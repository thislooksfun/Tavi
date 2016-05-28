//
//  GithubAPIAuthorization.swift
//  Tavi
//
//  Copyright (C) 2016 thislooksfun
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit

/// A class for storing and retrieving a [GitHub](https://github.com) authorization token
class GithubAPIAuthorization
{
	// MARK: Variables
	
	let id: Int
	let note:        String
	let user:        String
	let token:       String
	let scopes:     [String]
	let tokenHash:   String
	let fingerprint: String
	
	// MARK: - Initalizers
	
	/// Creates an instance from a `JSON` object and a token
	///
	/// - Parameters:
	///   - json: The `JSON` object to load from
	///   - token: The authorization token
	private init(id: Int, note: String, user: String, token: String, scopes: [String], tokenHash: String, fingerprint: String)
	{
		self.id =          id
		self.note =        note
		self.user =        user
		self.token =       token
		self.scopes =      scopes
		self.tokenHash =   tokenHash
		self.fingerprint = fingerprint
	}
	
	
	
	// MARK: - Functions -
	
	// MARK: Static
	
	/// Creates an instance from a `JSON` object
	///
	/// - Parameters:
	///   - json: The `JSON` object to load from
	///   - cb: The callback to execute upon completion
	static func makeInstanceFromJson(json: JSON, cb: (GithubAPIAuthorization?) -> Void) {
		let tok = json.getString("token")
		guard tok != nil && tok != "" else {
			cb(nil)
			return
		}
		makeInstanceFromJson(json, andToken: tok!, cb: cb)
	}
	
	/// Creates an instance from a `JSON` object and a token
	///
	/// - Parameters:
	///   - json: The `JSON` object to load from
	///   - token: The authorization token
	///   - cb: The callback to execute upon completion
	static func makeInstanceFromJson(json: JSON, andToken token: String, cb: (GithubAPIAuthorization?) -> Void)
	{
		Logger.trace("Loading JSON:\n\(json)\nWith token: '\(token)'")
		var user: String?
		
		if let msg = json.getString("message") {
			Logger.warn("Msg: "+msg)
		}
		
		user = json.getJson("user")?.getString("login")
		
		Logger.info(user)
		let id =          json.getInt("id")!
		let note =        json.getString("note") ?? ""
		let token =       token
		let scopes =      json.getKey("scopes") as! [String]
		let tokenHash =   json.getString("hashed_token")!
		let fingerprint = json.getString("fingerprint") ?? ""
		
		let authString = AuthHelper.generateAuthString(clientID, pass: clientSecret)
		
		if user == nil {
			GithubAPIBackend.apiCall("applications/\(clientID)/tokens/\(token)", method: .GET, headers: ["Authorization": authString])
			{ (errMsg: String?, json: JSON?, _) in
				
				if errMsg != nil {
					Logger.info(errMsg!)
					cb(nil)
				} else {
					user = json?.getJson("user")?.getString("login") ?? ""
					
					if user != "" {
						cb(GithubAPIAuthorization(id: id, note: note, user: user!, token: token, scopes: scopes, tokenHash: tokenHash, fingerprint: fingerprint))
					}
				}
			}
		} else {
			cb(GithubAPIAuthorization(id: id, note: note, user: user!, token: token, scopes: scopes, tokenHash: tokenHash, fingerprint: fingerprint))
		}
	}
	
	/// Attempts to load a `GithubAPIAuthorization` instance from the stored information
	///
	/// - Parameter cb: The callback to execute upon completion
	static func load(cb: (GithubAPIAuthorization?) -> Void)
	{
		let token = Settings.GitHub_Token.get()
		Logger.trace("Token = \(token)")
		
		guard token != nil && token != "" else { return cb(nil) }
		
		let authString = AuthHelper.generateAuthString(clientID, pass: clientSecret)
		
		GithubAPIBackend.apiCall("applications/\(clientID)/tokens/\(token!)", method: .GET, headers: ["Authorization": authString])
		{ (errMsg: String?, json: JSON?, _) in
			
			if errMsg != nil {
				Logger.info(errMsg!)
				cb(nil)
			} else if json == nil {
				Logger.info("JSON is nil!")
				cb(nil)
			} else {
				if let s = json!.getString("message") {
					Logger.error("Message: \(s)")
					cb(nil)
				} else {
					makeInstanceFromJson(json!, andToken: token!, cb: cb)
				}
			}
		}
	}
	
	
	// MARK: Internal
	
	/// Saves the authorization information
	func save() {
		Settings.GitHub_Token.set(self.token)
		Settings.GitHub_User.set(self.user)
	}
	
	/// Deletes the authorization information
	///
	/// - Warning: This is permanent. The only way to undo this is to re-authorize with [GitHub](https://github.com)
	func delete() {
		deleteToken()
		Settings.GitHub_User.set(nil)
	}
	
	/// Deletes the authorization token
	///
	/// - Warning: This is permanent. The only way to undo this is to re-authorize with [GitHub](https://github.com)
	func deleteToken() {
		GithubAPIBackend.apiCall("/authorizations/\(self.id)", method: .DELETE)
		{ (errMsg: String?, _, httpResponse: NSHTTPURLResponse?) in
			Settings.GitHub_Token.set(nil)
		}
	}
}
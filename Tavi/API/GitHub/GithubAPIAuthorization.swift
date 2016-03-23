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
	
	/// Creates an instance from a `JSON` object
	///
	/// - Parameter json: The `JSON` object to load from
	convenience init?(json: JSON) {
		let tok = json.getString("token")
		guard tok != nil && tok != "" else { return nil }
		self.init(json: json, token: tok!)
	}
	
	/// Creates an instance from a `JSON` object and a token
	///
	/// - Parameters:
	///   - json: The `JSON` object to load from
	///   - token: The authorization token
	init?(json: JSON, token: String)
	{
		Logger.trace("Loading JSON:\n\(json)\nWith token: '\(token)'")
		var user: String?
		
		if let msg = json.getString("message") {
			Logger.warn("Msg: "+msg)
		}
		
		user = json.getJson("user")?.getString("login")
		
		Logger.info(user)
		self.id =          json.getInt("id")!
		self.note =        json.getString("note") ?? ""
		self.token =       token
		self.scopes =      json.getKey("scopes") as! [String]
		self.tokenHash =   json.getString("hashed_token")!
		self.fingerprint = json.getString("fingerprint") ?? ""
		
		
		let authString = AuthHelper.generateAuthString(clientID, pass: clientSecret)
		
		if user == nil {
			GithubAPIBackend.apiCall("applications/\(clientID)/tokens/\(token)", method: .GET, headers: ["Authorization": authString], errorCallback: { (message) in Logger.info(message); user = nil })
				{ (json, httpResponse) in
					user = json.getJson("user")?.getString("login") ?? ""
			}
			
			while user == nil {}
			
			self.user = user ?? ""
		} else {
			self.user = user!
		}
		
		guard self.user != "" else { return nil }
	}
	
	
	
	// MARK: - Functions -
	
	// MARK: Static
	
	/// Attempts to load a `GithubAPIAuthorization` instance from the stored information
	///
	/// - Returns: A `GithubAPIAuthorization` instance if the token is valid, otherwise `nil`
	static func load() -> GithubAPIAuthorization?
	{
		let token = Settings.GitHub_Token.get()
		Logger.trace("Token = \(token)")
		
		guard token != nil && token != "" else { return nil }
		
		var finished = false
		var out: GithubAPIAuthorization?
		
		let authString = AuthHelper.generateAuthString(clientID, pass: clientSecret)
		
		GithubAPIBackend.apiCall("applications/\(clientID)/tokens/\(token!)", method: .GET, headers: ["Authorization": authString], errorCallback: { (message) in Logger.info(message); finished = true })
			{ (json, httpResponse) in
				
				if let s = json.getString("message") {
					Logger.error("Message: \(s)")
				} else {
					out = GithubAPIAuthorization(json: json, token: token!)
				}
				
				finished = true
		}
		
		while !finished {}
		
		return out
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
		GithubAPIBackend.apiCall("/authorizations/\(self.id)", method: .DELETE, errorCallback: nil)
		{ (json, httpResponse) in
			Logger.info(httpResponse)
			Settings.GitHub_Token.set(nil)
		}
	}
}
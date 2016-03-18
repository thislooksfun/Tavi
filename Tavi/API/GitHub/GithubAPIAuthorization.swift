//
//  GithubAPIAuthorization.swift
//  Tavi
//
//  Created by thislooksfun on 7/9/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class GithubAPIAuthorization
{
	let id: Int
	let note:        String
	let user:        String
	let token:       String
	let scopes:     [String]
	let tokenHash:   String
	let fingerprint: String
	
	convenience init?(json: JSON) {
		let tok = json.getString("token")
		guard tok != nil && tok != "" else { return nil }
		self.init(json: json, token: tok!)
	}
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
	
	func save()
	{
		Settings.GitHub_Token.set(self.token)
		Settings.GitHub_User.set(self.user)
	}
	
	func delete()
	{
		deleteToken()
		
		Settings.GitHub_User.set(nil)
	}
	
	func deleteToken() {
		GithubAPIBackend.apiCall("/authorizations/\(self.id)", method: .DELETE, errorCallback: nil)
		{ (json, httpResponse) in
			Logger.info(httpResponse)
			Settings.GitHub_Token.set(nil)
		}
	}
	
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
}
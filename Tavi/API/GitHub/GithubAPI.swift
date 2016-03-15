//
//  GithubAPI.swift
//  Tavi
//
//  Created by thislooksfun on 7/6/15.
//  Copyright (c) 2015 thislooksfun. All rights reserved.
//

import UIKit

class GithubAPI
{
	// Variables
	
	private static var authorization: GithubAPIAuthorization?
	
	
	
	// So no one can create a new instance
	private init() {}
	
	private static let authJson = [
		"scopes": ["read:org", "user:email", "repo_deployment", "repo:status", "write:repo_hook"],
		"note": "Tavi iOS app for \(UIDevice.currentDevice().name)",
		//"client_id": clientID,
		"client_secret": clientSecret
	] as [NSObject: AnyObject]
	
	// Functions
	
	// Authorizes (logs in) as the specified user
	static func auth(user user: String, pass: String, callback: (AuthState, Auth2fType?) -> Void) {
		self.auth(user: user, pass: pass, forceMainThread: false, callback: callback)
	}
	// Authorizes (logs in) as the specified user with the option to force to the main thread when performing the callback
	static func auth(user user: String, pass: String, forceMainThread: Bool, callback: (AuthState, Auth2fType?) -> Void)
	{
		Logger.info("\n============== GitHubAPI.auth")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: AuthState?
		var type: Auth2fType?
		
		let exit = { (state: AuthState, message: String?) -> Void in
			if message != nil { Logger.info(message!) }
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		let authString = AuthHelper.generateAuthString(user, pass: pass)
		
		GithubAPIBackend.apiCall("/authorizations/clients/\(clientID)/AppAuth", method: .PUT, headers: ["Authorization" : authString], json: authJson, errorCallback: { (message) in exit(AuthState.Other, message) })
		{ (let json, let httpResponse) in
			//19904254
			let s = json.getString("message")
			if (s == nil) {
				let t = json.getString("token")
				if t == nil {
					exit (AuthState.Other, "Token not found")
				} else if t == "" {
					exit(AuthState.TokenExists, nil)
				} else if !self.createAuthToken(json) {
					exit(AuthState.Other, "Error creating auth token")
				} else {
					exit(AuthState.Success, nil)
				}
			} else {
				switch (s!) {
				case "Must specify two-factor authentication OTP code.":
					let authType = httpResponse.allHeaderFields["X-GitHub-OTP"] as! NSString
					type = authType == "required; app" ? .App : .SMS
					exit(AuthState.Needs2fAuth, "2fauth! Type: \(authType)")
				case "Bad credentials":
					exit(AuthState.BadLogin, nil)
				default:
					exit(AuthState.Other, "Message: "+s!)
				}
			}
			
			if exitState == nil {
				exit(AuthState.Other, "Error: exitState not set!")
			}
			
			if exitState == AuthState.Other {
				Logger.trace(httpResponse)
			}
			
			if exitState == AuthState.Success {
				self.createAuthToken(json)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, type)
				})
			} else {
				callback(exitState!, type)
			}
		}
	}
	
	// Authorizes (logs in) as the specified user with a 2f auth code
	static func auth2f(user user: String, pass: String, code: String, callback: (Auth2fState) -> Void) {
		auth2f(user: user, pass: pass, code: code, forceMainThread: false, callback: callback)
	}
	// Authorizes (logs in) as the specified user with a 2f auth code with the option to force to the main thread when performing the callback
	static func auth2f(user user: String, pass: String, code: String, forceMainThread: Bool, callback: (Auth2fState) -> Void)
	{
		Logger.info("\n============== GitHubAPI.auth2f")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: Auth2fState?
		let exit = { (state: Auth2fState, message: String?) -> Void in
			if message != nil { Logger.info(message!) }
			guard (exitState == nil) else {
				Logger.warn("Error: exitState already set!")
				return
			}
			
			exitState = state
		}
		
		
		let authString = AuthHelper.generateAuthString(user, pass: pass)
		
		GithubAPIBackend.apiCall("/authorizations/clients/\(clientID)/AppAuth", method: .PUT, headers: ["Authorization": authString, "X-GitHub-OTP": code], json: authJson, errorCallback: { (message) in exit(Auth2fState.Other, nil) })
		{ (let json, let httpResponse) in
			
			let s = json.getString("message")
			if (s == nil) {
				let t = json.getString("token")
				if t == nil {
					exit (Auth2fState.Other, "Token not found")
				} else if t == "" {
					exit(Auth2fState.TokenExists, nil)
				} else if !self.createAuthToken(json) {
					exit(Auth2fState.Other, "Error creating auth token")
				} else {
					exit(Auth2fState.Success, nil)
				}
			} else {
				if (s! == "Must specify two-factor authentication OTP code.") { exit(Auth2fState.BadCode, nil) }
				else if (s! == "Bad credentials") { exit(Auth2fState.BadLogin, nil) }
				else { exit(Auth2fState.Other, "Message: "+s!) }
			}
			
			if exitState == nil { exit(Auth2fState.Other, "Error: exitState not set!") }
			
			if exitState == Auth2fState.Other {
				Logger.trace(httpResponse)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!)
				})
			} else {
				callback(exitState!)
			}
		}
	}
	
	// Creates an auth token
	private static func createAuthToken(json: JSON) -> Bool {
		self.authorization = GithubAPIAuthorization(json: json)
		guard self.authorization != nil else { return false }
		
		self.authorization!.save()
		return true
	}
	
	private static func checkAuthToken() -> Bool
	{
		self.authorization = GithubAPIAuthorization.load()
		return self.authorization != nil
	}
	
	// Returns true if the user is signed in and the auth token is still valid, otherwise returns false
	static func signedIn() -> Bool {
		return checkAuthToken()
	}
	
	// Clears the auth token for the current session
	static func signOut(keepUsername ku: Bool = false) {
		guard self.authorization != nil else { return } //Authorization is already nil, nothing to do
		
		let authString = AuthHelper.generateAuthString(clientID, pass: clientSecret)
		
		Logger.info(self.authorization?.token)
		GithubAPIBackend.apiCall("/applications/\(clientID)/tokens/\(self.authorization!.token)", method: .DELETE, headers: ["Authorization": authString], json: authJson, errorCallback: { (message) in Logger.trace(message) })
		{ (let json, let httpResponse) in
			Logger.info("Deleted token")
		}
		
		if ku {
			self.authorization?.deleteToken()
		} else {
			self.authorization?.delete()
		}
		self.authorization = nil
	}
	
	static func onClose() {
		self.authorization?.save()
	}
	
	// Enums
	enum AuthState {
		case Success
		case Needs2fAuth
		case BadLogin
		case TokenExists
		case Other
	}
	
	enum Auth2fState {
		case Success
		case BadCode
		case BadLogin
		case TokenExists
		case Other
	}
	
	enum Auth2fType {
		case App
		case SMS
	}
}
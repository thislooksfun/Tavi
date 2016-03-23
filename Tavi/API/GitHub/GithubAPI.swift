//
//  GithubAPI.swift
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

/// A general API for logging in to [GitHub](https://github.com)
class GithubAPI
{
	// MARK: Variables
	
	/// The authorization information
	private static var authorization: GithubAPIAuthorization?
	
	/// The [JSON](http://www.json.org) to use when authorizing with [GitHub](https://github.com)
	private static let authJson = [
		"scopes": ["read:org", "user:email", "repo_deployment", "repo:status", "write:repo_hook"],
		"note": "Tavi iOS app for \(UIDevice.currentDevice().name)",
		//"client_id": clientID,
		"client_secret": clientSecret
	] as [NSObject: AnyObject]
	
	
	// MARK: - Initalizers
	
	/// Set to private so no one can create a new instance
	private init() {}
	
	
	// MARK: - Functions -
	
	// MARK: Static
	
	
	/// Authorizes (logs in) as the specified user
	///
	/// - Parameters:
	///   - user: The username
	///   - pass: The password
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func auth(user user: String, pass: String, forceMainThread: Bool = false, callback: (AuthState, Auth2fType?) -> Void)
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
	
	/// Authorizes (logs in) as the specified user using a 2fauth code
	///
	/// - Parameters:
	///   - user: The username
	///   - pass: The password
	///   - code: The 2fauth code
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func auth2f(user user: String, pass: String, code: String, forceMainThread: Bool = true, callback: (Auth2fState) -> Void)
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
	
	/// Checks if the user is signed in
	/// - Returns: true if the user is signed in and the auth token is still valid, otherwise false
	static func signedIn() -> Bool {
		return checkAuthToken()
	}
	
	/// Clears the auth token for the current session
	/// - Parameter keepUsername: Whether or not to keep the username when clearing the token. (Default: `false`)
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
	
	// MARK: Private Static
	
	/// Creates an auth token
	///
	/// - Parameter json: The `JSON` object to create the auth token from
	///
	/// - Returns: `true` if the token creation was successful, otherwise `false`
	private static func createAuthToken(json: JSON) -> Bool {
		self.authorization = GithubAPIAuthorization(json: json)
		guard self.authorization != nil else { return false }
		
		self.authorization!.save()
		return true
	}
	
	/// Checks the validity of the current auth token
	///
	/// - Returns: `true` if the check was successful, otherwise `false`
	private static func checkAuthToken() -> Bool {
		self.authorization = GithubAPIAuthorization.load()
		return self.authorization != nil
	}
	
	// MARK: - Enums
	
	/// The auth state
	/// Used for the callback of the `auth` function
	enum AuthState
	{
		/// The authorization was successful
		case Success
		
		/// The user/pass is correct, but the user requres a 2fauth code to sign in
		case Needs2fAuth
		
		/// The user/pass is incorrect
		case BadLogin
		
		/// The token already exists, and thus we can't access it through the API
		case TokenExists
		
		/// Some unknown error occurred
		case Other
	}
	
	/// The auth state
	/// Used for the callback of the `auth2f` function
	enum Auth2fState
	{
		/// The authorization was successful
		case Success
		
		/// The 2fauth code is invalid
		case BadCode
		
		/// The user/pass is invalid
		case BadLogin
		
		/// The token already exists, and thus we can't access it through the API
		case TokenExists
		
		/// Some unknown error occurred
		case Other
	}
	
	/// The type of 2fauth required
	enum Auth2fType
	{
		/// Get the 2fauth from an authenticator app
		case App
		
		/// The auth code will be sent via an SMS text message
		case SMS
	}
}
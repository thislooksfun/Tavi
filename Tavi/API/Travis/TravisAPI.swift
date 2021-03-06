//
//  TravisAPI.swift
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

/// A general API for interacting with [Travis CI](https://travis-ci.org)
///
/// - TODO: Consolidate duplicate code?
/// - TODO: Maybe add method for interacting with https://travis-ci.com (the private one) as well?)
class TravisAPI
{
	/// The color used when a build is passing
	static let passingColor = UIColor(red:  63/255, green: 167/255, blue: 95/255, alpha: 1)
	/// The color used when a build is failing
	static let failingColor = UIColor(red: 219/255, green:  66/255, blue: 60/255, alpha: 1)
	/// The color used when a build is in progress
	static let inProgressColor = UIColor(red: 190/255, green: 171/225, blue:  4/225, alpha: 1)
	/// The color used when no builds are present
	static let noBuildColor = UIColor.clearColor()
	/// The color used when a build was cancelled
	static let cancelColor = UIColor(white: 102/255, alpha: 1)
	
	/// Whether or not the Travis auth token both exists and is valid
	///
	/// - Parameter cb: The callback to execute upon checking
	static func checkAuth(cb: (Bool) -> Void)
	{
		if Settings.Travis_Token.get() == nil || Settings.Travis_Token.get() == "" {
			cb(false)
			return
		}
		
		TravisAPIBackend.apiCall("users", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			if errMsg != nil {
				Logger.warn(errMsg!)
				cb(false)
			} else {
				cb(true)
			}
		}
	}
	
	/// Authenticate with Travis
	///
	/// - Parameters:
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func auth(forceMainThread forceMainThread: Bool = true, callback: (HTTPState) -> Void)
	{
		Logger.info("\n============== TravisAPI.auth")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		GithubAPI.signedIn() { (signedIn) in
			guard signedIn else {
				exit(.NeedsGithub, "Not logged into GitHub")
				callback(exitState!)
				return
			}
			
			let authJson = [
				"github_token": Settings.GitHub_Token.get()!
			]
			
			TravisAPIBackend.apiCall("auth/github", method: .POST, json: authJson)
			{ (let errMsg, let json, let httpResponse) in
				if errMsg != nil {
					Logger.warn(errMsg!)
					exit(.Other)
				} else
				{
					Settings.Travis_Token.set(json!.getString("access_token"))
					
					exit(.Success) //TODO check states
				}
				
				// No need to keep the github token around, discard it
				GithubAPI.signOut(keepUsername: true)
				
				if (forceMainThread) {
					NSOperationQueue.mainQueue().addOperationWithBlock({
						callback(exitState!)
					})
				} else {
					callback(exitState!)
				}
			}
		}
	}
	
	/// Loads all the active repositories for the current user
	///
	/// - Parameters:
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func load(forceMainThread: Bool = true, callback: (HTTPState, [JSON]?) -> Void)
	{
		Logger.info("\n============== TravisAPI.load")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		checkAuth() { (authed) in
			guard authed && Settings.GitHub_User.get() != nil else {
				exit(.NeedsGithub, "Not authenticated with Travis-CI")
				callback(exitState!, nil)
				return
			}
			
			TravisAPIBackend.apiCall("repos?member=\(Settings.GitHub_User.get()!)&active=true", method: .GET)
			{ (let errMsg, let json, let httpResponse) in
				
				var repos: [JSON]?
				if errMsg != nil {
					Logger.warn(errMsg!)
					exit(.Other)
				} else if json == nil {
					Logger.warn("json is nil")
					exit(.Other)
				} else {
					repos = json?.getJsonArray("repos")
					exit(repos == nil ? .Other : .Success)
				}
				
				if (forceMainThread) {
					NSOperationQueue.mainQueue().addOperationWithBlock({
						callback(exitState!, repos)
					})
				} else {
					callback(exitState!, repos)
				}
			}
		}
	}
	
	/// Loads repository information for a given ID
	///
	/// - Parameters:
	///   - id: The repo ID to load from
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func loadRepoFromID(id: Int, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void) {
		Logger.info("\n============== TravisAPI.loadRepoFromID")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		TravisAPIBackend.apiCall("repos/\(id)", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			
			if errMsg != nil {
				Logger.warn(errMsg!)
				exit(.Other)
			} else if json == nil {
				exit(.NoJson)
			} else {
				exit(.Success)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, json)
				})
			} else {
				callback(exitState!, json)
			}
		}
	}
	
	/// Loads repository information for a given slug
	///
	/// - Parameters:
	///   - slug: The repo slug to load from
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func loadRepoFromSlug(slug: String, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void) {
		Logger.info("\n============== TravisAPI.loadRepoFromSlug")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		TravisAPIBackend.apiCall("repos/\(slug)", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			
			if errMsg != nil {
				Logger.warn(errMsg!)
				exit(.Other)
			} else if json == nil {
				exit(.NoJson)
			} else {
				exit(.Success)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, json)
				})
			} else {
				callback(exitState!, json)
			}
		}
	}
	
	/// Loads the builds for a given repository
	///
	/// - Parameters:
	///   - slug: The repo slug to load builds for
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func loadBuildsForRepo(slug: String, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.loadBuildsForRepo")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		TravisAPIBackend.apiCall("repos/\(slug)/builds", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			
			if errMsg != nil {
				Logger.warn(errMsg!)
				exit(.Other)
			} else if json == nil {
				exit(.NoJson)
			} else {
				exit(.Success)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, json)
				})
			} else {
				callback(exitState!, json)
			}
		}
	}
	
	/// Loads a specific build from its ID
	///
	/// - Parameters:
	///   - buildID: The build ID to load
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func loadBuild(buildID: Int, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.loadBuild")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		TravisAPIBackend.apiCall("builds/\(buildID)", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			
			if errMsg != nil {
				Logger.warn(errMsg!)
				exit(.Other)
			} else if json == nil {
				exit(.NoJson)
			} else {
				exit(.Success)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, json)
				})
			} else {
				callback(exitState!, json)
			}
		}
	}
	
	//TODO: Document
	static func restartBuild(buildID: Int)
	{
		Logger.info("\n============== TravisAPI.restartBuild")
		
		TravisAPIBackend.apiCall("builds/\(buildID)/restart", method: .POST) { (_,_,_) in }
	}
	
	/// Loads a specific job from its ID
	///
	/// - Parameters:
	///   - jobID: The job ID to load
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func loadJob(jobID: Int, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.loadJob")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		TravisAPIBackend.apiCall("jobs/\(jobID)", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			
			if errMsg != nil {
				Logger.warn(errMsg!)
				exit(.Other)
			} else if json == nil {
				exit(.NoJson)
			} else {
				exit(.Success)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, json)
				})
			} else {
				callback(exitState!, json)
			}
		}
	}
	
	/// Loads the logs for a specific job
	///
	/// - Parameters:
	///   - jobID: The job ID to load from
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func loadLogForJob(jobID: Int, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.loadJob")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		TravisAPIBackend.apiCall("jobs/\(jobID)/log", method: .GET, accept: "application/json; chunked=true; version=2, text/plain; version=2", customHandler: {
			(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
			
			var json: JSON? = nil
			
			if error != nil {
				Logger.error(error)
				exit(.Other)
			} else if data != nil && response is NSHTTPURLResponse {
				let httpResponse = response as! NSHTTPURLResponse
				let contentType = httpResponse.allHeaderFields["Content-Type"]! as! String
				
				if contentType.containsString("json") {
					// Response is JSON
					Logger.trace("Log is in JSON")
					do {
						json = try JSON(data: data!).getJson("log")
					} catch {
						let datastr = NSString(data: data!, encoding: NSUTF8StringEncoding) ?? ""
						Logger.warn("Error parsing JSON \(datastr)")
					}
				} else {
					// Response is plain text
					Logger.trace("Log is in plain text")
					let log = NSString(data: data!, encoding: NSUTF8StringEncoding) ?? ""
					json = JSON(dict: ["parts": [["number": 1, "content": log, "final": true]]])
				}
				exit(.Success)
			}

			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, json)
				})
			} else {
				callback(exitState!, json)
			}
		}, callback: { (msg: String?, _, _) -> Void in
			if msg != nil {
				exit(.Other, msg!)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, nil)
				})
			} else {
				callback(exitState!, nil)
			}
		})
	}
	
	/// Gets the global Travis config information
	///
	/// - Parameters:
	///   - forceMainThread: Whether or not to force the callback to run on the main thread. (Default: `true`)
	///   - callback: The callback to use upon login completion (or failure)
	static func getConfig(forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.getConfig")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String? = nil) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		TravisAPIBackend.apiCall("config", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			
			if errMsg != nil {
				Logger.warn(errMsg!)
				exit(.Other)
			} else if json == nil {
				exit(.NoJson)
			} else {
				exit(.Success)
			}
			
			if (forceMainThread) {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					callback(exitState!, json)
				})
			} else {
				callback(exitState!, json)
			}
		}
	}
	
	/// Deauthorizes the app (throws away the token)
	static func deAuth() {
		Settings.Travis_Token.set(nil)
	}
	
	/// Gets updates in the background
	///
	/// - Parameter completion: the closure to call upon getting updates
	static func getUpdates(completion: (UIBackgroundFetchResult) -> Void)
	{
		//TODO: implement
		
//		Notifications.fireBuildFailed("vidr-group/gpool", buildNumber: 25, date: NSDate())
		completion(UIBackgroundFetchResult.NoData)
	}
	
	/// The build state
	enum BuildStatus
	{
		/// The build passed
		case Passing
		/// The build failed
		case Failing
		/// The build was created, but not yet started
		case Created
		/// The build has started
		case Started
		/// The build was cancelled
		case Cancelled
		/// None of the other states apply, for whatever reason.
		/// (This *should* never be used, but it's here just in case).
		case Unknown
		
		/// Whether or not the build is currently in progress (`.Created` or `.Started`)
		func isInProgress() -> Bool {
			return self == .Created || self == .Started
		}
	}
	
	/// The state for the HTTP requests
	enum HTTPState
	{
		/// The request succeeded
		case Success
		/// The request did not contain valid JSON
		case NoJson
		/// Travis is not authed, and neither is GitHub
		case NeedsGithub
		/// None of the other states apply
		case Other
	}
}
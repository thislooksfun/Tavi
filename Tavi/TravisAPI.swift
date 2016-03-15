//
//  TravisAPI.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

//TODO: Consolidate duplicate code sections?
class TravisAPI
{
	static let passingColor =    UIColor(red:  63/255, green: 167/255, blue: 95/255, alpha: 1)
	static let failingColor =    UIColor(red: 219/255, green:  66/255, blue: 60/255, alpha: 1)
	static let inProgressColor = UIColor(red: 190/255, green: 171/225, blue:  4/225, alpha: 1)
	static let noBuildColor =    UIColor.clearColor()
	static let cancelColor =     UIColor(white: 102/255, alpha: 1)
	
	static func authed() -> Bool {
		if Settings.Travis_Token.get() == nil || Settings.Travis_Token.get() == "" { return false }
		
		var exitState: HTTPState?
		func exit(state: HTTPState) {
			exitState = state
		}
		
		TravisAPIBackend.apiCall("users", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			if errMsg != nil {
				Logger.warn(errMsg!)
				exit(.Other)
			} else {
				exit(.Success)
			}
		}
		
		while exitState == nil {}
		
		return exitState == .Success
	}
	
	static func auth(forceMainThread forceMainThread: Bool = true, callback: (HTTPState) -> Void)
	{
		Logger.info("\n============== TravisAPI.auth")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String?) {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		guard GithubAPI.signedIn() else {
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
				exit(.Other, nil)
			} else
			{
				Settings.Travis_Token.set(json!.getString("access_token"))
				
				exit(.Success, nil) //TODO check states
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
	
	
	static func load(forceMainThread: Bool = true, callback: (HTTPState, [JSON]?) -> Void)
	{
		//TODO: rework to use the '/accounts' and '/repos {member, active}' endpoints
		Logger.info("\n============== TravisAPI.load")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String?) -> Void {
			if message != nil { Logger.info(message!) }
			
			guard exitState == nil else {
				Logger.warn("exitState already set!")
				return
			}
			
			exitState = state
		}
		
		guard authed() && Settings.GitHub_User.get() != nil else {
			exit(.NeedsGithub, "Not authenticated with Travis-CI")
			callback(exitState!, nil)
			return
		}
		
		TravisAPIBackend.apiCall("repos?member=\(Settings.GitHub_User.get()!)&active=true", method: .GET)
		{ (let errMsg, let json, let httpResponse) in
			
			var repos: [JSON]?
			if errMsg != nil {
				Logger.warn(errMsg!)
				exit(.Other, nil)
			} else if json == nil {
				Logger.warn("json is nil")
				exit(.Other, nil)
			} else {
				repos = json?.getJsonArray("repos")
				exit(repos == nil ? .Other : .Success, nil)
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
	
	static func loadRepoFromID(id: Int, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void) {
		Logger.info("\n============== TravisAPI.loadRepoFromID")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String?) -> Void {
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
				exit(.Other, nil)
			} else if json == nil {
				exit(.NoJson, nil)
			} else {
				exit(.Success, nil)
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
	
	static func loadRepoFromSlug(slug: String, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void) {
		Logger.info("\n============== TravisAPI.loadRepoFromSlug")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String?) -> Void {
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
				exit(.Other, nil)
			} else if json == nil {
				exit(.NoJson, nil)
			} else {
				exit(.Success, nil)
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
	
	static func loadBuildsForRepo(slug: String, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.loadBuildsForRepo")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String?) -> Void {
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
				exit(.Other, nil)
			} else if json == nil {
				exit(.NoJson, nil)
			} else {
				exit(.Success, nil)
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
	
	static func loadBuild(buildID: Int, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.loadBuild")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String?) -> Void {
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
				exit(.Other, nil)
			} else if json == nil {
				exit(.NoJson, nil)
			} else {
				exit(.Success, nil)
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
	
	static func loadJob(jobID: Int, forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.loadJob")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String?) -> Void {
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
				exit(.Other, nil)
			} else if json == nil {
				exit(.NoJson, nil)
			} else {
				exit(.Success, nil)
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
	
	static func getConfig(forceMainThread: Bool = true, callback: (HTTPState, JSON?) -> Void)
	{
		Logger.info("\n============== TravisAPI.getConfig")
		if !forceMainThread {
			Logger.warn("The callback will not be running on the main thread!")
		}
		
		var exitState: HTTPState?
		
		func exit(state: HTTPState, _ message: String?) -> Void {
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
				exit(.Other, nil)
			} else if json == nil {
				exit(.NoJson, nil)
			} else {
				exit(.Success, nil)
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
	
	static func deAuth() {
		Settings.Travis_Token.set(nil)
	}
	
	
	static func getUpdates(completion: (UIBackgroundFetchResult) -> Void)
	{
		//TODO: implement
		
//		Notifications.fireBuildFailed("vidr-group/gpool", buildNumber: 25, date: NSDate())
		completion(UIBackgroundFetchResult.NoData)
	}
	
	enum BuildStatus {
		case Passing
		case Failing
		case Created
		case Started
		case Cancelled
		case Unknown
		
		func isInProgress() -> Bool {
			return self == .Created || self == .Started
		}
	}
	
	enum HTTPState {
		case Success
		case Other
		case NoJson
		case NeedsGithub
	}
}
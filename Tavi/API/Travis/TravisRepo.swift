//
//  TravisRepo.swift
//  Tavi
//
//  Created by thislooksfun on 12/6/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class TravisRepo: Equatable
{
	static let SlugKey = "TravisRepoSlugKey"
	
	// MARK: Variables
	
	let slug: String
	
	var builds = [TravisBuild]()
	var lastBuild: TravisBuild? {
		get {
			return builds.first
		}
	}
	
	let repoID: Int
	
	private var binding: NSObjectProtocol?
	private var onPusherEvents: [NSObject : ((TravisRepo) -> Void)] = [:]
	
	// MARK: Static functions
	static func repoForID(id: Int, done: (TravisRepo?) -> Void)
	{
		Logger.info("Loading repo for id \(id)")
		TravisAPI.loadRepoFromID(id) {
			(state, json) in
			guard state == .Success else {
				done(nil)
				return
			}
			
			TravisRepo.repoFromJson(json, done: done)
		}
	}
	static func repoForSlug(slug: String, done: (TravisRepo?) -> Void)
	{
		Logger.info("Loading repo for slug \(slug)")
		TravisAPI.loadRepoFromSlug(slug) {
			(state, json) in
			guard state == .Success else {
				done(nil)
				return
			}
			
			TravisRepo.repoFromJson(json, done: done)
		}
	}
	
	static func repoFromJson(json: JSON?, done: (TravisRepo?) -> Void) {
		let repoJson = json?.getJson("repo") ?? json
		guard isJsonValid(repoJson) else {
			done(nil)
			return
		}
		
		_ = TravisRepo(slug: repoJson!.getString("slug")!, repoID: repoJson!.getInt("id")!, cb: done)
	}
	
	static func isJsonValid(json: JSON?) -> Bool {
		guard json != nil else { return false }
		guard let active = json!.getKey("active") as? Bool else { return false }
		guard active else { return false }
		
		return true
	}
	
	// MARK: Initalizers
	init(slug: String, repoID: Int, cb: (TravisRepo) -> Void)
	{
		Logger.info("Building repo '\(slug)' with id: '\(repoID)'")
		self.slug = slug
		self.repoID = repoID
		
		self.binding = Pusher.bindToAllEventsForChannel("repo-\(repoID)", withHandler: pusherEvent)
		
		getBuilds(cb)
	}
	
	func setPusherEventCallback(cb: (TravisRepo) -> Void, forObject obj: NSObject) {
		self.onPusherEvents[obj] = cb
	}
	func removePusherEventCallbackForObject(obj: NSObject) {
		self.onPusherEvents.removeValueForKey(obj)
	}
	
	func reloadLastBuild(cb: () -> Void) {
		guard let build = self.lastBuild else { return }
		
		TravisAPI.loadBuild(build.buildID)
		{ (let state, let json) in
			
			if state == .Success && json != nil {
				self.builds[0] = TravisBuild(buildJSON: json!, commit: build.commit)
			} else {
				Logger.warn("Problem reloading last build")
			}
			
			cb()
		}
	}
	
	func getBuilds(cb: (TravisRepo) -> Void)
	{
		TravisAPI.loadBuildsForRepo(self.slug)
		{ (let state, let json) in
			
			if state == .Success && json != nil {
				self.builds = [TravisBuild]()
				
				let builds = json!.getJsonArray("builds")!
				let commits = json!.getJsonArray("commits")!
				
				guard builds.count > 0 else {
					//If there are no builds, don't bother trying to load them
					cb(self)
					return
				}
				
				for i in 0..<builds.count {
					self.builds.append(TravisBuild(buildJSON: builds[i], commitJSON: commits[i]))
				}
				
				self.builds.sortInPlace() { (let build1, let build2) in
					//Just make sure everything is in the right order
					return build1.buildNumber > build2.buildNumber
				}
				
				cb(self)
			} else {
				Logger.warn("Problem loading builds for repo \(self.slug)")
			}
		}
	}
	
	func pusherEvent(event: PTPusherEvent?)
	{
		Logger.trace("Got pusher event in repo \(self.slug)")
		guard event != nil else {
			Logger.trace("Event is nil")
			return
		}
		Logger.trace("Event: \(event!.name ?? "")")
		
		guard (event!.name ?? "").hasPrefix("build:") else {
			Logger.warn("Event prefix is not 'build:'")
			return
		}
		
		guard let json = JSON(obj: event!.data) else {
			Logger.trace("Event data is not json")
			return
		}
		guard let buildJson = json.getJson("build") else {
			Logger.trace("Event json does not have a key 'build'")
			return
		}
		guard let commitJson = json.getJson("commit") else {
			Logger.trace("Event json does not have a key 'commit'")
			return
		}
		Logger.info(json)
		
		let newBuild = TravisBuild(buildJSON: buildJson, commitJSON: commitJson)
		if let last = self.lastBuild {
			if newBuild.buildID > last.buildID {
				self.builds.insert(newBuild, atIndex: 0)
			} else if newBuild.buildID == last.buildID {
				self.builds[0] = newBuild
			} else if newBuild.buildID < last.buildID {
				for (index, build) in self.builds.enumerate() {
					if build.buildID == newBuild.buildID {
						self.builds[index] = newBuild
						break
					}
				}
			}
		} else {
			self.builds.append(newBuild)
		}
		
		for (_, cb) in self.onPusherEvents {
			cb(self)
		}
		
		switch self.lastBuild!.status {
		case .Started: Notifications.fireBuildStarted(self.slug, buildNumber: self.lastBuild!.buildNumber)
		case .Passing: Notifications.fireBuildPassed(self.slug, buildNumber: self.lastBuild!.buildNumber)
		case .Failing: Notifications.fireBuildFailed(self.slug, buildNumber: self.lastBuild!.buildNumber)
		case .Cancelled: Notifications.fireBuildCancelled(self.slug, buildNumber: self.lastBuild!.buildNumber)
		default: break
		}
	}
	
	func dismiss() {
		Pusher.unbindChannel("repo-\(self.repoID)", withBinding: self.binding)
		
		for build in self.builds {
			build.dismiss()
		}
	}
}

func == (left: TravisRepo, right: TravisRepo) -> Bool {
	Logger.info("Repo ==")
	return left.repoID == right.repoID
		&& left.slug   == right.slug
		&& left.builds == right.builds
}
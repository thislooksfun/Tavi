//
//  TravisRepo.swift
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
import Pusher

/// A single Travis repository
class TravisRepo: Equatable
{
	// MARK: Variables
	
	/// The repository slug
	let slug: String
	
	/// An array of the builds for this repo
	var builds = [TravisBuild]()
	
	/// The most recent build, or `nil` if none exist
	var lastBuild: TravisBuild? {
		get {
			return builds.first
		}
	}
	
	/// The repo ID
	let repoID: Int
	
	/// A binding for all events fired on this repository's channel
	private var binding: NSObjectProtocol?
	
	/// The dictionary of closures to call upon recieving a `PTPusher` event
	private var onPusherEvents: [NSObject : ((TravisRepo) -> Void)] = [:]
	
	
	// MARK: Static functions
	
	/// Creates a `TravisRepo` from an ID
	///
	/// - Parameters:
	///   - id: The ID to create from
	///   - done: The closure to call once loading has finished
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
	
	/// Creates a `TravisRepo` from a slug
	///
	/// - Parameters:
	///   - slug: The slug to create from
	///   - done: The closure to call once loading has finished
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
	
	/// Creates a `TravisRepo` from a `JSON` object
	///
	/// - Parameters:
	///   - json: The `JSON` object to create from
	///   - done: The closure to call once loading has finished
	static func repoFromJson(json: JSON?, done: (TravisRepo?) -> Void) {
		let repoJson = json?.getJson("repo") ?? json
		guard isJsonValid(repoJson) else {
			done(nil)
			return
		}
		
		_ = TravisRepo(slug: repoJson!.getString("slug")!, repoID: repoJson!.getInt("id")!, cb: done)
	}
	
	/// Checks whether or not the `JSON` is generally valid for creating a repo from
	static func isJsonValid(json: JSON?) -> Bool {
		guard json != nil else { return false }
		guard let active = json!.getKey("active") as? Bool else { return false }
		guard active else { return false }
		
		return true
	}
	
	
	// MARK: Initalizers
	
	/// Creates a new instance
	///
	/// - Parameters:
	///   - slug: The repository's slug
	///   - repoID: The repository's ID
	///   - cb: The closure to call once loading has finished
	init(slug: String, repoID: Int, cb: (TravisRepo) -> Void)
	{
		Logger.info("Building repo '\(slug)' with id: '\(repoID)'")
		self.slug = slug
		self.repoID = repoID
		
		self.binding = Pusher.bindToAllEventsForChannel("repo-\(repoID)", withHandler: pusherEvent)
		
		getBuilds(cb)
	}
	
	/// Sets the closure to call for this object
	///
	/// - Parameters:
	///   - cb: The callback to add
	///   - obj: The object to add the callback for
	func setPusherEventCallback(cb: (TravisRepo) -> Void, forObject obj: NSObject) {
		self.onPusherEvents[obj] = cb
	}
	
	/// Removes a closure for a specific object
	///
	/// - Parameter obj: The object to remove the callback for
	func removePusherEventCallbackForObject(obj: NSObject) {
		self.onPusherEvents.removeValueForKey(obj)
	}
	
	/// Reloads the last build
	///
	/// - Parameter cb: The closure to call once the build has reloaded
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
	
	/// Loads all the builds for this repo
	///
	/// - Parameter cb: The closure to call once the builds have been loaded
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
	
	/// Called when a `PTPusher` event is fired for this repository
	///
	/// - Parameter event: The event that was fired
	func pusherEvent(event: PTPusherEvent?)
	{
		Logger.trace("Got pusher event in repo \(self.slug)")
		guard event != nil else {
			Logger.trace("Event is nil")
			return
		}
		Logger.trace("Event: \(event!.name ?? "")")
		
		guard (event!.name ?? "").hasPrefix("build:") else {
			//TODO: Handle other types of pusher events (job:, etc)
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
	
	/// Unload and unregister from anything.
	/// Used when this repo object will be deleted
	func dismiss() {
		Pusher.unbindChannel("repo-\(self.repoID)", withBinding: self.binding)
		
		for build in self.builds {
			build.dismiss()
		}
	}
}

/// An override of `==` used to allow equality between two different objects
func == (left: TravisRepo, right: TravisRepo) -> Bool {
	return left.repoID == right.repoID
		&& left.slug   == right.slug
		&& left.builds == right.builds
}
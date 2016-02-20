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
	
	private let repoID: Int
	
	private var bindings = [PTPusherEventBinding]()
	private var onBindEvent: (() -> Void)?
	
	// MARK: Static functions
	static func repoForSlug(slug: String, done: (TravisRepo?) -> Void)
	{
		Logger.info("Loading repo for slug \(slug)")
		TravisAPI.loadRepo(slug) {
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
		
		self.bindings.append(Pusher.bindToChannel("repo-\(repoID)", forEvent: "build:created",  withHandler: buildEvent))
		self.bindings.append(Pusher.bindToChannel("repo-\(repoID)", forEvent: "build:started",  withHandler: buildEvent))
		self.bindings.append(Pusher.bindToChannel("repo-\(repoID)", forEvent: "build:finished", withHandler: buildEvent))
		
		getBuilds(cb)
	}
	
	func setBindingCallback(cb: () -> Void) {
		self.onBindEvent = cb
	}
	
	func reloadLastBuild(cb: () -> Void) {
		guard let build = self.lastBuild else { return }
		
		TravisAPI.loadBuild(build.buildID)
		{ (let state, let json) in
			
			if state == .Success && json != nil {
				self.builds[0] = TravisBuild(buildJSON: json!)
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
				
				guard builds.count > 0 else {
					//If there are no builds, don't bother trying to load them
					cb(self)
					return
				}
				
				var remaining = builds.count
				func buildDone() {
					if --remaining <= 0 {
						cb(self)
					}
				}
				
				for build in builds {
					self.builds.append(TravisBuild(buildJSON: build, jobsLoaded: buildDone))
				}
				
				self.builds.sortInPlace() { (let build1, let build2) in
					//Just make sure everything is in the right order
					return build1.buildNumber > build2.buildNumber
				}
			} else {
				Logger.warn("Problem loading builds for repo \(self.slug)")
			}
		}
	}
	
	func buildEvent(event: PTPusherEvent!)
	{
		let json = JSON(obj: event.data)
		guard json != nil else { return }
		
		Logger.info(json!)
		
		let newBuild = TravisBuild(buildJSON: json!.getJson("build")!)
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
		}
		
		self.onBindEvent?()
	}
	
	func dismiss() {
		for binding in self.bindings {
			Pusher.unbindEvent(binding)
		}
		
		for build in self.builds {
			build.dismiss()
		}
	}
}

func == (left: TravisRepo, right: TravisRepo) -> Bool {
	return left.repoID == right.repoID
		&& left.slug   == right.slug
		&& left.builds == right.builds
}
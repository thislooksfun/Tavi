//
//  TravisBuild.swift
//  Tavi
//
//  Created by thislooksfun on 12/6/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class TravisBuild: Equatable
{
	let buildNumber: Int
	
	private(set) var status: TravisAPI.BuildStatus
	private(set) var startedAt: NSDate?
	private(set) var finishedAt: NSDate?
//	private(set) var duration: NSTimeInterval
	
	let buildID: Int
	
	var jobs = [TravisBuildJob]()
	
	init(buildJSON: JSON, jobsLoaded: (() -> Void)? = nil)
	{
		self.buildID = buildJSON.getInt("id")!
		
		self.buildNumber = Int(buildJSON.getString("number")!)!
		switch buildJSON.getString("state")! {
		case "passed": self.status = .Passing
		case "failed": self.status = .Failing
		case "canceled": self.status = .Cancelled
		case "created": self.status = .Created
		case "started": self.status = .Started
		default: self.status = .Unknown
		}
		
//		if self.status == .Started {
//			Logger.info("Started:")
//			Logger.info(buildJSON)
//		}
		
		self.startedAt = parseDate(buildJSON.getString("started_at") ?? "")
		self.finishedAt = parseDate(buildJSON.getString("finished_at") ?? "")
//		self.duration = NSTimeInterval(buildJSON.getInt("duration") ?? -1)
		
		self.loadJobs(buildJSON, done: jobsLoaded)
		
		/*
		Possible other fields:
		  - event_type
		  - pull_request_title
		  - commit_id
		  - config
		  - pull_request
		  - pull_request_number
		  - repository_id
		*/
	}
	
	func loadJobs(buildJSON: JSON, done: (() -> Void)?)
	{
		let jobIDs = buildJSON.getArray("job_ids")! as! [Int]
		var remaining = jobIDs.count
		func jobDone() {
			if --remaining <= 0 {
				done?()
			}
		}
		
		for id in jobIDs {
			TravisAPI.loadJob(id) {
				(state, json) in
				
				guard state == .Success && json != nil else {
					jobDone()
					return
				}
				guard let job = TravisBuildJob(jobJson: json!) else {
					jobDone()
					return
				}
				self.jobs.append(job)
				
				jobDone()
			}
		}
	}
	
	func dismiss() {
		//TODO: Implement this
	}
}

func == (left: TravisBuild, right: TravisBuild) -> Bool {
	return left.buildNumber == right.buildNumber
		&& left.status      == right.status
		&& left.startedAt   == right.startedAt
		&& left.finishedAt  == right.finishedAt
//		&& left.duration    == right.duration
		&& left.buildID     == right.buildID
}
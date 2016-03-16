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
	private(set) var commit: Commit
	
	let buildID: Int
	
	var jobs = [TravisBuildJob]()
	
	
	convenience init(buildJSON: JSON, commitJSON: JSON, jobsLoaded: (() -> Void)? = nil)
	{
		self.init(buildJSON: buildJSON, commit: Commit(fromJSON: commitJSON), jobsLoaded: jobsLoaded)
	}
	init(buildJSON: JSON, commit: Commit, jobsLoaded: (() -> Void)? = nil)
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
		
		self.startedAt = parseDate(buildJSON.getString("started_at") ?? "")
		self.finishedAt = parseDate(buildJSON.getString("finished_at") ?? "")
		
		self.commit = commit
		
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
	
	struct Commit {
		var branch: String
		var authorEmail: String
		var id: Int
		var committedAt: NSDate
		var message: String
		var authorName: String
		var sha: String
		var committerName: String
		var committerEmail: String
		var compareUrl: NSURL
		var pullRequestNumber: Int?
		
		init(fromJSON json: JSON) {
			branch = json.getString("branch")!
			authorEmail = json.getString("author_email")!
			id = json.getInt("id")!
			committedAt = parseDate(json.getString("committed_at")!)!
			message = json.getString("message")!
			authorName = json.getString("author_name")!
			sha = json.getString("sha")!
			committerName = json.getString("committer_name")!
			committerEmail = json.getString("committer_email")!
			compareUrl = NSURL(string: json.getString("compare_url")!)!
			pullRequestNumber = json.getInt("pull_request_number")
		}
		
		/*
		[{
		  "branch" : "master",
		  "author_email" : "thislooksfun@users.noreply.github.com",
		  "id" : 27018106,
		  "committed_at" : "2015-12-05T18:34:51Z",
		  "message" : "Create .travis.yml",
		  "author_name" : "thislooksfun",
		  "sha" : "9ecebfc533f6ad41587be21d5de188fb12a9a79d",
		  "committer_name" : "thislooksfun",
		  "committer_email" : "thislooksfun@users.noreply.github.com",
		  "compare_url" : "https:\/\/github.com\/thislooksfun\/testing\/compare\/67d44b7763ac...9ecebfc533f6",
		  "pull_request_number" : null
		}]
		*/
	}
}

func == (left: TravisBuild, right: TravisBuild) -> Bool {
	return left.buildNumber == right.buildNumber
		&& left.status      == right.status
		&& left.startedAt   == right.startedAt
		&& left.finishedAt  == right.finishedAt
		&& left.buildID     == right.buildID
}
//
//  TravisBuild.swift
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

/// A single Travis build
class TravisBuild: Equatable
{
	/// The build number
	let buildNumber: Int
	
	/// The status the build exited with
	private(set) var status: TravisAPI.BuildStatus
	
	/// The time when this build started (can be nil)
	private(set) var startedAt: NSDate?
	
	/// The time when this build finished (can be nil)
	private(set) var finishedAt: NSDate?
	
	/// The GitHub commit associated with this build
	private(set) var commit: Commit
	
	/// The buildID
	let buildID: Int
	
	var jobIDs: [Int]
	
	/// An `Array` of jobs for this build
	var jobs = [TravisBuildJob]()
	
	/// Creates an instance
	///
	/// - Parameters:
	///   - buildJSON: The `JSON` to construct this build from
	///   - commitJSON: The `JSON` to construct this build's commit from
	///   - loadJobs: Whether or not to load the jobs now (Default: `false`)
	///   - buildLoaded: The closure to call once the loading is complete (Default: `nil`)
	convenience init(buildJSON: JSON, commitJSON: JSON, loadJobs: Bool = false, buildLoaded: (() -> Void)? = nil)
	{
		self.init(buildJSON: buildJSON, commit: Commit(fromJSON: commitJSON), loadJobs: loadJobs, buildLoaded: buildLoaded)
	}
	
	/// Creates an instance
	///
	/// - Parameters:
	///   - buildJSON: The `JSON` to construct this build from
	///   - commit: The `Commit` associated with this build
	///   - loadJobs: Whether or not to load the jobs now (Default: `false`)
	///   - buildLoaded: The closure to call once the loading is complete (Default: `nil`)
	init(buildJSON: JSON, commit: Commit, loadJobs: Bool = false, buildLoaded: (() -> Void)? = nil)
	{
		self.buildID = buildJSON.getInt("id")!
		
		self.buildNumber = buildJSON.getInt("number") ?? Int(buildJSON.getString("number")!)!
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
		
		self.jobIDs = buildJSON.getArray("job_ids")! as! [Int]
		
		if loadJobs {
			self.loadJobs(done: { (_) in buildLoaded?() })
		} else {
			buildLoaded?()
		}
		
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
	
	/// Load all the jobs for this build
	///
	/// - Parameters:
	///   - buildJSON: The json for this build
	///   - done: The closure to call when the jobs are loaded
	func loadJobs(done done: (([TravisBuildJob]) -> Void)?)
	{
		var remaining = jobIDs.count
		func jobDone() {
			remaining -= 1
			if remaining <= 0 {
				done?(self.jobs)
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
	
	/// Unload and unregister from anything.
	/// Used when this build object will be deleted
	func dismiss() {
		//TODO: Implement this
	}
	
	/// A struct for storing the commit information
	struct Commit
	{
		/// The branch the commit was on
		var branch: String
		
		/// The commit author's email
		var authorEmail: String
		
		/// The commit ID
		var id: Int
		
		/// The time when the commit occurred
		var committedAt: NSDate
		
		/// The commit message
		var message: String
		
		/// The commit author's name
		var authorName: String
		
		/// The commit's SHA
		var sha: String
		
		/// The committer's name
		var committerName: String
		
		/// The committer's email
		var committerEmail: String
		
		/// The URL to the commit comparason
		var compareUrl: NSURL
		
		/// The pull request this commit was generated from
		/// or `nil`, if it wasn't from a pull request
		var pullRequestNumber: Int?
		
		/// Creates an instance from a `JSON` object
		init(fromJSON json: JSON)
		{
			branch = json.getString("branch")!
			authorEmail = json.getString("author_email")!
			id = json.getInt("id")!
			committedAt = parseDate(json.getString("committed_at")!)!
			message = json.getString("message")!
			authorName = json.getString("author_name")!
			sha = json.getString("sha")!
			committerName = json.getString("committer_name")!
			committerEmail = json.getString("committer_email")!
			let urlstring = json.getString("compare_url")!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
			compareUrl = NSURL(string: urlstring)!
			pullRequestNumber = json.getInt("pull_request_number")
		}
	}
}

/// An override of `==` used to allow equality between two different objects
func == (left: TravisBuild, right: TravisBuild) -> Bool {
	return left.buildNumber == right.buildNumber
		&& left.status      == right.status
		&& left.startedAt   == right.startedAt
		&& left.finishedAt  == right.finishedAt
		&& left.buildID     == right.buildID
}
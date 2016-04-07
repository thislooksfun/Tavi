//
//  TravisBuildJob.swift
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

/// A single Travis build job
class TravisBuildJob
{
	private let jobID: Int
	private let logID: Int
	
	/// Creates an instance from a `JSON` object
	///
	/// - Parameter jobJson: The `JSON` to load the job from
	init?(jobJson: JSON) {
		let job = jobJson.getJson("job")!
		Logger.info(job)
		
		jobID = job.getInt("id")!
		logID = job.getInt("log_id")!
		
		/* Other keys:
		
		state: String
		repository_slug: String
		annotation_ids: [Int]
		commit_id: Int
		tags: ???
		finished_at: String (date)
		build_id: Int
		allow_failure: Bool
		config : {
		  script: [String]
		  os: String
		  dist: String
		  language: String
		  node_js: String (I think the key for this is the value of config.language, but I'm not sure
		  .result: String
		  group: String
		}
		number: String
		started_at: String (date)
		queue: String
		repository_id: String
		
		*/
	}
	
	func getLog(cb: (TravisBuildLog) -> Void) {
		TravisAPI.loadLogForJob(self.jobID) {
			(state, json) in
			
			guard state == .Success else { return }
			guard json != nil else { return }
			guard let log = TravisBuildLog(json: json!) else { return }
			
			cb(log)
		}
	}
}
//
//  TravisBuildJob.swift
//  Tavi
//
//  Created by thislooksfun on 2/13/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

/// A single Travis build job
class TravisBuildJob
{
	/// Creates an instance from a `JSON` object
	///
	/// - Parameter jobJson: The `JSON` to load the job from
	init?(jobJson: JSON) {
		Logger.info(jobJson.getJson("job")!)
	}
	
	// TODO: Implement this
//	func getLog(cb: (JSON) -> Void) {
//		TravisAPI.loadLogForJob
//	}
}
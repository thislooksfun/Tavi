//
//  TravisBuildJob.swift
//  Tavi
//
//  Created by thislooksfun on 2/13/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class TravisBuildJob
{
	init?(jobJson: JSON) {
		Logger.info(jobJson.getJson("job")!)
	}
	
	func getLog(cb: (JSON) -> Void) {
//		TravisAPI.loadLogForJob
	}
}
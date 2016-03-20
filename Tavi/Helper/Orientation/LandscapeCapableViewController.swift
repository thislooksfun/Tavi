//
//  LandscapeCapableViewController.swift
//  Tavi
//
//  Created by thislooksfun on 7/7/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

/// A `UIViewController` that is capable of rotation to Landscape
class LandscapeCapableViewController: PortraitViewController
{
	override func shouldAutorotate() -> Bool {
		return true
	}
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.AllButUpsideDown
	}
	
	override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
		return UIInterfaceOrientation.Portrait
	}
}
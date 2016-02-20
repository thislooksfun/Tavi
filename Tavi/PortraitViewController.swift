//
//  PortraitViewController.swift
//  Tavi
//
//  Created by thislooksfun on 2/12/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class PortraitViewController: UIViewController
{
	override func shouldAutorotate() -> Bool {
		return true
	}
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.Portrait
	}
	
	override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
		return UIInterfaceOrientation.Portrait
	}
}
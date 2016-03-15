//
//  OrientationRespectfulNavController.swift
//  Tavi
//
//  Created by thislooksfun on 1/29/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class OrientationRespectfulNavController: UINavigationController
{
	override func shouldAutorotate() -> Bool {
		return self.visibleViewController?.shouldAutorotate() ?? true
	}
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		guard !(self.visibleViewController is UIAlertController) else { return UIInterfaceOrientationMask.Portrait }
		return self.visibleViewController?.supportedInterfaceOrientations() ?? UIInterfaceOrientationMask.Portrait
	}
}
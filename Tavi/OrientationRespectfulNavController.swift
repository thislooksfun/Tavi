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
		return self.visibleViewController?.supportedInterfaceOrientations() ?? UIInterfaceOrientationMask.Portrait
	}
}
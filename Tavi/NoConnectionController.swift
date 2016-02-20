//
//  NoConnectionController.swift
//  GitClient
//
//  Created by thislooksfun on 7/9/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class NoConnectionController: UIViewController
{
	@IBAction func refresh(sender: AnyObject) {
		if Connection.connectedToNetwork() {
			self.navigationController!.popViewControllerAnimated(true)
		}
	}
}
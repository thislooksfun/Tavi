//
//  LoadTravisViewController.swift
//  TravisCI
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class LoadTravisViewController: UIViewController
{
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		guard Connection.connectedToNetwork() else {
			self.performSegueWithIdentifier("NoConnection", sender: self)
			return
		}
		
		Logger.info("load travis")
		TravisAPI.load(callback: loadCallback)
	}
	
	func loadCallback(state: TravisAPI.AuthState, repos: [JSON]?)
	{
		Logger.info("LT cb")
		if state == .Success {
			self.loadRepoData(repos!)
		} else {
			// TODO: Implement the 'LoadFailed' segue
			self.performSegueWithIdentifier("LoadFailed", sender: self)
		}
	}
	
	func loadRepoData(repos: [JSON])
	{
		let authView = self.navigationController!.parentViewController! as! AuthViewController
		authView.loggedAndLoaded(repos)
	}
}
//
//  StartupViewController.swift
//  GitClient
//
//  Created by thislooksfun on 7/8/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class StartupViewController: UIViewController
{	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		guard Connection.connectedToNetwork() else {
			self.performSegueWithIdentifier("NoConnection", sender: nil)
			return
		}
		
		if TravisAPI.authed() {
			self.performSegueWithIdentifier("LoggedIn", sender: nil)
		} else {
			if GithubAPI.signedIn() {
				TravisAPI.auth(callback: travisAuth)
			} else {
				self.performSegueWithIdentifier("Login", sender: nil)
			}
		}
	}
	
	func travisAuth(state: TravisAPI.AuthState) {
		switch state {
			case .Success:     self.performSegueWithIdentifier("LoggedIn", sender: nil)
			case .NeedsGithub: self.performSegueWithIdentifier("Login", sender: nil)
			case .Other:       Logger.error("Unknown error occoured") //TODO: Handle better
		}
	}
}
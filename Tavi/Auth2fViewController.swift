//
//  2fauthViewController.swift
//  GitClient
//
//  Created by thislooksfun on 7/6/15.
//  Copyright (c) 2015 thislooksfun. All rights reserved.
//

import UIKit

class Auth2fViewController: PortraitViewController, UITextFieldDelegate
{
	@IBOutlet var code: UITextField!
	
	private var user: String?
	private var pass: String?
	private var authType: GithubAPI.Auth2fType?
	
	var nav: UINavigationController!
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		self.code.delegate = self
		self.code.becomeFirstResponder()
		self.nav = self.childViewControllers[0] as! UINavigationController
	}
	
	// Submits the form
	func submit() {
		guard Connection.connectedToNetwork() else {
			self.performSegueWithIdentifier("NoConnection", sender: nil)
			return
		}
		
		if nav.viewControllers.count > 1 {
			nav.popToRootViewControllerAnimated(false)
		}
		
		let messageArea = self.nav.topViewController as! MessageAreaController
		messageArea.spinner.hidden = false
		messageArea.message.hidden = true
		
		GithubAPI.auth2f(user: self.user!, pass: self.pass!, code: self.code.text!, callback: self.authCallback, forceMainThread: true)
	}
	
	// Checks what state the auth exited in, and performs the appropriate action
	private func authCallback(state: GithubAPI.Auth2fState)
	{
		let messageArea = self.nav.topViewController as! MessageAreaController
		messageArea.spinner.hidden = true
		switch (state) {
		case .Success:
			//Sucessfully logged in - segue to the main screen
			let auth = self.navigationController!.parentViewController as! AuthViewController
			auth.signedIn()
		case .BadCode:
			//Bad login - invalid 2f auth code - try again
			if (self.nav.childViewControllers.count > 1) {
				self.nav.popToRootViewControllerAnimated(false)
			}
			let messageArea = self.nav.topViewController as! MessageAreaController
			messageArea.message.text = "Invalid 2f auth code"
			messageArea.message.hidden = false
		case .Other:
			//Unknown error - try again
			if (self.nav.childViewControllers.count > 1) {
				self.nav.popToRootViewControllerAnimated(false)
			}
			let messageArea = self.nav.topViewController as! MessageAreaController
			messageArea.message.text = "An unknown error occurred.\nPlease try again later."
			messageArea.message.hidden = false
		}
	}
	
	// Clears all user-specific fields
	func clear()
	{
		self.user = nil
		self.pass = nil
		self.authType = nil
		self.code.text = nil
	}
	
	// Displays help about the 2fAuth type you're using
	@IBAction func displayMethod(sender: UIButton) {
		self.code.resignFirstResponder()
		if nav.viewControllers.count == 1 {
			nav.topViewController?.performSegueWithIdentifier(self.authType == .App ? "ShowAppHelp" : "ShowSMSHelp", sender: nil)
		}
	}
	
	// Sets the user & pass used to sign in - used to re-sign in with the 2fauth key
	func setUser(user: String?, andPass pass: String?) {
		self.user = user;
		self.pass = pass;
	}
	
	// Sets the 2f auth type - app or SMS
	func setAuthType(type: GithubAPI.Auth2fType) {
		self.authType = type
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		if (textField == self.code) {
			self.code.resignFirstResponder()
			self.submit()
		}
		
		return true
	}
	
	//Makes it so touching outside the text field causes the keyboard to go away
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		self.code.resignFirstResponder()
	}
}

class MessageAreaController: UIViewController
{
	@IBOutlet var message: UILabel!
	@IBOutlet var spinner: UIView!
}

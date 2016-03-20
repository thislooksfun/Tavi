//
//  LoginViewController.swift
//  GitClient
//
//  Created by thislooksfun on 7/6/15.
//  Copyright (c) 2015 thislooksfun. All rights reserved.
//

import UIKit

class LoginViewController: PortraitViewController, UITextFieldDelegate
{
	@IBOutlet var username: UITextField!
	@IBOutlet var password: UITextField!
	@IBOutlet var spinner: UIView!
	@IBOutlet var message: UILabel!
	@IBOutlet var onePassSignInButton: UIButton!
	
	private var authType: GithubAPI.Auth2fType!
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		
		self.username.delegate = self
		self.password.delegate = self
		
		self.username.becomeFirstResponder()
		
		let onePassAvailable = OnePasswordExtension.sharedExtension().isAppExtensionAvailable()
		self.onePassSignInButton.hidden = !onePassAvailable
		
		if onePassAvailable {
			self.username.rightView = UIView(frame: CGRectMake(0, 0, 37, self.username.frame.height))
			self.username.rightViewMode = .Always
		}
		
		
		// Testing stuff
		self.username.text = "thislooksfun"
		self.password.becomeFirstResponder()
		self.password.text = "Coco6=:)"
		
//		self.submit()
	}
	
	// Submits the form
	func submit() {
		guard Connection.connectedToNetwork() else {
			self.performSegueWithIdentifier("NoConnection", sender: nil)
			return
		}
		
		self.spinner.hidden = false
		self.message.hidden = true
		GithubAPI.auth(user: username.text!, pass: password.text!, callback: authCallback, forceMainThread: true)
	}
	
	// Checks what state the auth exited in, and performs the appropriate action
	private func authCallback(state: GithubAPI.AuthState, type: GithubAPI.Auth2fType?)
	{
		self.spinner.hidden = true
		switch (state) {
		case .Success:
			//Sucessfully logged in - segue to the main screen
			let auth = self.navigationController!.parentViewController as! AuthViewController
			auth.signedIn()
		case .BadLogin:
			//Bad login - invalid username/password - try again
			self.message.text = "Invalid username/email/password"
			self.message.hidden = false
		case .Needs2fAuth:
			//Needs two factor authentication - segue to the 2fauth screen
			let auth = self.navigationController!.parentViewController as! AuthViewController
			auth.showBackButton()
			self.authType = type!
			self.performSegueWithIdentifier("Do2fAuth", sender: nil)
		case .Other:
			//Unknown error - try again
			self.message.text = "An unknown error occurred.\nPlease try again later."
			self.message.hidden = false
		}
	}
	
	// Clears the text fields
	func clear() {
		self.username.text = nil
		self.password.text = nil
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool
	{
		if (textField == self.username) {
			//Select next text field
			self.password.becomeFirstResponder()
			return false
		} else if (textField == self.password) {
			
			guard self.username.text!.characters.count > 0 && self.password.text!.characters.count > 0 else {
				return false
			}
			
			self.password.resignFirstResponder()
			self.submit()
		}
		
		return true
	}
	
	@IBAction func onePasswordLogin(sender: AnyObject)
	{
		OnePasswordExtension.sharedExtension().findLoginForURLString("https://github.com", forViewController:self, sender:sender) {
			(loginDictionary: [NSObject: AnyObject]?, error: NSError?) in
			guard let dict = loginDictionary else { return }
			
			if (dict.count == 0) {
				if (error != nil && error!.code != Int(AppExtensionErrorCodeCancelledByUser)) {
					print("Error invoking 1Password App Extension for find login: \(error)");
				}
				return;
			}
			
			self.password.becomeFirstResponder()
			
			self.username.text = (dict[AppExtensionUsernameKey] as? String) ?? ""
			self.password.text = (dict[AppExtensionPasswordKey] as? String) ?? ""
		}
	}
	
	//Makes it so touching outside the text field causes the keyboard to go away
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		self.username.resignFirstResponder()
		self.password.resignFirstResponder()
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
	{
		//Set auth2f user, pass, and authType
		let auth2f = segue.destinationViewController as? Auth2fViewController
		auth2f?.setUser(self.username.text!, andPass: self.password.text!)
		auth2f?.setAuthType(self.authType)
	}
}
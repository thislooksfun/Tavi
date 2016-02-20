//
//  LoginController.swift
//  Tavi
//
//  Created by thislooksfun on 1/29/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class LoginController: PortraitViewController
{
	// MARK: IBOutlets
	@IBOutlet var grayView: UIView!
	@IBOutlet var topConstraint: NSLayoutConstraint!
	@IBOutlet var container: UIView!
	
	@IBOutlet var onePassWidthConstraint: NSLayoutConstraint!
	@IBOutlet var twoFAuthGapConstraint: NSLayoutConstraint!
	@IBOutlet var twoFAuthHeightConstraint: NSLayoutConstraint!
	
	@IBOutlet var username: UITextField!
	@IBOutlet var password: UITextField!
	@IBOutlet var twoFAuth: UITextField!
	
	@IBOutlet var spinner: UIActivityIndicatorView!
	@IBOutlet var submitButton: UIButton!
	
	@IBOutlet var errorLabel: UILabel!
	@IBOutlet var errorView: UIView!
	@IBOutlet var errorHeight: NSLayoutConstraint!
	
	
	// MARK: Settings
	private static let shownTopConstant: CGFloat = 70
	private static let maxBackgroundAlpha: CGFloat = 0.6
	
	// MARK: Variables
	private var gettingOnepass = false
	
	private var callback: ((Bool) -> Void)? = nil
	
	// MARK: - Functions -
	
	// MARK: Static
	static func openLogin(cb cb: ((Bool) -> Void)? = nil)
	{
		Logger.info("Open login...")
		let storyboard = UIStoryboard(name: "Login", bundle: nil)
		let loginVC = storyboard.instantiateInitialViewController()! as! LoginController
		let currentVC = UIViewController.currentViewController()
		
		loginVC.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
		currentVC.presentViewController(loginVC, animated: false, completion: nil)
		
		loginVC.callback = cb
	}
	
	// MARK: Override
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		// Hack thing to make sure the view is still there when the 1Password extension closes
		guard !gettingOnepass else { return }
		
		self.grayView.alpha = 0
		
		self.container.hidden = true
		self.container.layer.cornerRadius = 15
		self.container.clipsToBounds = true
		
		if !OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
			self.onePassWidthConstraint.constant = 0
		}
		
		self.twoFAuthGapConstraint.constant = 0
		self.twoFAuthHeightConstraint.constant = 0
		
		self.errorHeight.constant = 0
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		self.topConstraint.constant = self.view.window!.frame.height
		self.view.layoutIfNeeded()
		self.container.hidden = false
		
		if animated {
			UIView.animateWithDuration(0.3) {
				self.grayView.alpha = LoginController.maxBackgroundAlpha
				self.topConstraint.constant = LoginController.shownTopConstant
				UIView.animateWithDuration(0.3, animations: self.view.layoutIfNeeded)
			}
		} else {
			self.grayView.alpha = LoginController.maxBackgroundAlpha
			self.container.hidden = false
			self.topConstraint.constant = LoginController.shownTopConstant
			self.view.layoutIfNeeded()
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		self.closeKeyboard()
	}
	
	// MARK: IBAction
	@IBAction func onePasswordLogin(sender: AnyObject)
	{
		self.gettingOnepass = true
		OnePasswordExtension.sharedExtension().findLoginForURLString("https://github.com", forViewController:self, sender:sender) {
			(loginDictionary: [NSObject: AnyObject]?, error: NSError?) in
			
			self.gettingOnepass = false
			
			guard let dict = loginDictionary else { return }
			
			if (dict.count == 0) {
				if (error != nil && error!.code != Int(AppExtensionErrorCodeCancelledByUser)) {
					Logger.warn("Error invoking 1Password App Extension for find login: \(error)");
				}
				return;
			}
			
			self.username.text = (dict[AppExtensionUsernameKey] as? String) ?? ""
			self.password.text = (dict[AppExtensionPasswordKey] as? String) ?? ""
			if let totp = (dict[AppExtensionTOTPKey] as? String) {
				self.show2fAuth(.App) {
					delay(0.05) {
						self.twoFAuth.text = totp
						self.submit(nil)
					}
				}
			} else {
				self.submit(nil)
			}
		}
	}
	
	@IBAction func submit(sender: AnyObject?)
	{
		self.submitButton.enabled = false
		self.spinner.hidden = false
		
		if self.twoFAuth.text != nil && self.twoFAuth.text != "" {
			Logger.info("Submitting 2f auth login")
			GithubAPI.auth2f(user: self.username.text ?? "", pass: self.password.text ?? "", code: self.twoFAuth.text!, forceMainThread: true) {
				(authState) in
				
				self.submitButton.enabled = true
				self.spinner.hidden = true
				
				switch authState {
				case .Success:     self.loginSuccess()
				case .BadCode:     self.showError("Invalid code")
				case .BadLogin:    self.showError("Invalid login")
				case .TokenExists: self.showError(nil, withDetail: "The auth token for this app somehow already exists. Please go to https://github.com/settings/applications and revoke the token for Tavi, then try again.")
				case .Other:       self.showError("Unknown error. :/")
				}
			}
		} else {
			Logger.info("Submitting user/pass login")
			GithubAPI.auth(user: self.username.text ?? "", pass: self.password.text ?? "", forceMainThread: true) {
				(authState, auth2fType) in
				
				self.submitButton.enabled = true
				self.spinner.hidden = true
				
				switch authState {
				case .Success:     self.loginSuccess()
				case .Needs2fAuth: self.show2fAuth(auth2fType!)
				case .BadLogin:    self.showError("Invalid login")
				case .TokenExists: self.showError(nil, withDetail: "The auth token for this app somehow already exists. Please go to https://github.com/settings/applications and revoke the token for Tavi, then try again.")
				case .Other:       self.showError("Unknown error. :(")
				}
			}
		}
	}
	
	@IBAction func cancel(sender: AnyObject) {
		self.closeSlideDown(done: { (_) in self.callback?(false) })
	}
	
	// MARK: Notifications
	func keyboardWillShow(note: NSNotification) {
		self.view.layoutIfNeeded()
		
		let kNote = KeyboardNotification(note)
		
		let containerBottom = LoginController.shownTopConstant + self.container.frame.height
		let frameTop = kNote.frameEndForView(self.view).minY
		
		let offset = LoginController.shownTopConstant - ((containerBottom - frameTop) + 20)
		if offset < LoginController.shownTopConstant {
			self.topConstraint.constant = offset
			
			UIView.animateWithDuration(kNote.animationDuration, delay: 0.0, options: UIViewAnimationOptions(rawValue: UInt(kNote.animationCurve << 16)), animations: {
				self.view.layoutIfNeeded()
			}, completion: nil)
		}
	}
	func keyboardWillHide(note: NSNotification) {
		self.view.layoutIfNeeded()
		
		let kNote = KeyboardNotification(note)
		
		self.topConstraint.constant = LoginController.shownTopConstant
			
		UIView.animateWithDuration(kNote.animationDuration, delay: 0.0, options: UIViewAnimationOptions(rawValue: UInt(kNote.animationCurve << 16)), animations: {
			self.view.layoutIfNeeded()
		}, completion: nil)
	}
	
	// MARK: Other
	func closeKeyboard() {
		self.username.resignFirstResponder()
		self.password.resignFirstResponder()
		self.twoFAuth.resignFirstResponder()
	}
	
	private func show2fAuth(type: GithubAPI.Auth2fType, finished: (() -> Void)? = nil)
	{
		twoFAuthGapConstraint.constant = 12
		twoFAuthHeightConstraint.constant = 40
		UIView.animateWithDuration(0.3, animations: self.view.layoutIfNeeded, completion: { (_) in finished?() })
	}
	
	private func showError(msg: String?, withDetail details: String? = nil)
	{
		if details != nil {
			Alert.showAlertWithTitle("Error", andMessage: details!, andActions: [Alert.getDefaultActionWithTitle("Close")])
		}
		
		
		guard msg != nil else { return }
		
		self.errorLabel.text = msg
		self.view.layoutIfNeeded()
		
		self.errorHeight.constant = 40
		UIView.animateWithDuration(0.3, animations: self.view.layoutIfNeeded) { (_) in
			delay(2) {
				self.errorHeight.constant = 0
				UIView.animateWithDuration(0.3, animations: self.view.layoutIfNeeded)
			}
		}
	}
	
	private func loginSuccess()
	{
		TravisAPI.auth(forceMainThread: true) {
			(state) in
			switch state {
			case .Success:        self.closeSlideUp(done: { (_) in self.callback?(true) })
			case .NeedsGithub:    self.showError("Login unsuccessful")
			case .NoJson, .Other: self.showError("Unknown error. D:")
			}
		}
	}
	
	private func closeSlideUp(done done: ((Bool) -> Void)? = nil) {
		self.topConstraint.constant = -self.view.window!.frame.height
		UIView.animateWithDuration(0.3, animations: {
			self.grayView.alpha = 0
			self.view.layoutIfNeeded()
		}) { (_) in
			self.fadeAndDismiss(done: done)
		}
	}
	
	private func closeSlideDown(done done: ((Bool) -> Void)? = nil) {
		self.topConstraint.constant = self.view.window!.frame.height
		UIView.animateWithDuration(0.3, animations: {
			self.grayView.alpha = 0
			self.view.layoutIfNeeded()
		}) { (_) in
			self.fadeAndDismiss(done: done)
		}
	}
	
	private func fadeAndDismiss(done done: ((Bool) -> Void)? = nil) {
		UIView.animateWithDuration(0.2, animations: {
			self.grayView.alpha = 0
		}) { (finished) in
			done?(finished)
			self.dismissViewControllerAnimated(false, completion: nil)
		}
	}
}
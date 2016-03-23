//
//  LoginController.swift
//  Tavi
//
//  Copyright (C) 2016 thislooksfun
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit

class LoginController: PortraitViewController
{
	// MARK: IBOutlets
	/// The gray-out over the background
	@IBOutlet var grayView: UIView!
	/// The top position of the inner container
	@IBOutlet var topConstraint: NSLayoutConstraint!
	/// The inner container
	@IBOutlet var container: UIView!
	
	/// The width of the 1Password login button
	@IBOutlet var onePassWidthConstraint: NSLayoutConstraint!
	/// The gap between the 2fauth text field and the above password field
	@IBOutlet var twoFAuthGapConstraint: NSLayoutConstraint!
	/// The height of the 2f auth text field
	@IBOutlet var twoFAuthHeightConstraint: NSLayoutConstraint!
	
	/// The username text field
	@IBOutlet var username: UITextField!
	/// The password text field
	@IBOutlet var password: UITextField!
	/// The 2f auth text field
	@IBOutlet var twoFAuth: UITextField!
	
	/// The spinner displayed when a request is being processed
	@IBOutlet var spinner: UIActivityIndicatorView!
	/// The submit button
	@IBOutlet var submitButton: UIButton!
	
	/// The label displayed when an error occours
	@IBOutlet var errorLabel: UILabel!
	/// The view in which errors are displayed
	@IBOutlet var errorView: UIView!
	/// The height of the `errorView`
	@IBOutlet var errorHeight: NSLayoutConstraint!
	
	
	// MARK: Settings
	/// The top constraint for the inner view when it is shown
	private static let shownTopConstant: CGFloat = 70
	/// The alpha value of the `grayView`
	private static let maxBackgroundAlpha: CGFloat = 0.6
	
	// MARK: Variables
	/// Whether or not the user is currently looking at 1Password
	private var gettingOnepass = false
	
	/// The closure to fire when the login succeeds (or is cancelled)
	private var callback: ((Bool) -> Void)? = nil
	
	
	// MARK: - Functions -
	
	// MARK: Static
	
	/// Creates and displays a new instance of this class.
	///
	/// - Parameter cb: The closure to excecute upon the login finishing
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
	
	// MARK: Overrides
	
	/// Override of `UIViewController.viewWillAppear`
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
	
	/// Override of `UIViewController.viewDidAppear`
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
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
	}
	
	/// Override of `UIViewController.viewWillDisappear`
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	/// Override of `UIViewController.touchesBegan`
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		self.closeKeyboard()
	}
	
	
	// MARK: IBAction
	
	/// Opens up 1Password to the GitHub accounts page
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
	
	/// Submits the form
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
	
	/// Closes the login window without submitting
	@IBAction func cancel(sender: AnyObject) {
		self.closeSlideDown(done: { (_) in self.callback?(false) })
	}
	
	
	// MARK: Notifications
	
	/// Adjusts the view so nothing is covered by the keyboard when it appears
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
	
	/// Resets the view when the keyboard is dismissed
	func keyboardWillHide(note: NSNotification) {
		self.view.layoutIfNeeded()
		
		let kNote = KeyboardNotification(note)
		
		self.topConstraint.constant = LoginController.shownTopConstant
			
		UIView.animateWithDuration(kNote.animationDuration, delay: 0.0, options: UIViewAnimationOptions(rawValue: UInt(kNote.animationCurve << 16)), animations: {
			self.view.layoutIfNeeded()
		}, completion: nil)
	}
	
	
	// MARK: Other
	
	/// Deselects all text boxes and closes the keyboard, if it is open
	func closeKeyboard() {
		self.username.resignFirstResponder()
		self.password.resignFirstResponder()
		self.twoFAuth.resignFirstResponder()
	}
	
	/// Shows the 2f auth text box
	///
	/// - Parameters:
	///   - type: The type of 2f auth the user has selected
	///   - finished: The closure to call when the animation has finished (Default: `nil`)
	private func show2fAuth(type: GithubAPI.Auth2fType, finished: (() -> Void)? = nil)
	{
		twoFAuthGapConstraint.constant = 12
		twoFAuthHeightConstraint.constant = 40
		UIView.animateWithDuration(0.3, animations: self.view.layoutIfNeeded, completion: { (_) in finished?() })
	}
	
	/// Displays an error
	///
	/// - Parameters:
	///   - msg: The message to show
	///   - details: Any details to display (Default: `nil`).
	///              If this is not `nil`, the detauls will be shown in a pop-up alert
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
	
	/// Performs the necessary actions when the login is successful.
	///
	/// Namely, closing the view and calling the callbacks
	/// - Note: While this should only be called when the state is `.Success`,
	///         it will handle other states should it be called incorrectly
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
	
	/// Closes the inner view by sliding it upwards. (Used to indicate success).
	private func closeSlideUp(done done: ((Bool) -> Void)? = nil) {
		self.topConstraint.constant = -self.view.window!.frame.height
		UIView.animateWithDuration(0.3, animations: {
			self.grayView.alpha = 0
			self.view.layoutIfNeeded()
		}) { (_) in
			self.fadeAndDismiss(done: done)
		}
	}
	
	/// Closes the inner view by sliding it downwards. (Used to indicate cancellation)
	private func closeSlideDown(done done: ((Bool) -> Void)? = nil) {
		self.topConstraint.constant = self.view.window!.frame.height
		UIView.animateWithDuration(0.3, animations: {
			self.grayView.alpha = 0
			self.view.layoutIfNeeded()
		}) { (_) in
			self.fadeAndDismiss(done: done)
		}
	}
	
	/// Fades out the gray out view and dismisses this view controller
	private func fadeAndDismiss(done done: ((Bool) -> Void)? = nil) {
		UIView.animateWithDuration(0.2, animations: {
			self.grayView.alpha = 0
		}) { (finished) in
			done?(finished)
			self.dismissViewControllerAnimated(false, completion: nil)
		}
	}
}
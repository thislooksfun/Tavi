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

class NoConnectionController: PortraitViewController
{
	// MARK: IBOutlets
	/// The gray-out over the background
	@IBOutlet var grayView: UIView!
	/// The top position of the inner container
	@IBOutlet var topConstraint: NSLayoutConstraint!
	/// The inner container
	@IBOutlet var container: UIView!
	
	/// The radio tower icon with one bar
	@IBOutlet var RadioTower1: UIImageView!
	/// The radio tower icon with two bars
	@IBOutlet var RadioTower2: UIImageView!
	
	/// The retry button
	@IBOutlet var retryButton: UIButton!
	
	
	// MARK: Settings
	/// The top constraint for the inner view when it is shown
	private static let shownTopConstant: CGFloat = 70
	/// The alpha value of the `grayView`
	private static let maxBackgroundAlpha: CGFloat = 0.6
	
	// MARK: Variables
	/// The closure to fire when the login succeeds (or is cancelled)
	private var callback: ((Bool) -> Void)? = nil
	
	
	// MARK: - Functions -
	
	// MARK: Static
	
	/// Creates and displays a new instance of this class.
	///
	/// - Parameter cb: The closure to excecute upon the login finishing
	static func display(cb cb: ((Bool) -> Void)? = nil)
	{
		let storyboard = UIStoryboard(name: "NoConnection", bundle: nil)
		let NCVC = storyboard.instantiateInitialViewController()! as! NoConnectionController
		let currentVC = UIViewController.currentViewController()
		
		NCVC.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
		currentVC.presentViewController(NCVC, animated: false, completion: nil)
		
		NCVC.callback = cb
	}
	
	// MARK: Overrides
	
	/// Override of `UIViewController.viewWillAppear`
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		
		self.grayView.alpha = 0
		
		self.container.hidden = true
		self.container.layer.cornerRadius = 15
		self.container.clipsToBounds = true
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
				self.grayView.alpha = NoConnectionController.maxBackgroundAlpha
				self.topConstraint.constant = NoConnectionController.shownTopConstant
				UIView.animateWithDuration(0.3, animations: self.view.layoutIfNeeded)
			}
		} else {
			self.grayView.alpha = NoConnectionController.maxBackgroundAlpha
			self.container.hidden = false
			self.topConstraint.constant = NoConnectionController.shownTopConstant
			self.view.layoutIfNeeded()
		}
	}
	
	
	// MARK: IBAction
	
	/// Checks to see if there is a connection yet
	@IBAction func retry(sender: AnyObject?) {
		if Connection.connectedToNetwork() {
			self.closeSlideUp(done: self.callback)
		}
	}
	
	/// Closes the inner view by sliding it upwards.
	private func closeSlideUp(done done: ((Bool) -> Void)? = nil) {
		self.topConstraint.constant = -self.view.window!.frame.height
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
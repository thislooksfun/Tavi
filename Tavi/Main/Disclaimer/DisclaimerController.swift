//
//  DisclaimerController.swift
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

/// The controller for the legal disclaimer
class DisclaimerController: PortraitViewController
{
	/// The text view that contains the actual disclaimer
	@IBOutlet var textView: UITextView!
	/// The height of the title area (Used to hide it when accessed through the menu)
	@IBOutlet var titleAreaHeight: NSLayoutConstraint!
	/// The height of the button area (Used to hide it when accessed through the menu)
	@IBOutlet var buttonAreaHeight: NSLayoutConstraint!
	
	/// Whether or not this was displayed because the 'legal' button was pressed in the menu
	var isLegal = false
	
	/// Constructs and displays the view as a pop-up
	static func display()
	{
		let storyboard = UIStoryboard(name: "Disclaimer", bundle: nil)
		let disclaimerVC = storyboard.instantiateInitialViewController()! as! DisclaimerController
		
		UIViewController.currentViewController().presentViewController(disclaimerVC, animated: true, completion: nil)
	}
	
	/// Constructs and displays the view as a navigation controller page (used by the menu)
	///
	/// - Parameter nav: The navigation controller to push the disclaimer controller to
	static func displayAsLegal(nav: UINavigationController)
	{
		let storyboard = UIStoryboard(name: "Disclaimer", bundle: nil)
		let disclaimerVC = storyboard.instantiateInitialViewController()! as! DisclaimerController
		
		disclaimerVC.isLegal = true
		
		nav.pushViewController(disclaimerVC, animated: true)
	}
	
	override func viewDidLoad() {
		if self.isLegal {
			self.titleAreaHeight.constant = 0
			self.buttonAreaHeight.constant = 0
			self.navigationItem.title = "Legal"
		}
		self.textView.textContainerInset = UIEdgeInsetsMake(20, 20, 20, 20)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.textView.setContentOffset(CGPointZero, animated: false)
	}
	
	/// Sets `Settings.HasReadDisclaimer` to `true` and closes the view.
	@IBAction func close(sender: AnyObject) {
		Settings.HasReadDisclaimer.set(true)
		self.dismissViewControllerAnimated(true, completion: nil)
	}
}
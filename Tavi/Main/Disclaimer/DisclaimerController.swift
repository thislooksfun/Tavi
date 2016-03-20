//
//  DisclaimerController.swift
//  Tavi
//
//  Created by thislooksfun on 2/4/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
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
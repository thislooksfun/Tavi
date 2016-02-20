//
//  DisclaimerController.swift
//  Tavi
//
//  Created by thislooksfun on 2/4/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class DisclaimerController: PortraitViewController
{
	@IBOutlet var textView: UITextView!
	@IBOutlet var titleAreaHeight: NSLayoutConstraint!
	@IBOutlet var buttonAreaHeight: NSLayoutConstraint!
	
	var isLegal = false
	
	static func display()
	{
		let storyboard = UIStoryboard(name: "Disclaimer", bundle: nil)
		let disclaimerVC = storyboard.instantiateInitialViewController()! as! DisclaimerController
		
		UIViewController.currentViewController().presentViewController(disclaimerVC, animated: true, completion: nil)
	}
	
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
	
	@IBAction func close(sender: AnyObject) {
		Settings.HasReadDisclaimer.set(true)
		self.dismissViewControllerAnimated(true, completion: nil)
	}
}
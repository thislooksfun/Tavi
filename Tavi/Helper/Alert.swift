//
//  Alert.swift
//  Tavi
//
//  Created by thislooksfun on 2/12/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

/// A simple way of displaying alerts
class Alert
{
	/// Shows an alert
	///
	/// - Parameters:
	///   - title: The title of the alert
	///   - message: The the main body of the alert
	///   - actions the `UIAlertAction`s to display
	static func showAlertWithTitle(title: String, andMessage message: String, andActions actions: [UIAlertAction])
	{
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
		actions.forEach({ (action) in alert.addAction(action) })
		UIViewController.currentViewController().presentViewController(alert, animated: true, completion: nil)
	}
	
	/// Shows an action sheet
	///
	/// - Parameters:
	///   - title: The title of the sheet
	///   - message: The the main body of the sheet
	///   - actions the `UIAlertAction`s to display
	static func showActionSheetWithTitle(title: String, andMessage message: String, andActions actions: [UIAlertAction])
	{
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
		actions.forEach({ (action) in alert.addAction(action) })
		UIViewController.currentViewController().presentViewController(alert, animated: true, completion: nil)
	}
	
	/// Gets a `Default` styled UIAlertAction
	///
	/// - Parameters:
	///   - title: The title of the action
	///   - handler: the handler to use when the action is selected
	static func getDefaultActionWithTitle(title: String, andHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
		return UIAlertAction(title: title, style: .Default, handler: handler)
	}
	
	/// Gets a `Cancel` styled UIAlertAction
	///
	/// - Parameters:
	///   - title: The title of the action
	///   - handler: the handler to use when the action is selected
	static func getCancelActionWithTitle(title: String, andHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
		return UIAlertAction(title: title, style: .Cancel, handler: handler)
	}
	
	/// Gets a `Destructive` styled UIAlertAction
	///
	/// - Parameters:
	///   - title: The title of the action
	///   - handler: the handler to use when the action is selected
	static func getDestructiveActionWithTitle(title: String, andHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
		return UIAlertAction(title: title, style: .Destructive, handler: handler)
	}
}
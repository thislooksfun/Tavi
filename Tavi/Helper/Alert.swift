//
//  Alert.swift
//  Tavi
//
//  Created by thislooksfun on 2/12/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class Alert
{
	static func showAlertWithTitle(title: String, andMessage message: String, andActions actions: [UIAlertAction])
	{
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
		actions.forEach({ (action) in alert.addAction(action) })
		UIViewController.currentViewController().presentViewController(alert, animated: true, completion: nil)
	}
	
	static func showActionSheetWithTitle(title: String, andMessage message: String, andActions actions: [UIAlertAction])
	{
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
		actions.forEach({ (action) in alert.addAction(action) })
		UIViewController.currentViewController().presentViewController(alert, animated: true, completion: nil)
	}
	
	static func getDefaultActionWithTitle(title: String, andHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
		return UIAlertAction(title: title, style: .Default, handler: handler)
	}
	static func getCancelActionWithTitle(title: String, andHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
		return UIAlertAction(title: title, style: .Cancel, handler: handler)
	}
	static func getDestructiveActionWithTitle(title: String, andHandler handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertAction {
		return UIAlertAction(title: title, style: .Destructive, handler: handler)
	}
}
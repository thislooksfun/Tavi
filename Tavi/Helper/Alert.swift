//
//  Alert.swift
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
	
	/// Checks whether or not there is currently an alert showing
	///
	/// - returns: `true` if the current view controller is an
	///            instance of `UIAlertController`, otherwise false
	static func isAlertShowing() -> Bool {
		return UIViewController.currentViewController() is UIAlertController
	}
}
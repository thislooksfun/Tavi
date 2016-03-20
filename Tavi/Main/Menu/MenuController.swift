//
//  MenuController.swift
//  Tavi
//
//  Created by thislooksfun on 12/6/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

/// The `UITableViewController` in charge of the main screen of the menu
class MenuController: PortraitTableViewController
{
	/// The label for the favorites view, in order to gray it out when no favorites are present
	@IBOutlet var favoritesLabel: UILabel!
	/// The label with the current count of favorited items
	@IBOutlet var favoritesCount: UILabel!
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.favoritesCount.text = "\((Settings.Favorites.get() ?? []).count)"
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.section == 0 && (Settings.Favorites.get() ?? []).count == 0 {
			cell.userInteractionEnabled = false
			favoritesLabel.enabled = false
		}
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
		switch indexPath.section {
		case 0:  self.performSegueWithIdentifier("openFavoritesMenu", sender: self)
		case 1:  self.performSegueWithIdentifier("openNotificationMenu", sender: self)
		case 2:  DisclaimerController.displayAsLegal(self.navigationController!)
		case 3:  self.logOut()
		default: self.warnUnknown(indexPath)
		}
	}
	
	/// Logs out of GitHub and Travis
	func logOut() {
		GithubAPI.signOut()
		TravisAPI.deAuth()
		Settings.GitHub_User.set(nil)
		
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	/// Logs a warning that an unknown table index was selected.
	/// (This should never be needed in practice)
	private func warnUnknown(index: NSIndexPath) {
		Logger.warn("Unspecified menu index selected: [section: \(index.section), row: \(index.row)]")
		self.tableView.deselectRowAtIndexPath(index, animated: true)
	}
}
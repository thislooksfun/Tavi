//
//  MenuController.swift
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
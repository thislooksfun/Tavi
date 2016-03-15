//
//  MenuController.swift
//  Tavi
//
//  Created by thislooksfun on 12/6/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class MenuController: PortraitTableViewController
{
	@IBOutlet var favoritesLabel: UILabel!
	@IBOutlet var favoritesCount: UILabel!
	@IBOutlet var filterStateLabel: UILabel!
	
//	override func viewDidLoad() {
//		super.viewDidLoad()
//		self.navigationController!.interactivePopGestureRecognizer?.delegate = nil
//	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if Settings.FilterState.get() == nil {
			Settings.FilterState.set(Settings.Filter.Active.rawValue)
		}
		self.favoritesCount.text = "\((Settings.Favorites.get() ?? []).count)"
		self.filterStateLabel.text = Settings.Filter.fromInt(Settings.FilterState.get()).description
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
		case 1:  self.performSegueWithIdentifier("openFilterSelect", sender: self)
		case 2:  DisclaimerController.displayAsLegal(self.navigationController!)
		case 3:  self.logOut()
		default: self.warnUnknown(indexPath)
		}
	}
	
	func logOut() {
		GithubAPI.signOut()
		TravisAPI.deAuth()
		Settings.GitHub_User.set(nil)
		
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	private func warnUnknown(index: NSIndexPath) {
		Logger.warn("Unspecified menu index selected: [section: \(index.section), row: \(index.row)]")
		self.tableView.deselectRowAtIndexPath(index, animated: true)
	}
	
	
}
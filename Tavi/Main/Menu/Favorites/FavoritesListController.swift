//
//  FavoritesListController.swift
//  Tavi
//
//  Created by thislooksfun on 2/11/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

/// The manager for the list of favorited items
class FavoritesListController: PortraitTableViewController
{
	/// The favorited states for all the different slugs that were favorited when the view was opened
	private var data = [State]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.tableFooterView = UIView()
		
		if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
			let infoButton = UIButton(type: .InfoLight)
			infoButton.addTarget(self, action: "showInfo:", forControlEvents: .TouchUpInside)
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
		}
		
		for fav in (Settings.Favorites.get() ?? []) {
			self.data.append(State(slug: fav, favorited: true))
		}
		
		if self.data.count > 1 {
			self.tableView.setEditing(true, animated: true)
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		guard self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available else { return }
		
		let shortcutIndicatorBar = UIView()
		shortcutIndicatorBar.translatesAutoresizingMaskIntoConstraints = false
		shortcutIndicatorBar.backgroundColor = Settings.Tavi_Orange_Color
		self.view.addSubview(shortcutIndicatorBar)
		let count = self.data.count
		let truncatedCount = (count > 4) ? 4 : count
		let height: CGFloat = CGFloat(44 * truncatedCount)
		self.view.addConstraint(NSLayoutConstraint(item: shortcutIndicatorBar, attribute: .Top,    relatedBy: .Equal, toItem: self.view, attribute: .Top,            multiplier: 1, constant: 0))
		self.view.addConstraint(NSLayoutConstraint(item: shortcutIndicatorBar, attribute: .Left,   relatedBy: .Equal, toItem: self.view, attribute: .Left,           multiplier: 1, constant: 0))
		self.view.addConstraint(NSLayoutConstraint(item: shortcutIndicatorBar, attribute: .Width,  relatedBy: .Equal, toItem: nil,       attribute: .NotAnAttribute, multiplier: 1, constant: 5))
		self.view.addConstraint(NSLayoutConstraint(item: shortcutIndicatorBar, attribute: .Height, relatedBy: .Equal, toItem: nil,       attribute: .NotAnAttribute, multiplier: 1, constant: height))
	}
	
	override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
		if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
			let infoButton = UIButton(type: .InfoLight)
			infoButton.addTarget(self, action: "showInfo:", forControlEvents: .TouchUpInside)
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: infoButton)
		} else {
			self.navigationItem.rightBarButtonItem = nil
		}
		self.tableView.reloadData()
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.data.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("FavoritesCell", forIndexPath: indexPath) as! FavoritesCell
		cell.load(self.data[indexPath.row].slug)
		cell.favToggleButton.tag = indexPath.row
		cell.favToggleButton.addTarget(self, action: "toggleCellFavorite:", forControlEvents: .TouchUpInside)
		return cell
	}
	
	override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
		let item = self.data.removeAtIndex(sourceIndexPath.row)
		self.data.insert(item, atIndex: destinationIndexPath.row)
		
		self.saveToFavorites()
	}
	
	override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		return UITableViewCellEditingStyle.None
	}
	override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	
	/// Shows a small pop-up that informs the user what the orange bar on the left means
	/// 
	/// - Note: Both the orange bar and the info button are only visible when the app is running
	///         on a device that both supports 3D touch, and has it enabled.
	///
	/// - TODO: Actually implement this
	func showInfo(sender: AnyObject?) {
		//TODO: Make this button explain that the orange bar on the left of the screen indicates the items that will be in the homescreen quick action window thing
		Logger.info("Showing info")
	}
	
	/// Toggles the state of a cell when the heart button is pressed
	///
	/// - Parameter button: The specfic heart button that was pressed
	func toggleCellFavorite(button: UIButton) {
		self.data[button.tag].favorited = !self.data[button.tag].favorited
		self.saveToFavorites()
	}
	
	/// Inserts the repo into the favorites at the correct index
	func saveToFavorites() {
		var favs = [String]()
		for state in self.data {
			if state.favorited {
				favs.append(state.slug)
			}
		}
		
		Settings.Favorites.set(favs)
		self.tableView.reloadData()
	}
	
	/// A really simple way to keep track of the current favorited state
	struct State {
		/// The slug
		var slug: String
		/// Whether or not the slug is a favorite
		var favorited: Bool
	}
}
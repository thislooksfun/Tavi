//
//  NotificationController.swift
//  Tavi
//
//  Created by thislooksfun on 3/15/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import Foundation

/// The `UITableViewController` in charge of the 'Notifications' section of the menu
class NotificationController: PortraitTableViewController
{
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
		
		if indexPath.section == 0 {
			let filterStateRaw = Settings.NoteType(rawValue: Settings.NotificationTypes.getWithDefault(Settings.NoteType.All.rawValue))
			cell.accessoryType = (filterStateRaw.contains(Settings.NoteType.fromPos(indexPath.row))) ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		if indexPath.section == 0
		{
			var types = Settings.NoteType(rawValue: Settings.NotificationTypes.getWithDefault(Settings.NoteType.All.rawValue))
			let typeForRow = Settings.NoteType.fromPos(indexPath.row)
			if types.contains(typeForRow) {
				types.remove(typeForRow)
			} else {
				types.insert(typeForRow)
			}
			
			Settings.NotificationTypes.set(types.rawValue)
			self.tableView.reloadData()
		}
	}
}
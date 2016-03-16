//
//  NotificationController.swift
//  Tavi
//
//  Created by thislooksfun on 3/15/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import Foundation

class NotificationController: PortraitTableViewController
{
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
		
		if indexPath.section == 0 {
			let filterStateRaw = Settings.InAppNoteType(rawValue: Settings.InAppNotificationTypes.getWithDefault(Settings.InAppNoteType.All.rawValue))
			cell.accessoryType = (filterStateRaw.contains(Settings.InAppNoteType.fromPos(indexPath.row))) ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
		}
		
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		if indexPath.section == 0
		{
			var types = Settings.InAppNoteType(rawValue: Settings.InAppNotificationTypes.getWithDefault(Settings.InAppNoteType.All.rawValue))
			let typeForRow = Settings.InAppNoteType.fromPos(indexPath.row)
			if types.contains(typeForRow) {
				types.remove(typeForRow)
			} else {
				types.insert(typeForRow)
			}
			
			Settings.InAppNotificationTypes.set(types.rawValue)
			self.tableView.reloadData()
		}
	}
}
//
//  NotificationController.swift
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
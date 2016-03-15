//
//  FilterController.swift
//  Tavi
//
//  Created by thislooksfun on 2/12/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class FilterController: PortraitTableViewController
{
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
		
		if Settings.FilterState.get() == nil {
			Settings.FilterState.set(Settings.Filter.Active.rawValue)
		}
		
		let filterStateRaw = Settings.FilterState.get()!
		cell.accessoryType = (indexPath.row == filterStateRaw) ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None
		
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		Settings.FilterState.set(indexPath.row)
		self.tableView.reloadData()
	}
}
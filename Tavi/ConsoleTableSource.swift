//
//  ConsoleTableController.swift
//  Tavi
//
//  Created by thislooksfun on 12/2/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class ConsoleTableSource: NSObject, UITableViewDelegate, UITableViewDataSource
{
	@IBOutlet weak var table: UITableView!
	@IBOutlet weak var tableHeight: NSLayoutConstraint!
	@IBOutlet weak var tableWidth: NSLayoutConstraint!
	private var data = [RowInfo]()
	private var groups = [Group]()
	private var longestWidth: CGFloat = -1
	
	private var font = UIFont(name: "Inconsolata", size: 14)!
	private var groupStartColor = UIColor(white: 43/255, alpha: 1)
	private var defaultColor = UIColor(white: 34/255, alpha: 1)
	
	func load(job: TravisBuildJob)
	{
		self.clearRows(reloadAndResize: false)
		
		job.getLog(loadFromJson)
		
		self.addRow("Hi", reloadAndResize: false)
		self.addRow("How are you?", reloadAndResize: false)
		self.addRow("I'm doing pretty well", reloadAndResize: false)
		self.addRow("Thanks for asking", reloadAndResize: false)
		self.addRow("How's Sally?", reloadAndResize: false)
		self.addRow("I heard she got a dog", reloadAndResize: false)

		self.addRow("This is the start of a group", isGroupStart: true, reloadAndResize: false)
		self.addRow("This is part 1/3 of a group", reloadAndResize: false)
		self.addRow("This is part 2/3 of a group", reloadAndResize: false)
		self.addRow("This is part 3/3 of a group", reloadAndResize: false)
		self.addRow("This is the end of the group", isGroupEnd: true, reloadAndResize: false)
		
		self.addRow("Here is some more stuff", reloadAndResize: false)
		self.addRow("This should be visible", reloadAndResize: false)
		self.addRow("This is a really long line of text to make sure that horizontal (sideways) scrolling is working properly when it encounters a long line of console input.", reloadAndResize: false)
		
		for _ in 1...9 {
			self.addRow("Filler text...", reloadAndResize: false)
		}
		
		self.reloadAndResize()
	}
	
	private func loadFromJson(json: JSON) {
		Logger.info(json)
	}
	
	func didLayoutSubviews() {
		self.resizeTable()
	}
	
	func clearRows(reloadAndResize refresh: Bool = true) {
		self.data.removeAll()
		longestWidth = -1
		
		guard refresh else { return }
		self.table.reloadData()
		self.resizeTable()
	}
	
	private var groupStart = -1
	func addRow(text: String, isGroupStart: Bool = false, isGroupEnd: Bool = false, reloadAndResize refresh: Bool = true)
	{
		if isGroupStart {
			groupStart = data.count
		} else if groupStart > -1 && isGroupEnd {
			let group = Group(startIndex: groupStart, endIndex: data.count, expanded: false)
			if !groups.contains(group) {
				self.groups.append(group)
			}
			groupStart = -1
		}
		
		let row = RowInfo(
			row: data.count+1,
			data: text
		)
		data.append(row)
		
		let str = text as NSString
		let size = str.sizeWithAttributes([NSFontAttributeName: font])
		
		if size.width > longestWidth {
			longestWidth = size.width
		}
		
		guard refresh else { return }
		self.reloadAndResize()
	}
	
	func reloadAndResize() {
		self.groups.sortInPlace({ (group1, group2) -> Bool in
			return group1.startIndex < group2.startIndex
		})
		self.table.reloadData()
		self.resizeTable()
	}
	
	func resizeTable() {
		tableHeight.constant = table.rowHeight * CGFloat(data.count - sumContractedGroups())
		tableWidth.constant = 84 + longestWidth
	}
	
	func toggleExpand(sender: UIButton) {
		guard var group = groupForConsoleRow(sender.tag) else { return }
		group.expanded.flip()
		replaceGroupForConsoleRow(sender.tag, withGroup: group)
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count - sumContractedGroups()
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("ConsoleCell", forIndexPath: indexPath) as! ConsoleLineCell
		
		cell.selectionStyle = UITableViewCellSelectionStyle.None
		
		let offsetRow = offsetTableRowForGroups(indexPath.row)
		let info = data[offsetRow]
		let group = groupForTableRow(indexPath.row)
		if group != nil && group!.startIndex == offsetRow {
			cell.backgroundColor = groupStartColor
			
			cell.disclosureArrow.hidden = false
			cell.disclosureArrow.highlighted = group!.expanded
			
			cell.expandButton.tag = offsetRow
			cell.expandButton.addTarget(self, action: "toggleExpand:", forControlEvents: .TouchUpInside)
		} else {
			cell.backgroundColor = defaultColor
			
			cell.disclosureArrow.hidden = true
			
			cell.expandButton.removeTarget(self, action: "toggleExpand:", forControlEvents: .TouchUpInside)
		}
		
		cell.lineNumber = info.row
		cell.lineText = info.data
		
		//TODO: Support command line colors
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		table.deselectRowAtIndexPath(indexPath, animated: false)
	}
	
	func tableView(tableView: UITableView, canFocusRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	
	func offsetTableRowForGroups(row: Int) -> Int {
		var out = row
		for group in self.groups {
			if group.startIndex < out {
				if !group.expanded {
					out += group.length
				}
			} else {
				//No point in looking any further, we've passed it now.
				break
			}
		}
		return out
	}
	func sumContractedGroups() -> Int {
		var out = 0
		for group in self.groups {
			if !group.expanded {
				out += group.length
			}
		}
		return out
	}
	func groupForTableRow(row: Int) -> Group? {
		return groupForConsoleRow(offsetTableRowForGroups(row))
	}
	func groupForConsoleRow(row: Int) -> Group? {
		for group in groups {
			if group.startIndex <= row && group.endIndex >= row {
				return group
			}
		}
		return nil
	}
	func replaceGroupForConsoleRow(row: Int, withGroup: Group) {
		for (index, group) in groups.enumerate() {
			if group.startIndex <= row && group.endIndex >= row {
				groups[index] = withGroup
				break
			}
		}
		self.resizeTable()
		self.table.reloadData()
	}
	
	struct Group: Equatable {
		let startIndex: Int
		let endIndex: Int
		var expanded: Bool
		
		var length: Int {
			get {
				return endIndex - startIndex
			}
		}
	}
	struct RowInfo {
		let row: Int
		var data: String
	}
}

func ==(left: ConsoleTableSource.Group, right: ConsoleTableSource.Group) -> Bool {
	return left.startIndex == right.startIndex
		&& left.endIndex == right.endIndex
		//Intentionally don't check expand state
}
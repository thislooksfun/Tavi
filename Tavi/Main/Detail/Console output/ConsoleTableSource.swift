//
//  ConsoleTableController.swift
//  Tavi
//
//  Created by thislooksfun on 12/2/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

/// The class in charge of supplying the console table with its information
class ConsoleTableSource: NSObject, UITableViewDelegate, UITableViewDataSource
{
	/// The table object
	@IBOutlet weak var table: UITableView!
	/// The height of the table
	@IBOutlet weak var tableHeight: NSLayoutConstraint!
	/// The width of the table
	@IBOutlet weak var tableWidth: NSLayoutConstraint!
	
	/// The information for the rows
	private var data = [RowInfo]()
	/// The information about groups
	private var groups = [Group]()
	/// The longest line width - used to adjust `tableWidth` for proper scrolling
	private var longestWidth: CGFloat = -1
	
	/// The font the table uses
	private let font = UIFont(descriptor: UIFontDescriptor(name: "Inconsolata", size: 14), size: 14)
	/// The color for a cell that is the start of a group
	private var groupStartColor = UIColor(white: 43/255, alpha: 1)
	/// The color for all cells that aren't part of a group
	private var defaultColor = UIColor(white: 34/255, alpha: 1)
	
	/// Loads information for the table from a given `TravisBuildJob`
	///
	/// - Parameters:
	///   - job: The job to load from
	///   - done: The closure to execute upon load completion
	func load(job: TravisBuildJob, done: () -> Void)
	{
		self.clearRows(reloadAndResize: false)
		
		// TODO:
//		job.getLog(loadFromJson)
		
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
		
		//TODO: Load console from remote
		
		self.reloadAndResize()
		
		async(cb: done)
	}
	
	/// Loads the row information from a `JSON` object
	///
	/// - Parameter json: The `JSON` object to load from
	private func loadFromJson(json: JSON) {
		Logger.info(json)
	}
	
	/// Called by `DetailViewController` to tell this class that
	/// the subviews have been layed out, and it can now re-arrange them
	func didLayoutSubviews() {
		self.resizeTable()
	}
	
	/// Removes all the rows from the table, and optionally resizes it
	///
	/// - Parameter refresh: Whether or not to update and resize the table (Default: `true`)
	func clearRows(reloadAndResize refresh: Bool = true) {
		self.data.removeAll()
		longestWidth = -1
		
		guard refresh else { return }
		self.table.reloadData()
		self.resizeTable()
	}
	
	/// The start index of the most recent group.
	/// Used by `addRow:`
	private var groupStart = -1
	
	/// Adds a row to the table
	///
	/// - Parameters:
	///   - text: The body of the row
	///   - isGroupStart: Whether or not this row is the start of a group (Default: `false`)
	///   - isGroupEnd: Whether or not this row in the end of a group (Default: `false`)
	///   - refresh: Whether or not to update and resize the table (Default: `true`)
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
	
	/// Sorts the data, and refreshes and resizes the table
	func reloadAndResize() {
		self.groups.sortInPlace({ (group1, group2) -> Bool in
			return group1.startIndex < group2.startIndex
		})
		self.table.reloadData()
		self.resizeTable()
	}
	
	/// Resizes the table to allow for correct scrolling behavior
	func resizeTable() {
		tableHeight.constant = table.rowHeight * CGFloat(data.count - sumContractedGroups())
		tableWidth.constant = 84 + longestWidth
	}
	
	/// Toggles whether or not a group is expanded
	///
	/// - Parameter sender: The button that was pressed
	func toggleExpand(sender: UIButton) {
		guard var group = groupForConsoleRow(sender.tag) else { return }
		group.expanded.flip()
		replaceGroupForConsoleRow(sender.tag, withGroup: group)
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count - sumContractedGroups()
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
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
			cell.expandButton.addTarget(self, action: #selector(ConsoleTableSource.toggleExpand(_:)), forControlEvents: .TouchUpInside)
		} else {
			cell.backgroundColor = defaultColor
			
			cell.disclosureArrow.hidden = true
			
			cell.expandButton.removeTarget(self, action: #selector(ConsoleTableSource.toggleExpand(_:)), forControlEvents: .TouchUpInside)
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
	
	/// Calculates what the console row number will be from a given table index
	///
	/// - Parameter row: The table row to offset
	///
	/// - Returns: The row number, taking into account all the closed groups
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
	
	/// Sums all the rows in the contracted groups
	///
	/// - Returns: The number of lines that are currently hidden
	func sumContractedGroups() -> Int {
		var out = 0
		for group in self.groups {
			if !group.expanded {
				out += group.length
			}
		}
		return out
	}
	
	/// Gets a group from a specific table-indexed row
	///
	/// - Parameter row: The table-indexed row for which to get a group
	///
	/// - Returns: The group for the given row, or `nil` if no group exists for that row
	func groupForTableRow(row: Int) -> Group? {
		return groupForConsoleRow(offsetTableRowForGroups(row))
	}
	
	/// Gets a group from a specific console-indexed row
	///
	/// - Parameter row: The console-indexed row for which to get a group
	///
	/// - Returns: The group for the given row, or `nil` if no group exists for that row
	func groupForConsoleRow(row: Int) -> Group? {
		for group in groups {
			if group.startIndex <= row && group.endIndex >= row {
				return group
			}
		}
		return nil
	}
	
	/// Replaces a group containing a specific console-indexed row with a new group.
	///
	/// - Note: If no group currently exists at `row`, this will do nothing.
	///
	/// - Parameters:
	///   - row: The console-indexed row at which to replace the group
	///   - withGroup: The group to replace the old group with
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
	
	/// The struct used to keep track of groupings
	struct Group: Equatable
	{
		/// The start index of the group
		let startIndex: Int
		/// The end index of the group
		let endIndex: Int
		/// Whether or not the group is expanded
		var expanded: Bool
		
		/// The length of the group
		var length: Int {
			get {
				return endIndex - startIndex
			}
		}
	}
	
	/// The struct used to keep track of row information
	struct RowInfo
	{
		/// The console-indexed row number
		let row: Int
		/// The text content of the row
		var data: String
	}
}

/// Checks equality between two groups, ignoring the expanded state
func ==(left: ConsoleTableSource.Group, right: ConsoleTableSource.Group) -> Bool {
	return left.startIndex == right.startIndex
		&& left.endIndex == right.endIndex
		//Intentionally don't check expand state
}
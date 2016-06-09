//
//  ConsoleTableController.swift
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

/// The class in charge of supplying the console table with its information
class ConsoleTableSource: NSObject, UITableViewDelegate, UITableViewDataSource
{
	/// The table object
	@IBOutlet weak var table: UITableView!
	/// The height of the table
	@IBOutlet weak var tableHeight: NSLayoutConstraint!
	/// The width of the table
	@IBOutlet weak var tableWidth: NSLayoutConstraint!
	/// The sideways scroll view used by the console
	@IBOutlet weak var sidewaysScrollView: UIScrollView!
	
	/// The selected row - used to highlight the row to be copied
	private var selectedRow: Int = -1
	/// The information for the rows
	private var data = [RowInfo]()
	/// The information about groups
	private var groups = [Group]()
	/// The width of the longest line - used to adjust `tableWidth` for proper scrolling
	private var longestWidth: CGFloat = -1
	
	/// The font the table uses
	private let lineFont = UIFont(descriptor: UIFontDescriptor(name: "Inconsolata", size: 14), size: 14)
	/// The bolded version of the font the table uses
	private let lineFontBold = UIFont(descriptor: UIFontDescriptor(name: "Inconsolata-Bold", size: 14), size: 14)
	/// The font the table uses
	private let sectionInfoFont = UIFont(descriptor: UIFontDescriptor(name: "Inconsolata", size: 12), size: 12)
	/// The color for a cell that is the start of a group
	private let groupStartColor = UIColor(white: 43/255, alpha: 1)
	/// The color for all cells that aren't part of a group
	private let defaultColor = UIColor(white: 34/255, alpha: 1)
	/// The color for all highlighted cells that aren't part of a group
	private let cellHighlightColor = UIColor(white: 52/255, alpha: 1)
	/// The color of the text in the console view
	private var consoleTextColor = UIColor(white: 241/255, alpha: 1)
	
	/// A closure to call after the `reloadAndResize:` function runs
	var afterReloadResize: (() -> Void)? = nil
	
	
	/// Loads information for the table from a given `TravisBuildJob`
	///
	/// - Parameters:
	///   - job: The job to load from
	///   - done: The closure to execute upon load completion
	func load(job: TravisBuildJob, done: () -> Void)
	{
		self.clearRows(reloadAndResize: false)
		
		async(onNewThread: true) {
			Logger.info("Loading log")
			job.getLog() { (log) in
				self.loadFromLog(log)
				async(cb: done)
			}
		}
	}
	
	/// Loads the row information from a `TravisBuildLog` object
	///
	/// - Parameter log: The `TravisBuildLog` to load from
	private func loadFromLog(log: TravisBuildLog) {
		let lines = log.lines
		
		// Don't bother loading if there's nothing to load
		guard lines.count > 0 else { return }
		
		let maxLines = 1000 //TODO: Populate this from .travis.yml, or wherever it's stored?
		guard lines.count < maxLines else {
			Logger.warn("Log too large")
			self.addRow(NSAttributedString(string: "The log is too large to be displayed"))
			self.addRow(NSAttributedString(string: "\(lines.count - maxLines) lines longer than the \(maxLines) line limit"))
			async(cb: self.reloadAndResize)
			//TODO: Add raw log link when log is too large?
			return
		}
		
		for line in lines
		{
			let lineStr = NSMutableAttributedString()
			for segment in line.segments {
				lineStr += segment.toAttributedStringWithFont(lineFont, andBoldFont: lineFontBold, andForegroundColor: consoleTextColor, andBackgroundColor: line.isGroupStart ? groupStartColor : defaultColor)
			}
			self.addRow(lineStr, withSectionTitle: line.groupName, andSectionTime: line.time, isGroupStart: line.isGroupStart, isGroupEnd: line.isGroupEnd)
		}
		
		async(cb: self.reloadAndResize)
		
		
		//TODO: add this somewhere for testing, and toggle it via the secret button
		/*
		var lines: [TravisBuildLog.Line] = []
		
		// Control
		lines.append(TravisBuildLog.Line(segments: ANSIParse.parse("Control codes"), groupName: "", isGroupStart: false, isGroupEnd: false, time: nil))
		for i in 1...8 {
		let segments = ANSIParse.parse("\u{001B}[\(i)m" + "ESC[\(i)m" + "\u{001B}[2\(i)m (Reset with ESC[2\(i)m)")
		lines.append(TravisBuildLog.Line(segments: segments, groupName: "", isGroupStart: false, isGroupEnd: false, time: nil))
		}
		
		// Foreground
		lines.append(TravisBuildLog.Line(segments: ANSIParse.parse("\nForeground colors"), groupName: "", isGroupStart: false, isGroupEnd: false, time: nil))
		for i in [Int](30...37) + [Int](90...97) {
		let segments = ANSIParse.parse("\u{001B}[\(i)m" + "ESC[\(i)m" + " \u{001B}[40m" + "ESC[\(i)m" + " \u{001B}[47m" + "ESC[\(i)m" + "\u{001B}[0m")
		lines.append(TravisBuildLog.Line(segments: segments, groupName: "", isGroupStart: false, isGroupEnd: false, time: nil))
		}
		
		// Background
		lines.append(TravisBuildLog.Line(segments: ANSIParse.parse("\nBackground colors"), groupName: "", isGroupStart: false, isGroupEnd: false, time: nil))
		for i in [Int](40...47) + [Int](100...107) {
		let segments = ANSIParse.parse("\u{001B}[\(i)m" + "ESC[\(i)m" + " \u{001B}[30m" + "ESC[\(i)m" + " \u{001B}[37m" + "ESC[\(i)m" + "\u{001B}[0m")
		lines.append(TravisBuildLog.Line(segments: segments, groupName: "", isGroupStart: false, isGroupEnd: false, time: nil))
		}
		
		self.consoleTableSource.loadFromLineArray(lines)
		*/
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
		self.groups.removeAll()
		
		longestWidth = -1
		
		guard refresh else { return }
		self.reloadAndResize()
	}
	
	/// The start index of the most recent group.
	/// Used by `addRow:`
	private var groupStart = -1
	
	/// Adds a row to the table
	///
	/// - Parameters:
	///   - text: The body of the row
	///   - sectionTitle: The title of the fold section (Default: `"")
	///   - sectionTime: The time this line or group took to execute (Default: `nil`)
	///   - isGroupStart: Whether or not this row is the start of a group (Default: `false`)
	///   - isGroupEnd: Whether or not this row in the end of a group (Default: `false`)
	///   - refresh: Whether or not to update and resize the table (Default: `false`)
	func addRow(text: NSAttributedString, withSectionTitle sectionTitle: String = "", andSectionTime sectionTime: Int? = nil, isGroupStart: Bool = false, isGroupEnd: Bool = false, reloadAndResize refresh: Bool = false)
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
		
		Logger.trace("Adding row \(text)")
		
		let row = RowInfo(
			row: data.count+1,
			data: text,
			sectionTitle: sectionTitle,
			sectionTime: sectionTime
		)
		data.append(row)
		
		
		// Find the longest line width
		let width = text.size().width
		
		
		// Find the longest info section
		
		let titleStr = (sectionTitle ?? "") as NSString
		let timeStr = (sectionTime == nil ? "" : String(format: "%.3f", sectionTime!)) as NSString
		
		let titleWidth = titleStr.sizeWithAttributes([NSFontAttributeName: sectionInfoFont]).width
		let timeWidth =  timeStr.sizeWithAttributes( [NSFontAttributeName: sectionInfoFont]).width
		
		// Calculate the total width.
		// Formula: [4px + title width + 4px] + [4px + time width + 4px] + [an 8 px gap between them, if they are both >0] + [an 8 px gap with the right edge, if either of them are >0]
		let totalWidth = width + titleWidth + (titleWidth > 0 ? 8 : 0) + timeWidth + (timeWidth > 0 ? 8 : 0) + (titleWidth > 0 && timeWidth > 0 ? 8 : 0) + (titleWidth + timeWidth > 0 ? 8 : 0)

		if totalWidth > longestWidth {
			longestWidth = totalWidth
		}
		
		
		// Update the table's bounds
		
		guard refresh else { return }
		self.reloadAndResize()
	}
	
	/// Sorts the data, and refreshes and resizes the table
	func reloadAndResize()
	{
		// This will likely never be used, but just in case...
		guard self.table != nil else { return }
		
		self.groups.sortInPlace({ (group1, group2) -> Bool in
			return group1.startIndex < group2.startIndex
		})
		self.table.reloadData()
		self.resizeTable()
		
		// Make this wait a bit for it to actually take effect.
		// No idea why the delay is required though. :/
		delay(0.05) {
			// Prevent crash when going in and out quickly
			guard self.sidewaysScrollView != nil else { return }
			self.scrollViewDidScroll(self.sidewaysScrollView)
			self.afterReloadResize?()
		}
	}
	
	/// Resizes the table to allow for correct scrolling behavior
	func resizeTable() {
		let newHeight = table.rowHeight * CGFloat(data.count - sumContractedGroups())
		tableHeight.constant = newHeight < 0 ? 0 : newHeight //Ensure the height is >= 0
		let newWidth = 84 + longestWidth
		tableWidth.constant = newWidth < 0 ? 0 : newWidth //Ensure the width is >= 0
	}
	
	/// Toggles whether or not a group is expanded
	///
	/// - Parameter sender: The button that was pressed
	func toggleExpand(sender: UIButton) {
		guard var group = groupForConsoleRow(sender.tag) else { return }
		group.expanded.invert()
		replaceGroupForConsoleRow(sender.tag, withGroup: group)
	}
	
	/// Highlights a row of the console
	///
	/// - Parameter index: The index path to highlight
	func highlightIndex(index: NSIndexPath) {
		Logger.debug("Highlighting row \(index.row)")
		self.selectedRow = index.row
		self.table.reloadRowsAtIndexPaths([index], withRowAnimation: UITableViewRowAnimation.None)
	}
	
	/// De-highlights all the rows in the console
	func dehighlightAll() {
		self.selectedRow = -1
		self.table.reloadData()
	}
	
	func copyHighlightedRow() {
		guard self.selectedRow > -1 else { return } //Make sure something is selected
		guard self.selectedRow < data.count else { return } //Also make sure it's not out of range
		let cell = self.tableView(self.table, cellForRowAtIndexPath: NSIndexPath(forRow: self.selectedRow, inSection: 0)) as! ConsoleLineCell
		UIPasteboard.generalPasteboard().string = cell.lineText.string
		//TODO: Copy attributed string too?
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
		
		cell.sectionTitle = info.sectionTitle
		cell.sectionTime = info.sectionTime
		
		return cell
	}

	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.row == selectedRow {
			//Selected, display that color
			cell.backgroundColor = cellHighlightColor
		} else if !(cell as! ConsoleLineCell).disclosureArrow.hidden {
			//The disclosure arrow is showing, it must be the start of a group!
			cell.backgroundColor = groupStartColor
		} else {
			//Not selected, not part of a group
			cell.backgroundColor = defaultColor
		}
	}
	
	func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
		return nil
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
		var data: NSAttributedString
		
		/// The section title
		var sectionTitle: String
		/// The time the section took to execute
		var sectionTime: Int?
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView)
	{
		var distance: CGFloat = 0
		
		if scrollView.contentOffset.x > (scrollView.contentSize.width - scrollView.frame.width) {
			distance = 8;
		} else if scrollView.contentOffset.x < 0 {
			distance = tableWidth.constant - (UIScreen.mainScreen().bounds.width - 8);
		} else {
			distance = tableWidth.constant - scrollView.contentOffset.x - (UIScreen.mainScreen().bounds.width - 8);
		}
		
		for cell in table.visibleCells as! [ConsoleLineCell] where !cell.sectionTitleLabel.hidden || !cell.sectionTimeLabel.hidden {
			cell.sectionInfoDistanceToRight.constant = distance
			cell.sectionInfoEdgeLockDistanceToRight.constant = distance - 8 //Only keep part of the first letter
		}
	}
}

/// Checks equality between two groups, ignoring the expanded state
func ==(left: ConsoleTableSource.Group, right: ConsoleTableSource.Group) -> Bool {
	return left.startIndex == right.startIndex
		&& left.endIndex == right.endIndex
		//Intentionally don't check expand state
}
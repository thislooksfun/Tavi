//
//  ConsoleLineCell.swift
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

/// The cell of a single line
class ConsoleLineCell: UITableViewCell
{
	/// The disclosure arrow used by the first cell of a group
	@IBOutlet var disclosureArrow: UIImageView!
	/// The line number label
	@IBOutlet var lineNumberLabel: UILabel!
	/// The actual text content of the line
	@IBOutlet var lineTextLabel: UILabel!
	/// The button on top of the disclosure arrow that registers
	/// when the user taps to expand the group
	@IBOutlet var expandButton: UIButton!
	
	/// The title of the console section
	@IBOutlet var sectionTitleLabel: UILabel!
	/// The time the section took to execute
	@IBOutlet var sectionTimeLabel: UILabel!
	/// The distance from the section information to the
	/// right edge of the screen
	@IBOutlet var sectionInfoDistanceToRight: NSLayoutConstraint!
	
	/// The line number this cell represents
	var lineNumber: Int {
		get {
			return Int(lineNumberLabel.text ?? "") ?? -1
		}
		set {
			lineNumberLabel.text = "\(newValue)"
		}
	}
	
	/// The text content of the line
	var lineText: NSAttributedString {
		get {
			return lineTextLabel.attributedText ?? NSAttributedString()
		}
		set {
			lineTextLabel.attributedText = newValue
		}
	}
	
	var sectionTitle: String {
		get {
			return sectionTitleLabel.text ?? ""
		}
		set {
			if !newValue.isEmpty {
				sectionTitleLabel.text = newValue
				sectionTitleLabel.hidden = false
			} else {
				sectionTitleLabel.hidden = true
			}
		}
	}
	
	var sectionTime: Int? {
		get {
			return Int((Double(sectionTimeLabel.text ?? "") ?? 0) * 1000)
		}
		set {
			if let val = newValue {
				sectionTimeLabel.text = String(format: "%.2fs", Double(val) / 1000)
				sectionTimeLabel.hidden = false
			} else {
				sectionTimeLabel.hidden = true
			}
		}
	}
}
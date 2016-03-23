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
	
	/// The line number this cell represents
	var lineNumber: Int {
		get {
			return Int(lineNumberLabel.text!) ?? -1
		}
		set {
			lineNumberLabel.text = "\(newValue)"
		}
	}
	
	/// The text content of the line
	var lineText: String {
		get {
			return self.lineTextLabel.text ?? ""
		}
		set {
			self.lineTextLabel.text = newValue
		}
	}
}
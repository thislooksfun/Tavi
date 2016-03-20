//
//  ConsoleLineCell.swift
//  Tavi
//
//  Created by thislooksfun on 12/2/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
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
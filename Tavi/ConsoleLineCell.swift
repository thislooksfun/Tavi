//
//  ConsoleLineCell.swift
//  Tavi
//
//  Created by thislooksfun on 12/2/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class ConsoleLineCell: UITableViewCell
{
	@IBOutlet var disclosureArrow: UIImageView!
	@IBOutlet var lineNumberLabel: UILabel!
	@IBOutlet var lineTextLabel: UILabel!
	@IBOutlet var expandButton: UIButton!
	
	var lineNumber: Int {
		get {
			return Int(lineNumberLabel.text!) ?? -1
		}
		set {
			lineNumberLabel.text = "\(newValue)"
		}
	}
	
	var lineText: String {
		get {
			return self.lineTextLabel.text ?? ""
		}
		set {
			self.lineTextLabel.text = newValue
		}
	}
}
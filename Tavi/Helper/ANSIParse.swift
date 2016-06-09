//
//  ANSIParse.swift
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
import UIColor_Hex_Swift

/// A fairly simple class for parsing ANSI formatted text into usable segments
public class ANSIParse
{
	/// Whether or not to add extra debug information to the output
	public static var includeDebugPrinting = false
	
	/// The regular color scheme
	public static let colors = [
		0: UIColor(rgba: "#4E4E4E"), //Black
		1: UIColor(rgba: "#FF6C60"), //Red
		2: UIColor(rgba: "#00AA00"), //Green
		3: UIColor(rgba: "#FFFFB6"), //Yellow
		4: UIColor(rgba: "#96CBFE"), //Blue
		5: UIColor(rgba: "#FF73FD"), //Magenta
		6: UIColor(rgba: "#00AAAA"), //Cyan
		7: UIColor(rgba: "#CCCCCC")  //Gray
	]
	/// The lightened color scheme
	public static let lightColors = [
		0: UIColor(rgba: "#7C7C7C"), //Dark Gray
		1: UIColor(rgba: "#FF9B93"), //Red
		2: UIColor(rgba: "#B1FD79"), //Green
		3: UIColor(rgba: "#FFFF91"), //Yellow
		4: UIColor(rgba: "#B5DCFE"), //Blue
		5: UIColor(rgba: "#FF9CFE"), //Magenta
		6: UIColor(rgba: "#55FFFF"), //Cyan
		7: UIColor(rgba: "#FFFFFF")  //White
	]

	// Used to do proper cross-line formatting
	private static var formatting: ANSIAttributes = []
	private static var foreground: UIColor? = nil
	private static var background: UIColor? = nil
	
	
	/// The `escape` character. Used along with `[` to indicate the start of an ANSI code
	private static let esc = "\u{001B}"
	
	/// Parses the given string into ANSI formatted segments
	///
	/// - Parameter string: The string to parse
	///
	/// - Returns: An array of `ANSISegment`s
	static func parse(string: String) -> [ANSISegment]
	{
		// If there's nothing to parse, don't bother
		guard !string.isEmpty else { return [] }
		
		// If the string has no escape codes, don't bother trying to parse it
		guard string.containsString("\(esc)[") else {
			return [ANSISegment(formatting: formatting, foreground: foreground, background: background, text: string)]
		}
		
		let codeSeparations = string.split("\(esc)[", ignoreEmpty: true)
		
		var segments = [ANSISegment]()
		
		for sep in codeSeparations
		{
			var debugTxt = ""
			var sgmtTxt = ""
			
			//TODO: Implement more of these?
			
			if let codeEnd = sep.characters.indexOf("A") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Cursor up
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)A"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("B") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Cursor down
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)B"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("C") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Cursor forward
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)C"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("D") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Cursor backwards
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)D"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("E") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Cursor next line
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)E"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("F") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Cursor prev line
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)F"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("G") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Cursor horizontal absolute
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)G"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("H") where sep.substringToIndex(codeEnd) =~ "^\\d;\\d$" { // Cursor position
				let codeStrs = sep.substringToIndex(codeEnd).split(";")
				debugTxt = "ESC[\(codeStrs.joinWithSeparator(";"))H"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("J") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Erase display
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)J"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("K") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Erase in line
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)K"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("S") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Scroll up
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)S"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("T") where sep.substringToIndex(codeEnd) =~ "^\\d?$" { // Scroll down
				let codeStr = sep.substringToIndex(codeEnd)
				debugTxt = "ESC[\(codeStr)T"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("f") where sep.substringToIndex(codeEnd) =~ "^\\d;\\d$" { // Same as H
				let codeStrs = sep.substringToIndex(codeEnd).split(";")
				debugTxt = "ESC[\(codeStrs.joinWithSeparator(";"))f"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("m") where sep.substringToIndex(codeEnd) =~ "^(\\d\\d?;?)+$" { // Select graphic rendition (color/effects)
				let codeStrs = sep.substringToIndex(codeEnd).split(";")
				debugTxt = "ESC[\(codeStrs.joinWithSeparator(";"))m"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
				
				for codeStr in codeStrs {
					guard let code = Int(codeStr) else {
						print("\(codeStr) isn't an Int!")
						continue
					}
					
					switch code {
					case 0: clearPrevFormatting() //Reset all
						
					case 1...8:   formatting.unionInPlace(ANSIAttributes.fromCode(code))         //Set format flag
					case 21...28: formatting.subtractInPlace(ANSIAttributes.fromCode(code - 20)) //Reset format flag
						
					case 39:      foreground = nil                    //Use default foreground color
					case 30...37: foreground = colors[code - 30]      //Set foreground color
					case 90...97: foreground = lightColors[code - 90] //Set light foreground color
						
					case 49:        background = nil                     //Use default background color
					case 40...47:   background = colors[code - 40]       //Set background color
					case 100...107: background = lightColors[code - 100] //Set light background color
						
					default: print("Unknown \(code)") //Unknown code
					}
				}
			} else if let codeEnd = sep.characters.indexOf("s") where sep.substringToIndex(codeEnd) =~ "^$" { // Save cursor position
				debugTxt = "ESC[s"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else if let codeEnd = sep.characters.indexOf("u") where sep.substringToIndex(codeEnd) =~ "^$" { // Restore cursor position
				debugTxt = "ESC[u"
				sgmtTxt = sep.substringFromIndex(codeEnd.successor())
			} else {
				sgmtTxt = sep
			}
			
			// If debug printing is on, show it (but without any formatting)
			if includeDebugPrinting && !debugTxt.isEmpty {
				segments.append(ANSISegment(formatting: [], foreground: nil, background: nil, text: debugTxt))
			}
			
			// If there is no text, don't try to add it
			guard !sgmtTxt.isEmpty else { continue }
			
			segments.append(ANSISegment(formatting: formatting, foreground: foreground, background: background, text: sgmtTxt))
		}
		
		return segments
	}
	
	/// Clears all of the stored formatting information.  \
	/// This **_MUST_** be called after every formatting session,
	/// or else the next session will have incorrect formatting until
	/// the first reset code.
	public static func clearPrevFormatting() {
		formatting = []
		foreground = nil
		background = nil
	}
	
	/// One ANSI formatted segment
	public struct ANSISegment
	{
		/// The ANSI format attributes (bold, underlined, etc)
		/// - SeeAlso: ANSIAttributes
		public let formatting: ANSIAttributes
		/// The text color - can be nil
		public let foreground: UIColor?
		/// The background color - can be nil
		public let background: UIColor?
		/// The actual text of the segment
		public let text: String
		
		/// Converts the segment into an `NSAttributedString`
		/// 
		/// - Arguments:
		///   - font: The default text font
		///   - boldFont: The bolded text font
		///   - fgColor: The default text color
		///   - bgColor: The default background color
		///
		/// - Returns: An `NSAttributedString` representing this segment
		public func toAttributedStringWithFont(font: UIFont, andBoldFont boldFont: UIFont, andForegroundColor fgColor: UIColor, andBackgroundColor bgColor: UIColor) -> NSAttributedString {
			var attrs: [String: AnyObject] = [NSFontAttributeName: font]
			
			var reverse = false
			if self.formatting.contains(.Bold) {
				attrs[NSFontAttributeName] = boldFont
			}
			if self.formatting.contains(.Underline) {
				attrs[NSUnderlineStyleAttributeName] = NSUnderlineStyle.StyleSingle.rawValue
			}
			if self.formatting.contains(.Reverse) {
				reverse = true
			}
			
			//			if self.formatting.contains(.Dim) {}    //Dim isn't supported. Maybe in a future version?
			//			if self.formatting.contains(.Blink) {}  //Blink isn't supported. Maybe in a future version?
			//			if self.formatting.contains(.Hidden) {} //Hidden isn't supported. Maybe in a future version?
			
			if reverse {
				attrs[NSForegroundColorAttributeName] = self.background ?? bgColor
				attrs[NSBackgroundColorAttributeName] = self.foreground ?? fgColor
			} else {
				if self.foreground != nil {
					attrs[NSForegroundColorAttributeName] = self.foreground!
				}
				if self.background != nil {
					attrs[NSBackgroundColorAttributeName] = self.background!
				}
			}
			
			return NSAttributedString(string: self.text, attributes: attrs)
		}
	}
	
	/// ANSI format attributes (bold, underline, etc.)
	public struct ANSIAttributes: OptionSetType
	{
		/// The raw int value
		public let rawValue: Int
		
		/// Constructs an `ANSIAttributes` instance
		public init(rawValue: Int) { self.rawValue = rawValue }
		
		/// Bold the text
		public static let Bold = ANSIAttributes(rawValue: 1 << 1)
		/// Dims the text
		public static let Dim = ANSIAttributes(rawValue: 1 << 2)
		/// Underlines the text
		public static let Underline = ANSIAttributes(rawValue: 1 << 4)
		/// Makes the text blink
		public static let Blink = ANSIAttributes(rawValue: 1 << 5)
		/// Reverses the foreground and background colors
		public static let Reverse = ANSIAttributes(rawValue: 1 << 7)
		/// Hides the text
		public static let Hidden = ANSIAttributes(rawValue: 1 << 8)
		
		/// Gets the attribute for a specific ANSI code
		///
		/// Accepted codes:\
		///  1: Bold\
		///  2: Dim\
		///  4: Underline\
		///  5: Blink\
		///  7: Reverse\
		///  8: Hidden\
		/// Note that 3 and 6 are invalid codes
		///
		/// - Parameter code: The code to get the attribute for
		///
		/// - Returns: The attribute, or [] if the code was invalid
		public static func fromCode(code: Int) -> ANSIAttributes {
			switch code {
			case 1: return .Bold
			case 2: return .Dim
		//  case 3: return .???
			case 4: return .Underline
			case 5: return .Blink
		//  case 6: return .???
			case 7: return .Reverse
			case 8: return .Hidden
			default: return []
			}
		}
	}
}
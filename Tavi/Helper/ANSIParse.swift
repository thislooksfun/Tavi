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
	/// The regular color scheme
	public static let colors = [
		0: UIColor(rgba: "#4E4E4E"), //Black
		1: UIColor(rgba: "#FF6C60"), //Red
		2: UIColor(rgba: "#00AA00"), //Green
		3: UIColor(rgba: "#FFFFB6"), //Yellow
		4: UIColor(rgba: "#96CBFE"), //Blue
		5: UIColor(rgba: "#FF73FD"), //Magenta
		6: UIColor(rgba: "#00AAAA"), //Cyan
		7: UIColor(rgba: "#969696")  //Gray
	]
	/// The lightened color scheme
	public static let lightColors = [
		0: UIColor(rgba: "#969696"), //Dark Gray
		1: UIColor(rgba: "#FFB6B0"), //Red
		2: UIColor(rgba: "#CEFFAB"), //Green
		3: UIColor(rgba: "#FFFFCB"), //Yellow
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
			var sgmtTxt = ""
			
			//TODO: Implement more of these?
//			if let _ = sep.characters.indexOf("A")        { // Cursor up
//			} else if let _ = sep.characters.indexOf("B") { // Cursor down
//			} else if let _ = sep.characters.indexOf("C") { // Cursor forward
//			} else if let _ = sep.characters.indexOf("D") { // Cursor backwards
//			} else if let _ = sep.characters.indexOf("E") { // Cursor next line
//			} else if let _ = sep.characters.indexOf("F") { // Cursor prev line
//			} else if let _ = sep.characters.indexOf("G") { // Cursor horizontal absolute
//			} else if let _ = sep.characters.indexOf("H") { // Cursor position
//			} else if let _ = sep.characters.indexOf("J") { // Erase display
//			} else if let _ = sep.characters.indexOf("K") { // Erase in line
//			} else if let _ = sep.characters.indexOf("S") { // Scroll up
//			} else if let _ = sep.characters.indexOf("T") { // Scroll down
//			} else if let _ = sep.characters.indexOf("f") { // Same as H
//			} else if let _ = sep.characters.indexOf("m") { // Select graphic rendition (color/effects)
//			} else if let _ = sep.characters.indexOf("s") { // Save cursor position
//			} else if let _ = sep.characters.indexOf("u") { // Restore cursor position
			
			if let codeEnd = sep.characters.indexOf("m") { // Select graphic rendition (color/effects)
				let codeStrs = sep.substringToIndex(codeEnd).split(";")
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
			} else {
				sgmtTxt = sep
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
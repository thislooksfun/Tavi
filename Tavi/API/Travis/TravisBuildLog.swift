//
//  TravisBuildLog.swift
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

class TravisBuildLog
{
	var lines = [Line]()
	
	init?(json: JSON) {
		guard let parts = json.getJsonArray("parts") else { return nil }
		
		for part in parts {
			let rawContent = part.getString("content")!
			let rawLines = formatNewlines(rawContent)
			
			var nextIsGroupStart = false
			var nextName = ""
			
			var times = [String: Int]() //Dict of times: type = [UUID: start_line]. This will probably only ever have 1 value, but it doesn't hurt to be safe
			
			for line in rawLines
			{
				let stripped = strip(line)
				if stripped.hasPrefix("travis_")
				{
					if stripped.hasPrefix("travis_fold:start") {
						nextIsGroupStart = true
						nextName = stripped.substringFromIndex(stripped.startIndex.advancedBy(18))
					} else if stripped.hasPrefix("travis_fold:end") {
						var last = lines.removeLast()
						last.isGroupEnd = true
						lines.append(last)
					} else if stripped.hasPrefix("travis_time:start") {
						let uuid = stripped.substringWithRange(stripped.startIndex.advancedBy(18)..<stripped.endIndex.predecessor()) //Use a range to avoid capturing the newline
						times[uuid] = lines.count
						Logger.info("Added times[\(uuid)] = \(lines.count)")
					} else if stripped.hasPrefix("travis_time:end") {
						let dataStr = stripped.substringWithRange(stripped.startIndex.advancedBy(16)..<stripped.endIndex.predecessor()) //Use a range to avoid capturing the newline
						
						let separatorIndex = dataStr.characters.indexOf(":")!
						
						let uuid = dataStr.substringToIndex(separatorIndex)
						
						Logger.info(dataStr)
						let firstComma =  dataStr.characters.indexOf(",")!
						let secondComma = dataStr.substringFromIndex(firstComma.advancedBy(8)).characters.indexOf(",")!
						
						// The advancedBy bits in the above def for secondComma and in finishTimeStr and durationStr below
						// are to get rid of the 'finish=' and 'duration=' bits of the string
						
						// Maybe do something with these two later?
//						let startTimeStr =  dataStr.substringWithRange(separatorIndex.advancedBy(7)..<firstComma)
//						let finishTimeStr = dataStr.substringFromIndex(firstComma.advancedBy(8)).substringToIndex(secondComma)
						
						let durationStr = dataStr.substringFromIndex(firstComma.advancedBy(8)).substringFromIndex(secondComma.advancedBy(10))
						
						// Convert from microseconds to miliseconds
						// NOTE: This is a force floor operation. If the value is such that
						//       1ms < val <= 0.5ms, the resulting value will still be 0.
						Logger.info(durationStr.length)
						let duration = durationStr.length > 6 ? Int(durationStr.substringToIndex(durationStr.endIndex.advancedBy(-6))) : 0
						
						let lineNum = times.removeValueForKey(uuid)!
						var line = lines.removeAtIndex(lineNum)
						line.time = duration
						lines.insert(line, atIndex: lineNum)
					} else {
						Logger.info(stripped)
					}
					
					continue
				}
			
				
				let segments = ANSIParse.parse(stripped)
				
				if let lastLine = lines.last {
					//TODO: Overwrite, don't just blanket replace
					// Currently, inputting "123456789\rabc" will result in a line that says "321"
					// But "123456789\r321" should turn into "abc456789"
					if lastLine.segments.last?.text.hasSuffix("\r") ?? false {
						lines.removeLast()
					}
				}
				
				lines.append(Line(segments: segments, groupName: nextName, isGroupStart: nextIsGroupStart, isGroupEnd: false, time: nil))
				
				nextIsGroupStart = false
				nextName = ""
			}
		}
		
//		lines.append(Line(sections: [Section(color: "", message: "Line!")]))
	}
	
	/// The regex for a newline at the end of the string
	private var newlineAtTheEndRegex: NSRegularExpression? = {
		do {
			return try NSRegularExpression(pattern: "\n$", options: [])
		} catch {
			Logger.error(error)
			return nil
		}
	}()
	
	/// Formats the newlines of the given string, and returns an array of the lines
	///
	/// Examples:
	///   - Passing in "Hello\nWorld" would return ["Hello", "World"]
	///   - Passing in "Hello\r\nWorld" would also return ["Hello", "World"]
	///   - However, passing in "Hello\rWorld" would return ["Hello\r", "World"]
	///
	/// - Parameter str: The string to format
	///
	/// - Returns: The array of all of the lines
	private func formatNewlines(str: String) -> [String]
	{
		// Replace \r\n with just \n, no point in having double returns
		var intermediate = str.stringByReplacingOccurrencesOfString("\r\n", withString: "\n")
		
		/// Remove newlines from the end of the string
		//ERROR: Fix this not working properly (still keeping in blank lines it shouldn't, but only when reading chunked JSON)
		if intermediate.hasSuffix("\n") {
			intermediate = intermediate.substringToIndex(intermediate.endIndex.predecessor())
		} else if intermediate.length > 2 {
			Logger.trace("Last char = \(intermediate.substringFromIndex(intermediate.endIndex.advancedBy(-2)))")
		} else {
			Logger.trace("Line = \(intermediate)")
		}
		
		// Replace \r with \r\n, in order to keep the \r on the end of the line when splitting
		// This is important becase the \r line ending how the console knows to replace the line
		// instead of simply printing a new one
		// This MUST be done AFTER the above lines, or else it WILL NOT WORK
		intermediate = intermediate.stringByReplacingOccurrencesOfString("\r", withString: "\r\n")
		
		// Splits the string on the \n string
		return intermediate.componentsSeparatedByString("\n")
	}
	
	/// The regex of the ansi things to remove from the log
	private var clearAnsiRegex: NSRegularExpression? = {
		do {
			return try NSRegularExpression(pattern: "(?:\u{001B})(?:\\[0?c|\\[[0356]n|\\[7[lh]|\\[\\?25[lh]|\\(B|H|\\[(?:\\d+(;\\d+)\\{,2\\})?G|\\[(?:[12])?[JK]|[DM]|\\[0K)", options: [])
		} catch {
			Logger.error(error)
			return nil
		}
	}()
	
	/// Strips unused characters from the given string
	private func strip(str: String) -> String {
		// Replace all unused ANSI chars
		return clearAnsiRegex!.stringByReplacingMatchesInString(str, options: [], range: NSMakeRange(0, str.length), withTemplate: "")
	}
	
	struct Line {
		let segments: [ANSIParse.ANSISegment]
		
		let groupName: String
		let isGroupStart: Bool
		private(set) var isGroupEnd: Bool
		
		private(set) var time: Int?
	}
}
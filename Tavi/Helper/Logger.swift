//
//  Logger.swift
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
//#if
import UIKit

/// A (decently) simple logging system
public class Logger
{
	/// The longest caller info section we have yet seen
	/// used to try to equalize the log positions
	//TODO:Document
	private static var longestFunctionNameSoFar = 0
	private static var longestFileNameSoFar = 0
	private static var longestLineNumberSoFar = 0
	
	/// The minimum level required for a message to be displayed
	private static var minLogLevel: LogLevel?
	/// The indentation prefix
	private static var indentPrefix = ""
	
	/// Increases the indent by two spaces
	public static func indent() {
		indentPrefix += "  "
	}
	
	/// If the current indent is greater than two spaces, decrease the index by two spaces
	/// Otherwise, set the indent to an empty string
	public static func outdent() {
		if indentPrefix.characters.count >= 2 {
			indentPrefix = indentPrefix.substringToIndex(indentPrefix.endIndex.advancedBy(-2))
		} else {
			indentPrefix = ""
		}
	}
	
	/// Sets the minimum log level
	///
	/// - Parameter level: The new minimum log level
	public static func setLogLevel(level: LogLevel) {
		minLogLevel = level
	}
	
	
	/// Whether or not to include the function signature in the log
	public static var useFunctionName = false
	/// Whether or not to include the file name in the log
	public static var useFileName = true
	/// Whether or not to include the line number in the log - does nothing if `useFileName` is `false`
	public static var useLineNumber = true
	
	//TODO: Add more settings here
	
	public static var xcodeColorsEnabled: Bool = {
		let colors = NSProcessInfo.processInfo().environment["XcodeColors"]
		return colors == "YES"
	}()
	
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - vals: The values to log
	public static func log<T>(level: LogLevel, vals: T..., functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(level, seperator: " ", arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - vals: The values to log
	public static func log<T>(level: LogLevel, vals: T?..., functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(level, seperator: " ", arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - seperator: The string to insert between the vals
	///   - vals: The values to log
	public static func log<T>(level: LogLevel, seperator: String, vals: T..., functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(level, seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - seperator: The string to insert between the vals
	///   - vals: The values to log
	public static func log<T>(level: LogLevel, seperator: String, vals: T?..., functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(level, seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - seperator: The string to insert between the vals
	///   - vals: The values to log
	private static func log<T>(level: LogLevel, seperator: String, arr: [T?], functionName: String, filePath: String, lineNumber: Int) {
		var out = [String]()
		for v in arr {
			if v == nil {
				out.append("nil")
			} else {
				out.append("Optional(\(v!))")
			}
		}
		log(level, seperator: seperator, arr: out, functionName: functionName, filePath: filePath, lineNumber: lineNumber)
	}
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - seperator: The string to insert between the vals
	///   - vals: The values to log
	private static func log<T>(level: LogLevel, seperator: String, arr: [T], functionName: String, filePath: String, lineNumber: Int) {
		if minLogLevel == nil {
			minLogLevel = LogLevel.Info
		}
		guard level.index >= minLogLevel!.index else { return }
		
		var callerInfo = ""
		if useFunctionName {
			var funcName = functionName+" "
			if funcName.length > longestFunctionNameSoFar {
				longestFunctionNameSoFar = funcName.length
			} else {
				funcName.ensureAtLeast(longestFunctionNameSoFar)
			}
			
			callerInfo += funcName
		}
		if useFileName {
			var fileName = "("+(filePath as NSString).lastPathComponent
			if fileName.length > longestFileNameSoFar {
				longestFileNameSoFar = fileName.length
			} else {
				fileName.ensureAtLeast(longestFileNameSoFar, prepend: true)
			}
			
			callerInfo += fileName
			
			if useLineNumber {
				var lineNum = "\(lineNumber)) "
				if lineNum.length > longestLineNumberSoFar {
					longestLineNumberSoFar = lineNum.length
				} else {
					lineNum.ensureAtLeast(longestLineNumberSoFar)
				}
				
				callerInfo += ":\(lineNum)"
			} else {
				callerInfo += ") "
			}
		}
		let prefix = "\(level.prefix)\(indentPrefix)"
		
		if xcodeColorsEnabled {
//			s = "\(level.color.format())\(s)\(XcodeColor.reset)"
//			prefix = "\(level.color.format())\(level.prefix)\(XcodeColor.reset)\(indentPrefix)"
		}
		
		
		var s = ""
		for v in arr {
			let stringified = "\(v)"
			s += (s == "" ? "" : seperator)+stringified
		}
		s = s.stringByReplacingOccurrencesOfString("\r\n", withString: "\n")
		s = s.stringByReplacingOccurrencesOfString("\r", withString: "\\r\n")
		s = s.stringByReplacingOccurrencesOfString("\n", withString: "\n\(callerInfo)\(prefix)")
		
		print("\(callerInfo)\(prefix)\(s)")
	}
	
	/// Logs a message at the plain level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func plain<T>(vals: T...,  seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { plain(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	/// Logs a message at the plain level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func plain<T>(vals: T?..., seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { plain(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func plain<T>(seperator seperator: String, arr: [T],  functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Plain, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func plain<T>(seperator seperator: String, arr: [T?], functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Plain, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the debug level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func debug<T>(vals: T...,  seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { debug(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	/// Logs a message at the debug level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func debug<T>(vals: T?..., seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { debug(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func debug<T>(seperator seperator: String, arr: [T],  functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Debug, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func debug<T>(seperator seperator: String, arr: [T?], functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Debug, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the trace level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func trace<T>(vals: T...,  seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { trace(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	/// Logs a message at the trace	level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func trace<T>(vals: T?..., seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { trace(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func trace<T>(seperator seperator: String, arr: [T],  functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Trace, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func trace<T>(seperator seperator: String, arr: [T?], functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Trace, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the info level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func info<T>(vals: T...,  seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { info(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	/// Logs a message at the info level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func info<T>(vals: T?..., seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { info(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func info<T>(seperator seperator: String, arr: [T],  functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Info, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func info<T>(seperator seperator: String, arr: [T?], functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Info, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the warn level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func warn<T>(vals: T...,  seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { warn(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	/// Logs a message at the warn level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func warn<T>(vals: T?..., seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { warn(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func warn<T>(seperator seperator: String, arr: [T],  functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Warn, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func warn<T>(seperator seperator: String, arr: [T?], functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Warn, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	/// Logs a message at the error level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func error<T>(vals: T...,  seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { error(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	/// Logs a message at the error level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	public static func error<T>(vals: T?..., seperator: String = " ", functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { error(seperator: seperator, arr: vals, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func error<T>(seperator seperator: String, arr: [T],  functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Error, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	private static func error<T>(seperator seperator: String, arr: [T?], functionName: String = #function, filePath: String = #file, lineNumber: Int = #line) { log(.Error, seperator: seperator, arr: arr, functionName: functionName, filePath: filePath, lineNumber: lineNumber) }
	
	//TODO: Get colors working. Maybe use https://github.com/robbiehanson/XcodeColors ? (Wow that link looks crap on this background)
	/// The level to log at
	public struct LogLevel
	{
		/// The Debug level
		///
		/// This is the lowest level, used primarily for internal testing and, well, debugging
		public static let Debug = LogLevel(index: 0, prefix: "DEBUG: ", color: "")
		
		/// The Plain level
		///
		/// This is the 2nd lowest level, used for displaying plain-text messages with no prefix
		public static let Plain = LogLevel(index: 1, prefix: "", color: "")
		
		/// The Trace level
		///
		/// This is the 3rd level, used for verbose logging, such as incoming HTTP messages and loop outputs
		public static let Trace = LogLevel(index: 2, prefix: "TRACE: ", color: "")
		
		/// The Info level
		///
		/// This is the 4th level, and is used for general information logging
		public static let Info = LogLevel(index: 3, prefix: " INFO: ", color: "")
		
		/// The Warn level
		///
		/// This is the 2nd highest level, used for items that could cause strange behaviour, but are not app-breaking
		public static let Warn = LogLevel(index: 4, prefix: " WARN: ", color: "")
		
		/// The Error level
		///
		/// This is the highest level. These messages will always be displayed, and thus
		/// are used for errors that must be addressed ASAP
		public static let Error = LogLevel(index: 5, prefix: "ERROR: ", color: "")
		
		
		/// The prefix for this log level
		private let prefix: String
		/// The color to print (this isn't working yet)
		private let color: String
		private let index: Int
		private init(index: Int, prefix: String, color: String) {
			self.prefix = prefix
			self.color = color
			self.index = index
		}
	}
}
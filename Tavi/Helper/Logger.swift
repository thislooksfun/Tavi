//
//  Logger.swift
//  Tavi
//
//  Created by thislooksfun on 7/15/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

/// A (decently) simple logging system
class Logger
{
	/// tThe minimum level required for a message to be displayed
	private static var minLogLevel: LogLevel?
	/// The indentation prefix
	private static var indentPrefix = ""
	
	/// Increases the indent by two spaces
	static func indent() {
		indentPrefix += "  "
	}
	
	/// If the current indent is greater than two spaces, decrease the index by two spaces
	/// Otherwise, set the indent to an empty string
	static func outdent() {
		if indentPrefix.characters.count >= 2 {
			indentPrefix = indentPrefix.substringToIndex(indentPrefix.endIndex.advancedBy(-2))
		} else {
			indentPrefix = ""
		}
	}
	
	/// Sets the minimum log level
	///
	/// - Parameter level: The new minimum log level
	static func setLogLevel(level: LogLevel) {
		minLogLevel = level
	}
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - vals: The values to log
	static func log<T>(level: LogLevel, vals: T...) { log(level, seperator: " ", arr: vals) }
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - seperator: The string to insert between the vals
	///   - vals: The values to log
	static func log<T>(level: LogLevel, seperator: String, vals: T...) { log(level, seperator: seperator, arr: vals) }
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - seperator: The string to insert between the vals
	///   - vals: The values to log
	private static func log<T>(level: LogLevel, seperator: String, arr: [T?]) {
		var out = [String]()
		for v in arr {
			if v == nil {
				out.append("nil")
			} else {
				out.append("Optional(\(v!))")
			}
		}
		log(level, seperator: seperator, arr: out)
	}
	
	/// Logs a message at the specified level
	///
	/// - Parameters:
	///   - level: The level to log at
	///   - seperator: The string to insert between the vals
	///   - vals: The values to log
	private static func log<T>(level: LogLevel, seperator: String, arr: [T]) {
		if minLogLevel == nil {
			minLogLevel = LogLevel.Info
		}
		guard level.index >= minLogLevel!.index else { return }
		
		var s = ""
		for v in arr {
			let stringified = "\(v)"
			s += (s == "" ? "" : seperator)+stringified
		}
		s = s.stringByReplacingOccurrencesOfString("\n", withString: "\n\(level.prefix)\(indentPrefix)")
		print("\(level.prefix)\(indentPrefix)\(s)")
	}
	
	/// Logs a message at the plain level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func plain<T>(vals: T...,  seperator: String = " ") { plain(seperator: seperator, arr: vals) }
	/// Logs a message at the plain level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func plain<T>(vals: T?..., seperator: String = " ") { plain(seperator: seperator, arr: vals) }
	private static func plain<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Plain, seperator: seperator, arr: arr) }
	private static func plain<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Plain, seperator: seperator, arr: arr) }
	
	/// Logs a message at the debug level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func debug<T>(vals: T...,  seperator: String = " ") { debug(seperator: seperator, arr: vals) }
	/// Logs a message at the debug level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func debug<T>(vals: T?..., seperator: String = " ") { debug(seperator: seperator, arr: vals) }
	private static func debug<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Debug, seperator: seperator, arr: arr) }
	private static func debug<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Debug, seperator: seperator, arr: arr) }
	
	/// Logs a message at the trace level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func trace<T>(vals: T...,  seperator: String = " ") { trace(seperator: seperator, arr: vals) }
	/// Logs a message at the trace	level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func trace<T>(vals: T?..., seperator: String = " ") { trace(seperator: seperator, arr: vals) }
	private static func trace<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Trace, seperator: seperator, arr: arr) }
	private static func trace<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Trace, seperator: seperator, arr: arr) }
	
	/// Logs a message at the info level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func info<T>(vals: T...,  seperator: String = " ") { info(seperator: seperator, arr: vals) }
	/// Logs a message at the info level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func info<T>(vals: T?..., seperator: String = " ") { info(seperator: seperator, arr: vals) }
	private static func info<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Info, seperator: seperator, arr: arr) }
	private static func info<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Info, seperator: seperator, arr: arr) }
	
	/// Logs a message at the warn level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func warn<T>(vals: T...,  seperator: String = " ") { warn(seperator: seperator, arr: vals) }
	/// Logs a message at the warn level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func warn<T>(vals: T?..., seperator: String = " ") { warn(seperator: seperator, arr: vals) }
	private static func warn<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Warn, seperator: seperator, arr: arr) }
	private static func warn<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Warn, seperator: seperator, arr: arr) }
	
	/// Logs a message at the error level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func error<T>(vals: T...,  seperator: String = " ") { error(seperator: seperator, arr: vals) }
	/// Logs a message at the error level
	///
	/// - Parameters:
	///   - vals: The values to log
	///   - seperator: The seperator to use (Default: `" "`)
	static func error<T>(vals: T?..., seperator: String = " ") { error(seperator: seperator, arr: vals) }
	private static func error<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Error, seperator: seperator, arr: arr) }
	private static func error<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Error, seperator: seperator, arr: arr) }
	
	//TODO: Get colors working. Maybe use https://github.com/robbiehanson/XcodeColors ? (Wow that link looks crap on this background)
	/// The level to log at
	struct LogLevel
	{
		/// The Debug level
		///
		/// This is the lowest level, used primarily for internal testing and, well, debugging
		static let Debug = LogLevel(index: 0, prefix: "DEBUG: ", color: UIColor.whiteColor())
		
		/// The Plain level
		///
		/// This is the 2nd lowest level, used for displaying plain-text messages with no prefix
		static let Plain = LogLevel(index: 1, prefix: "",        color: UIColor.whiteColor())
		
		/// The Trace level
		///
		/// This is the 3rd level, used for verbose logging, such as incoming HTTP messages and loop outputs
		static let Trace = LogLevel(index: 2, prefix: "TRACE: ", color: UIColor.whiteColor())
		
		/// The Info level
		///
		/// This is the 4th level, and is used for general information logging
		static let Info =  LogLevel(index: 3, prefix: " INFO: ", color: UIColor.whiteColor())
		
		/// The Warn level
		///
		/// This is the 2nd highest level, used for items that could cause strange behaviour, but are not app-breaking
		static let Warn =  LogLevel(index: 4, prefix: " WARN: ", color: UIColor.yellowColor())
		
		/// The Error level
		///
		/// This is the highest level. These messages will always be displayed, and thus
		/// are used for errors that must be addressed ASAP
		static let Error = LogLevel(index: 5, prefix: "ERROR: ", color: UIColor.redColor())
		
		
		/// The prefix for this log level
		let prefix: String
		/// The color to print (this isn't working yet)
		let color: UIColor
		let index: Int
		private init(index: Int, prefix: String, color: UIColor) {
			self.prefix = prefix
			self.color = color
			self.index = index
		}
	}
}
//
//  Logger.swift
//  Tavi
//
//  Created by thislooksfun on 7/15/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class Logger
{
	private static var minLogLevel: LogLevel?
	private static var indentPrefix = ""
	
	static func indent() {
		indentPrefix += "  "
	}
	static func outdent() {
		if indentPrefix.characters.count >= 2 {
			indentPrefix = indentPrefix.substringToIndex(indentPrefix.endIndex.advancedBy(-2))
		} else {
			indentPrefix = ""
		}
	}
	
	static func setLogLevel(level: LogLevel) {
		minLogLevel = level
	}
	
	// Logs a message at the specified level
	static func log<T>(level: LogLevel, vals: T...) { log(level, seperator: " ", arr: vals) }
	static func log<T>(level: LogLevel, seperator: String, vals: T...) { log(level, seperator: seperator, arr: vals) }
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
	
	// Logs a message at the plain level
	static func plain<T>(vals: T...,  seperator: String = " ") { plain(seperator: seperator, arr: vals) }
	static func plain<T>(vals: T?..., seperator: String = " ") { plain(seperator: seperator, arr: vals) }
	private static func plain<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Plain, seperator: seperator, arr: arr) }
	private static func plain<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Plain, seperator: seperator, arr: arr) }
	
	// Logs a message at the debug level
	static func debug<T>(vals: T...,  seperator: String = " ") { debug(seperator: seperator, arr: vals) }
	static func debug<T>(vals: T?..., seperator: String = " ") { debug(seperator: seperator, arr: vals) }
	private static func debug<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Debug, seperator: seperator, arr: arr) }
	private static func debug<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Debug, seperator: seperator, arr: arr) }
	
	// Logs a message at the trace level
	static func trace<T>(vals: T...,  seperator: String = " ") { trace(seperator: seperator, arr: vals) }
	static func trace<T>(vals: T?..., seperator: String = " ") { trace(seperator: seperator, arr: vals) }
	private static func trace<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Trace, seperator: seperator, arr: arr) }
	private static func trace<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Trace, seperator: seperator, arr: arr) }
	
	// Logs a message at the info level
	static func info<T>(vals: T...,  seperator: String = " ") { info(seperator: seperator, arr: vals) }
	static func info<T>(vals: T?..., seperator: String = " ") { info(seperator: seperator, arr: vals) }
	private static func info<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Info, seperator: seperator, arr: arr) }
	private static func info<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Info, seperator: seperator, arr: arr) }
	
	// Logs a message at the warn level
	static func warn<T>(vals: T...,  seperator: String = " ") { warn(seperator: seperator, arr: vals) }
	static func warn<T>(vals: T?..., seperator: String = " ") { warn(seperator: seperator, arr: vals) }
	private static func warn<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Warn, seperator: seperator, arr: arr) }
	private static func warn<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Warn, seperator: seperator, arr: arr) }
	
	// Logs a message at the error level
	static func error<T>(vals: T...,  seperator: String = " ") { error(seperator: seperator, arr: vals) }
	static func error<T>(vals: T?..., seperator: String = " ") { error(seperator: seperator, arr: vals) }
	private static func error<T>(seperator seperator: String, arr: [T])  { log(LogLevel.Error, seperator: seperator, arr: arr) }
	private static func error<T>(seperator seperator: String, arr: [T?]) { log(LogLevel.Error, seperator: seperator, arr: arr) }
	
	struct LogLevel {
		static let Debug = LogLevel(index: 0, prefix: "DEBUG: ", color: UIColor.whiteColor())
		static let Plain = LogLevel(index: 1, prefix: "",        color: UIColor.redColor())
		static let Trace = LogLevel(index: 2, prefix: "TRACE: ", color: UIColor.whiteColor())
		static let Info =  LogLevel(index: 3, prefix: " INFO: ", color: UIColor.whiteColor())
		static let Warn =  LogLevel(index: 4, prefix: " WARN: ", color: UIColor.yellowColor())
		static let Error = LogLevel(index: 5, prefix: "ERROR: ", color: UIColor.redColor())
		
		let prefix: String
		let color: UIColor
		let index: Int
		private init(index: Int, prefix: String, color: UIColor) {
			self.prefix = prefix
			self.color = color
			self.index = index
		}
	}
}
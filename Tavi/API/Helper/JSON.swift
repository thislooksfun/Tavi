//
//  JSON.swift
//  Tavi
//
//  Created by thislooksfun on 7/6/15.
//  Copyright (c) 2015 thislooksfun. All rights reserved.
//

import UIKit

class JSON: CustomStringConvertible
{
	private var dict: NSDictionary!
	private var string: String!
	
	init?(obj: AnyObject?) {
		guard obj != nil else { return nil }
		
		if obj is NSDictionary {
			self.dict = obj! as! NSDictionary
//		} else if obj is NSArray {
//			
		} else if obj is String {
			if let data = (obj as! String).dataUsingEncoding(NSUTF8StringEncoding) {
				do {
					self.dict = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
				} catch let error as NSError {
					Logger.warn(error)
				}
			}
			guard self.dict != nil else { return nil }
		} else {
			Logger.warn("Unknown for object: '\(obj!)'")
			return nil
		}
	}
	
	init(data: NSData) throws {
		self.string = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
		
		let error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
		let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? NSDictionary
		guard json != nil else {
			throw error
		}
		self.dict = json!
	}
	
	init?(dict: NSDictionary?) {
		guard dict != nil else { return nil }
		self.dict = dict!
	}
	
	// Returns a string version of this JSON object
	var description: String {
		get {
			do {
				return NSString(data: try NSJSONSerialization.dataWithJSONObject(self.dict, options: NSJSONWritingOptions.PrettyPrinted), encoding: NSUTF8StringEncoding)! as String
			} catch _ {
				return ""
			}
		}
	}
	
	// Gets the specified key, or nil if it doesn't exist
	func getKey(key: String) -> AnyObject? {
		return dict[key]
	}
	
	// Gets the specified key as a String, or nil if it can't be cast or doesn't exist
	func getString(key: String) -> String? {
		let k = getKey(key) as? NSString
		return k as? String
	}
	
	// Gets the specified key as an Int, or nil if it can't be cast or doesn't exist
	func getInt(key: String) -> Int? {
		return getKey(key) as? Int
	}
	
	// Gets the specified key as an array, or nil if it can't be cast or doesn't exist
	func getArray(key: String) -> [AnyObject]? {
		return getKey(key) as? [AnyObject]
	}
	
	// Gets the specified key as new JSON object, or nil if it can't be cast or doesn't exist
	func getJson(key: String) -> JSON? {
		return JSON(dict: getKey(key) as? NSDictionary)
	}
	
	// Gets the specified key as an array of new JSON objects, or nil if it can't be cast or doesn't exist
	func getJsonArray(key: String) -> [JSON]? {
		guard dict[key] is [NSDictionary] else { return nil }
		
		var out = [JSON]()
		for obj in dict[key] as! [NSDictionary] {
			let nextJson = JSON(dict: obj)
			guard nextJson != nil else { return nil }
			out.append(nextJson!)
		}
		
		return out
	}
}
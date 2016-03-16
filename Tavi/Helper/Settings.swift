//
//  Settings.swift
//  Tavi
//
//  Created by thislooksfun on 7/9/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class Settings
{
	private static let defaults = NSUserDefaults.standardUserDefaults()
	
	static let Tavi_Orange_Color = UIColor(red: 255/255, green: 109/255, blue:  0/255, alpha: 1)
	static let Tavi_Yellow_Color = UIColor(red: 255/255, green: 195/255, blue: 59/255, alpha: 1)
	
	static let GitHub_Token = SettingsItem<String>(key: "GithubToken")
	static let GitHub_User = SettingsItem<String>(key: "GithubUser")
	static let Travis_Token = SettingsItem<String>(key: "TravisToken")
	static let HasReadDisclaimer = SettingsItem<Bool>(key: "DisclaimerRead")
	static let Favorites = SettingsItem<[String]>(key: "Favorites")
	static let InAppNotificationTypes = SettingsItem<Int>(key: "NotificationTypes")
	
//	static var displayInAppNotifications: InAppNoteType = .All
	static var checkForBuildsInBackground = true
	
	static func save() {
		defaults.synchronize()
		
	}
	
	struct InAppNoteType: OptionSetType {
		let rawValue: Int
		
		init(rawValue: Int) { self.rawValue = rawValue }
		
		static let Start =  InAppNoteType(rawValue: 1 << 0)
		static let Pass =   InAppNoteType(rawValue: 1 << 1)
		static let Fail =   InAppNoteType(rawValue: 1 << 2)
		static let Cancel = InAppNoteType(rawValue: 1 << 3)
		
		static let None: InAppNoteType = []
		static let All: InAppNoteType = [Start, Pass, Fail, Cancel]
		
		static func fromPos(pos: Int) -> InAppNoteType
		{
			switch pos {
			case 0:  return Start
			case 1:  return Pass
			case 2:  return Fail
			case 3:  return Cancel
			default: return None
			}
		}
	}
}

class SettingsItem<T>: CustomStringConvertible
{
	private var doOnSet: (() -> Void)?
	private let key: String
	
	private init(key: String) {
		self.key = key
	}
	
	func onSet(fnc: (() -> Void)?) {
		self.doOnSet = fnc
	}
	
	func get() -> T? {
		return Settings.defaults.valueForKey(self.key) as? T
	}
	
	func getWithDefault(deflt: T) -> T {
		var out = self.get()
		if out == nil {
			Logger.trace("Setting default")
			self.set(deflt)
			out = deflt
		}
		return out!
	}
	
	func set(obj: T?) {
		Logger.trace("Setting key \(key) to \(obj)")
		Settings.defaults.setValue(obj as? AnyObject, forKey: self.key)
		self.doOnSet?()
	}
	
	var description: String {
		get {
			return "\(self.key) : \(self.get())"
		}
	}
}
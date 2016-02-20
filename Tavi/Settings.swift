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
	static let FilterState = SettingsItem<Int>(key: "Filter")
	
	static var displayInAppNotifications: InAppNoteType = .All
	static var checkForBuildsInBackground = true
	
	static func save() {
		defaults.synchronize()
	}
	
	enum InAppNoteType {
		case All
		case Pass
		case Fail
		case None
	}
	
	enum Filter: Int, CustomStringConvertible {
		case Active
		case Favorites
		case Both
		
		static func fromInt(int: Int?) -> Filter {
			guard int != nil else { return .Active }
			return Filter(rawValue: int!) ?? .Active
		}
		
		var description: String {
			get {
				switch self {
				case .Active: return "Active"
				case .Favorites: return "Favorites"
				case .Both: return "Active + Favorites"
				}
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
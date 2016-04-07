//
//  Settings.swift
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

import UIKit

/// A way to interact cleanly with NSUserDefaults
class Settings
{
	/// The standard user defaults
	private static let defaults = NSUserDefaults.standardUserDefaults()
	
	/// The RGB orange color from the Tavi icon
	static let Tavi_Orange_Color = UIColor(red: 255/255, green: 109/255, blue:  0/255, alpha: 1)
	
	/// The RGB yellow color from the Tavi icon
	static let Tavi_Yellow_Color = UIColor(red: 255/255, green: 195/255, blue: 59/255, alpha: 1)
	
	/// The Github auth token
	static let GitHub_Token = SettingsItem<String>(key: "GithubToken")
	
	/// The Github username
	static let GitHub_User = SettingsItem<String>(key: "GithubUser")
	
	/// The Travis CI auth token
	static let Travis_Token = SettingsItem<String>(key: "TravisToken")
	
	/// Whether or not the use has read the disclaimer
	static let HasReadDisclaimer = SettingsItem<Bool>(key: "DisclaimerRead")
	
	/// The array of favorites
	static let Favorites = SettingsItem<[String]>(key: "Favorites")
	
	/// The mask of allowed notifications
	static let NotificationTypes = SettingsItem<Int>(key: "NotificationTypes")
	
	/// Whether or not to check for builds in the background
	///
	/// - TODO: Make this a	`SettingsItem` and add to the menu
	static var checkForBuildsInBackground = true
	
	/// Saves all the settings
	static func save() {
		defaults.synchronize()
	}
	
	///
	struct NoteType: OptionSetType {
		let rawValue: Int
		
		init(rawValue: Int) { self.rawValue = rawValue }
		
		/// A notification sent when a build was started (not created)
		static let Start = NoteType(rawValue: 1 << 0)
		
		/// A notification sent when a build passed
		static let Pass = NoteType(rawValue: 1 << 1)
		
		/// A notification sent when a build failed
		static let Fail = NoteType(rawValue: 1 << 2)
		
		/// A notification sent when a build was cancelled
		static let Cancel = NoteType(rawValue: 1 << 3)
		
		/// No notifications should be sent
		static let None: NoteType = []
		
		/// Allow all notifications (default)
		static let All: NoteType = [Start, Pass, Fail, Cancel]
		
		/// Get a `NoteType` from its position
		/// 
		/// The return values are as follows: \
		/// 0: `.Start` \
		/// 1: `.Pass` \
		/// 2: `.Fail` \
		/// 3: `.Cancel` \
		///
		/// If `pos < 0` or `pos > 3`, it will return `.None`
		///
		/// - Parameter pos: The position, in the interval [0,3]
		///
		/// - Returns: `.Start`, `.Pass`, `.Fail`, or `.Cancel` if `pos` is valid, otherwise `.None`
		static func fromPos(pos: Int) -> NoteType
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

/// A helper class used for interacting with `NSUserDefaults`
class SettingsItem<T>: CustomStringConvertible
{
	/// A closure to execute upon `.set()` being called
	private var doOnSet: (() -> Void)?
	
	/// The key to access in `NSUserDefaults`
	private let key: String
	
	/// Creates an instance
	///
	/// - Parameter key: The key to use
	private init(key: String) {
		self.key = key
	}
	
	/// Sets the closure to execute upon `.set()` being called
	///
	/// If `nil` is passed, it clears the closure
	///
	/// - Parameter fnc: The new closure to use (can be `nil`)
	func onSet(fnc: (() -> Void)?) {
		self.doOnSet = fnc
	}
	
	/// Gets the value stored in `NSUserDefaults`
	///
	/// - Returns: The stored value, or `nil` if it doesn't exist or isn't of type `T`
	func get() -> T? {
		return Settings.defaults.valueForKey(self.key) as? T
	}
	
	/// Gets the value stored in `NSUserDefaults`, and sets a default if no value exists
	///
	/// - SeeAlso: `.get()`
	///
	/// - Parameter deflt: The default value to use if `.get()` returns `nil`
	///
	/// - Returns: The stored value, or `deflt` if it doesn't exist or isn't of type `T`
	func getWithDefault(deflt: T) -> T {
		var out = self.get()
		if out == nil {
			Logger.trace("Setting default")
			self.set(deflt)
			out = deflt
		}
		return out!
	}
	
	/// Sets the stored object to the given value
	///
	/// Pass `nil` to clear
	///
	/// - Parameter obj: The object to store (can be `nil`)
	func set(obj: T?) {
		Logger.trace("Setting key \(key) to \(obj)")
		Settings.defaults.setValue(obj as? AnyObject, forKey: self.key)
		self.doOnSet?()
	}
	
	/// A string description of this object. Used in places like `print()` and in string interpolation (`"\(asdf)"`)
	var description: String {
		get {
			return "\(self.key) : \(self.get())"
		}
	}
}
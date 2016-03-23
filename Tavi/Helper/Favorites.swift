//
//  Favorites.swift
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

/// Manage favorite repos
class Favorites
{
	/// Called when the app is launched
	static func appStarted() {
		Settings.Favorites.onSet(favoritesSet)
		favoritesSet()
	}
	
	/// Gets the current favorites
	///
	/// - Returns: A String array (`[String]`) of all the slugs of the favorited repos
	static func getFavorites() -> [String] {
		return Settings.Favorites.getWithDefault([])
	}
	
	/// Called when `Settings.Favorites` is changed
	static func favoritesSet() {
		if let favorites = Settings.Favorites.get() {
			var favoriteShortcuts = [UIApplicationShortcutItem]()
			for slug in favorites {
				favoriteShortcuts.append(UIApplicationShortcutItem(type: "\(NSBundle.mainBundle().bundleIdentifier!).openFavorite", localizedTitle: slug, localizedSubtitle: "", icon: UIApplicationShortcutIcon(templateImageName: "icon-heart-outline"), userInfo: nil))
			}
			UIApplication.sharedApplication().shortcutItems = favoriteShortcuts
		}
	}
	
	/// Toggles the favorited state of the given repo
	///
	/// - Parameters:
	///   - slug: The slug of the repo to toggle
	///   - atIndex: the index to insert the favorite, if it doesn't already exist
	static func toggleFavorite(slug: String, atIndex: Int? = nil) {
		if var favorites = Settings.Favorites.get() {
			let index = favorites.indexOf(slug)
			
			if index != nil {
				favorites.removeAtIndex(favorites.startIndex.distanceTo(index!))
			} else {
				if atIndex == nil {
					favorites.append(slug)
				} else {
					favorites.insert(slug, atIndex: atIndex!)
				}
			}
			Settings.Favorites.set(favorites)
		} else {
			Settings.Favorites.set([slug])
		}
	}
	
	/// Checks whether or not a repo is favorited
	///
	/// - Parameter slug: The slug to check
	///
	/// - Returns: `true` if the repo is favorited, otherwise `false`
	static func isFavorite(slug: String) -> Bool {
		return Settings.Favorites.get()?.contains(slug) ?? false
	}
}
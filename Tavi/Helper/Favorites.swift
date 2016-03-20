//
//  Favorites.swift
//  Tavi
//
//  Created by thislooksfun on 2/10/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
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
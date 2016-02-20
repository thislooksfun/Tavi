//
//  Favorites.swift
//  Tavi
//
//  Created by thislooksfun on 2/10/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class Favorites
{
	static func appStarted() {
		Settings.Favorites.onSet(favoritesSet)
		favoritesSet()
	}
	
	static func favoritesSet() {
		if let favorites = Settings.Favorites.get() {
			var favoriteShortcuts = [UIApplicationShortcutItem]()
			for slug in favorites {
				favoriteShortcuts.append(UIApplicationShortcutItem(type: "\(NSBundle.mainBundle().bundleIdentifier!).openFavorite", localizedTitle: slug, localizedSubtitle: "", icon: UIApplicationShortcutIcon(templateImageName: "icon-heart-outline"), userInfo: nil))
			}
			UIApplication.sharedApplication().shortcutItems = favoriteShortcuts
		}
	}
	
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
	
	static func isFavorite(slug: String) -> Bool {
		return Settings.Favorites.get()?.contains(slug) ?? false
	}
}
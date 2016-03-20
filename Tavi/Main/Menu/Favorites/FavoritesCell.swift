//
//  FavoritesCell.swift
//  Tavi
//
//  Created by thislooksfun on 2/11/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

/// A cell in the favorites table
class FavoritesCell: UITableViewCell
{
	/// The slug for this favorited repo
	@IBOutlet var repoSlug: UILabel!
	/// The heart icon image
	@IBOutlet var heartIcon: UIImageView!
	/// The button to toggle the favorited status
	@IBOutlet var favToggleButton: UIButton!
	
	/// Loads the view
	///
	/// - Parameter slug: The slug to load from
	func load(slug: String) {
		self.repoSlug.text = slug
		self.heartIcon.highlighted = Favorites.isFavorite(slug)
	}
}
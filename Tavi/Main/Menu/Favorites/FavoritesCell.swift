//
//  FavoritesCell.swift
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
//
//  FavoritesCell.swift
//  Tavi
//
//  Created by thislooksfun on 2/11/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class FavoritesCell: UITableViewCell
{
	@IBOutlet var repoSlug: UILabel!
	@IBOutlet var heartIcon: UIImageView!
	@IBOutlet var favToggleButton: UIButton!
	
	func load(slug: String) {
		self.repoSlug.text = slug
		self.heartIcon.highlighted = Favorites.isFavorite(slug)
	}
}
//
//  Router.swift
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
import JLRoutes

/// A simple class used to interact with `JLRoutes`
class Router
{
	/// Adds the routes the app can handle
	static func initHandlers()
	{
		JLRoutes.addRoute("id/:id") {
			(params) -> Bool in
			
			Logger.trace("Attempting to open repo from ID")
			
//			guard TravisAPI.authed() else { return false }
			
			let repoView = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RepoView") as! DetailViewController
			guard let controller = UIViewController.rootViewController() as? UINavigationController else { return false }
			
			repoView.id = params["id"] as? Int
			
			Logger.trace("ID to open: \(repoView.id)")
			
			controller.popToRootViewControllerAnimated(true)
			controller.pushViewController(repoView, animated: true)
			
			return true
		}
		
		JLRoutes.addRoute("slug/:user/:repo") {
			(params) -> Bool in
			
			Logger.trace("Attempting to open repo from slug")
			
//			guard TravisAPI.authed() else { return false }
			
			let repoView = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RepoView") as! DetailViewController
			guard let controller = UIViewController.rootViewController() as? UINavigationController else { return false }
			
			repoView.slug = "\(params["user"] as! String)/\(params["repo"] as! String)"
			
			Logger.trace("Slug to open: \(repoView.slug)")
			
			controller.popToRootViewControllerAnimated(true)
			controller.pushViewController(repoView, animated: true)
			
			return true
		}
	}
}
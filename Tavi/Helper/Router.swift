//
//  Router.swift
//  Tavi
//
//  Created by thislooksfun on 2/12/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class Router {
	static func initHandlers() {
		JLRoutes.addRoute("id/:id") {
			(params) -> Bool in
			
			Logger.trace("Attempting to open repo from ID")
			
			guard TravisAPI.authed() else { return false }
			
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
			
			guard TravisAPI.authed() else { return false }
			
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
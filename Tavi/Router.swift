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
		JLRoutes.addRoute("repo/:id") {
			(params) -> Bool in
			
			Logger.warn("Trying to use unsupported path '/repo/:id'")
			//TODO: Support this?
			
			return false
		}
		
		JLRoutes.addRoute("repo/:user/:repo") {
			(params) -> Bool in
			
			guard TravisAPI.authed() else { return false }
			
			let repoView = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RepoView") as! DetailViewController
			guard let controller = UIViewController.rootViewController() as? UINavigationController else { return false }
			
			repoView.slug = "\(params["user"] as! String)/\(params["repo"] as! String)"
			
			controller.popToRootViewControllerAnimated(true)
			controller.pushViewController(repoView, animated: true)
			
			return true
		}
	}
}
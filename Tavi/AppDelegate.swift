//
//  AppDelegate.swift
//  Tavi
//
//  Created by thislooksfun on 12/2/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		Logger.setLogLevel(.Trace)
		
		Logger.info("App started")
		
		application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil))
		application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
		
		GBVersionTracking.track()
		
		Favorites.appStarted()
		
		Router.initHandlers()
		
		
		//Various debug testing things
		
//		Logger.setLogLevel(.Debug)
//		GithubAPI.signOut()
//		TravisAPI.deAuth()
//		Settings.HasReadDisclaimer.set(nil)
		
		Logger.plain("1")
		Logger.debug("2")
		Logger.trace("3")
		Logger.info("4")
		Logger.warn("5")
		Logger.error("6")
		
		return true
	}
	
	func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
		Logger.debug("supportedInterfaceOrientationsForWindow")
		if let root = window?.rootViewController where !(window!.rootViewController! is UIAlertController) {
			return root.supportedInterfaceOrientations()
		} else {
			return UIInterfaceOrientationMask.Portrait
		}
	}
	
	func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
		let item = shortcutItem.type.substringFromIndex(shortcutItem.type.startIndex.advancedBy(NSBundle.mainBundle().bundleIdentifier!.characters.count+1))
		
		switch item {
		case "openFavorite": JLRoutes.routeURL(NSURL(string: "tavi://slug/\(shortcutItem.localizedTitle)"))
		default: Logger.warn("Tried to trigger a shortcut with an unknown type \(shortcutItem.type)")
		}
		
		completionHandler(false)
	}
	
	func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
		return JLRoutes.routeURL(url)
	}
	
	func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
		Notifications.handleInApp(notification)
	}
	
	func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
		TravisAPI.getUpdates(completionHandler)
	}
	
	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		Pusher.disconnect()
		Settings.save()
		Logger.info("background")
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
		Pusher.connect()
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		application.applicationIconBadgeNumber = 0
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:
		Logger.info("terminate")
		Pusher.disconnect()
	}
}
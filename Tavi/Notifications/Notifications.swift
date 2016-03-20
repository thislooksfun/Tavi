//
//  Notifications.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import Foundation

/// A wrapper for firing local notifications
class Notifications
{
	/// The last slug that a notification was sent for (used to prevent duplicates)
	private static var lastSlug = ""
	/// The last build number that a notification was sent for (used to prevent duplicates)
	private static var lastBuildNumber = -1
	/// The last status that a notification was sent for (used to prevent duplicates)
	private static var lastStatus = ""
	
	
	// MARK: Sending notifications
	
	/// Fire a build started event
	///
	/// - Parameters:
	///   - slug: The repo slug
	///   - buildNumber: The build number
	///   - fireDate: When to fire the notification (Default: now)
	static func fireBuildStarted(slug: String, buildNumber: Int, fireDate: NSDate = NSDate()) {
		fireBuildStatus(slug, buildNumber: buildNumber, status: "started", fireDate: fireDate)
	}
	
	/// Fire a build passed event
	///
	/// - Parameters:
	///   - slug: The repo slug
	///   - buildNumber: The build number
	///   - fireDate: When to fire the notification (Default: now)
	static func fireBuildPassed(slug: String, buildNumber: Int, fireDate: NSDate = NSDate()) {
		fireBuildStatus(slug, buildNumber: buildNumber, status: "passed", fireDate: fireDate)
	}
	
	/// Fire a build failed event
	///
	/// - Parameters:
	///   - slug: The repo slug
	///   - buildNumber: The build number
	///   - fireDate: When to fire the notification (Default: now)
	static func fireBuildFailed(slug: String, buildNumber: Int, fireDate: NSDate = NSDate()) {
		fireBuildStatus(slug, buildNumber: buildNumber, status: "failed", fireDate: fireDate)
	}
	
	/// Fire a build cancelled event
	///
	/// - Parameters:
	///   - slug: The repo slug
	///   - buildNumber: The build number
	///   - fireDate: When to fire the notification (Default: now)
	static func fireBuildCancelled(slug: String, buildNumber: Int, fireDate: NSDate = NSDate()) {
		fireBuildStatus(slug, buildNumber: buildNumber, status: "cancelled", fireDate: fireDate)
	}
	
	/// Fire a build event
	///
	/// - Parameters:
	///   - slug: The repo slug
	///   - buildNumber: The build number
	///   - status: The build status
	///   - fireDate: When to fire the notification (Default: now)
	static func fireBuildStatus(slug: String, buildNumber: Int, status: String, fireDate: NSDate = NSDate())
	{
		//Prevent duplicate notifications
		if slug == lastSlug && buildNumber == lastBuildNumber && status == lastStatus { return }
		
		lastSlug = slug
		lastBuildNumber = buildNumber
		lastStatus = status
		
		let noteSettings = Settings.NoteType(rawValue: Settings.NotificationTypes.getWithDefault(Settings.NoteType.All.rawValue))
		
		guard noteSettings != .None else { return }
		if status == "started"   && !noteSettings.contains(.Start)  { return }
		if status == "passed"    && !noteSettings.contains(.Pass)   { return }
		if status == "failed"    && !noteSettings.contains(.Fail)   { return }
		if status == "cancelled" && !noteSettings.contains(.Cancel) { return }
		
		buildNotification("\(slug):\nBuild #\(buildNumber) \(status)", userInfo: ["slug": slug, "build": buildNumber, "status": status], fireDate: fireDate)
	}
	
	/// Constructs a `UILocalNotification` for firing
	///
	/// - Parameters:
	///   - title: The title of the notification
	///   - action: What to display after after "Slide to..." on the lock screen - defaults to "Slide to view" if `nil` is passed (Default: `nil`)
	///   - fireDate: When the event will be fired (Default: now)
	///   - sound: The sound to play (Default: `UILocalNotificationDefaultSoundName`)
	///   - userInfo: A dictionary of information to pass to the app when the notfication is displayed in-app or is tapped (Default: `nil`)
	///   - category: Honestly, no clue what this does. (Default: `nil`)
	///   - incBadge: How much to increment the app badge by (Default: 1)
	private static func buildNotification(title: String, action: String? = nil, fireDate: NSDate = NSDate(), sound: String = UILocalNotificationDefaultSoundName, userInfo: [NSObject: AnyObject]? = nil, category: String? = nil, incBadge: Int = 1)
	{
		let note = UILocalNotification()
		note.alertBody = title                      // Message content
		note.alertAction = action                   // What to display after after "Slide to..." on the lock screen - defaults to "Slide to view"
		note.fireDate = fireDate	                // When notification will be fired
		note.soundName = sound                      // The sound to play
		note.userInfo = userInfo                    // Any specific information, such as a UUID to later backtrack
		note.category = category                    // ??
		note.applicationIconBadgeNumber = incBadge  // Increase the badge number
		
		// Schedule the notification
		UIApplication.sharedApplication().scheduleLocalNotification(note)
	}
	
	
	// MARK: Displaying in-app notifications
	
	/// Handles an in-app notification
	///
	/// - Parameter note: The notification to handle
	static func handleInApp(note: UILocalNotification)
	{
		Logger.trace("Display in-app notification:")
		Logger.indent()
		Logger.trace(note.alertBody ?? "No body found")
		Logger.outdent()
		
//		let sharedApp = UIApplication.sharedApplication()
		
//		if unseenNotes.count == 0 {
//			sharedApp.applicationIconBadgeNumber = 0
//		}
		
		let info = note.userInfo as! [String: AnyObject]
//		unseenNotes.append(info)
//		let index = unseenNotes.count - 1
		
		InAppNotification.display(info)
	}
}
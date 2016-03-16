//
//  Notifications.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import Foundation

class Notifications
{
	// MARK: Sending notifications
	
	private static var lastSlug = ""
	private static var lastBuildNumber = -1
	private static var lastStatus = ""
	
	static func fireBuildStarted(slug: String, buildNumber: Int, fireDate: NSDate = NSDate()) {
		fireBuildStatus(slug, buildNumber: buildNumber, status: "started", fireDate: fireDate)
	}
	static func fireBuildPassed(slug: String, buildNumber: Int, fireDate: NSDate = NSDate()) {
		fireBuildStatus(slug, buildNumber: buildNumber, status: "passed", fireDate: fireDate)
	}
	static func fireBuildFailed(slug: String, buildNumber: Int, fireDate: NSDate = NSDate()) {
		fireBuildStatus(slug, buildNumber: buildNumber, status: "failed", fireDate: fireDate)
	}
	static func fireBuildCancelled(slug: String, buildNumber: Int, fireDate: NSDate = NSDate()) {
		fireBuildStatus(slug, buildNumber: buildNumber, status: "cancelled", fireDate: fireDate)
	}
	static func fireBuildStatus(slug: String, buildNumber: Int, status: String, fireDate: NSDate = NSDate())
	{
		//Prevent duplicate notifications
		if slug == lastSlug && buildNumber == lastBuildNumber && status == lastStatus { return }
		
		lastSlug = slug
		lastBuildNumber = buildNumber
		lastStatus = status
		
		let inAppNoteSettings = Settings.InAppNoteType(rawValue: Settings.InAppNotificationTypes.getWithDefault(Settings.InAppNoteType.All.rawValue))
		
		guard inAppNoteSettings != .None else { return }
		if status == "started"   && !inAppNoteSettings.contains(.Start)  { return }
		if status == "passed"    && !inAppNoteSettings.contains(.Pass)   { return }
		if status == "failed"    && !inAppNoteSettings.contains(.Fail)   { return }
		if status == "cancelled" && !inAppNoteSettings.contains(.Cancel) { return }
		
		buildNotification("\(slug):\nBuild #\(buildNumber) \(status)", userInfo: ["slug": slug, "build": buildNumber, "status": status], fireDate: fireDate)
	}
	
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
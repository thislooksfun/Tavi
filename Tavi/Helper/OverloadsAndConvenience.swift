//
//  OverloadsAndConvenience.swift
//  Tavi
//
//  Created by thislooksfun on 7/6/15.
//  Copyright (c) 2015 thislooksfun. All rights reserved.
//

import UIKit

//MARK: Extensions

extension NSDate {
	func timeAgo(inTimeZone timeZone: NSTimeZone? = nil) -> NSDateComponents {
		return self.timeTo(NSDate())
	}
	
	func timeTo(date: NSDate, inTimeZone timeZone: NSTimeZone? = nil) -> NSDateComponents {
		let calendar = NSCalendar.currentCalendar()
		calendar.timeZone = timeZone ?? NSTimeZone(name: "GMT")!
		
		let units: NSCalendarUnit = [.Second, .Minute, .Hour, .Day, .WeekOfYear, .Month, .Year]
		return calendar.components(units, fromDate: self, toDate: date, options: [])
	}
}

extension CAGradientLayer {
	class func gradientLayerForBounds(bounds: CGRect, andColors colors: [CGColor], andStartPoint start: CGPoint, andEndPoint end: CGPoint) -> CAGradientLayer {
		let layer = CAGradientLayer()
		layer.frame = bounds
		layer.colors = colors
		layer.startPoint = start
		layer.endPoint = end
		return layer
	}
}

extension UIViewController
{
	func findBestViewController() -> UIViewController
	{
		if let presented = self.presentedViewController {
			// Return presented view controller
			return presented.findBestViewController()
		} else if self is UISplitViewController {
			// Return right hand side
			let svc = self as! UISplitViewController
			if (svc.viewControllers.count > 0) {
				return svc.viewControllers.last!.findBestViewController()
			} else {
				return self;
			}
		} else if self is UINavigationController {
			// Return top view
			let svc = self as! UINavigationController
			if svc.viewControllers.count > 0 {
				return svc.topViewController!.findBestViewController()
			} else {
				return self
			}
		
		} else if self is UITabBarController {
			// Return visible view
			let svc = self as! UITabBarController
			if svc.viewControllers != nil && svc.viewControllers!.count > 0 {
				return svc.selectedViewController!.findBestViewController()
			} else {
				return self;
			}
		} else {
			// Unknown view controller type, return last child view controller
			return self;
		}
	}
	
	static func currentViewController() -> UIViewController {
		// Find best view controller
		return rootViewController().findBestViewController()
	}
	
	static func rootViewController() -> UIViewController {
		return UIApplication.sharedApplication().keyWindow!.rootViewController!
	}
}

protocol Hidable {
	func show(maxAlpha maxAlpha: CGFloat, duration: Double, delay: Double, options: UIViewAnimationOptions, completion: ((finished: Bool) -> Void)?)
	func hide(minAlpha minAlpha: CGFloat, duration: Double, delay: Double, options: UIViewAnimationOptions, completion: ((finished: Bool) -> Void)?)
}

extension UIView
{
	func show(maxAlpha maxAlpha: CGFloat = 1, duration: Double = 0.3, delay: Double = 0, options: UIViewAnimationOptions = [], completion: ((finished: Bool) -> Void)? = nil) {
		self.hidden = false
		
		guard duration > 0 else {
			self.alpha = maxAlpha
			return
		}
		
		UIView.animateWithDuration(duration, delay: delay, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
			self.alpha = maxAlpha
		}, completion: nil)
	}
	
	func hide(minAlpha minAlpha: CGFloat = 0, duration: Double = 0.3, delay: Double = 0, options: UIViewAnimationOptions = [], completion: ((finished: Bool) -> Void)? = nil) {
		
		guard duration > 0 else {
			self.alpha = 0
			self.hidden = true
			return
		}
		
		UIView.animateWithDuration(duration, animations: {
			self.alpha = minAlpha
		}) { (finished) in
			self.hidden = minAlpha <= 0
			completion?(finished: finished)
		}
	}
}

extension UIDevice {
	func forceOrientation(orientation: UIInterfaceOrientation) {
		self.setValue(orientation.rawValue, forKey: "orientation")
	}
}


extension Bool {
	mutating func flip() {
		self = !self
	}
}

extension SequenceType {
	func find(search: (Self.Generator.Element) -> Bool) -> Self.Generator.Element? {
		for el in self {
			if search(el) {
				return el
			}
		}
		return nil
	}
	func findWithPos(search: (Self.Generator.Element) -> Bool) -> (index: Int, element: Self.Generator.Element?) {
		for (index, el) in self.enumerate() {
			if search(el) {
				return (index, el)
			}
		}
		return (-1, nil)
	}
}
extension SequenceType where Generator.Element: Equatable {
	func find(element: Self.Generator.Element) -> Self.Generator.Element? {
		for el in self {
			if el == element {
				return el
			}
		}
		return nil
	}
	func findWithPos(element: Self.Generator.Element) -> (index: Int, element: Self.Generator.Element?) {
		for (index, el) in self.enumerate() {
			if el == element {
				return (index, el)
			}
		}
		return (-1, nil)
	}
}

extension Array {
	mutating func moveElementFromPos(from: Int, toPos end: Int) {
		let tmp = self.removeAtIndex(from)
		self.insert(tmp, atIndex: end)
	}
}

extension Array where Element: Equatable
{
	mutating func removeDuplicates()
	{
		var out = [Element]()
		
		for repo in self {
			Logger.info("removedupes")
			if repo == out.last {
				out.append(repo)
			}
		}
		
		self = out
	}
}

public enum ViewOrientation {
	case Portrait
	case Landscape
}

extension UIView {
	public class func viewOrientationForSize(size:CGSize) -> ViewOrientation {
		return (size.width > size.height) ? .Landscape : .Portrait
	}
	
	public var viewOrientation:ViewOrientation {
		return UIView.viewOrientationForSize(self.bounds.size)
	}
	
	public func isViewOrientationPortrait() -> Bool {
		return self.viewOrientation == .Portrait
	}
	
	public func isViewOrientationLandscape() -> Bool {
		return self.viewOrientation == .Landscape
	}
}

//MARK: - Functions

func parseDate(date: String) -> NSDate?
{
	let formatter = NSDateFormatter()
	formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
	return formatter.dateFromString(date)
}

// func: async
// Runs the given callback asyncronously, after the specified delay.
//  - delay: Double
//      If delay is <= 0, it behaves exactly the same as async:
//  - onNewThread: Bool, defaults to false
//      If onNewThread is false, it runs on the main thread, otherwise it runs on a new thread with the given priority.
//  - withPriority: dispatch_queue_priority_t, defaults to DISPATCH_QUEUE_PRIORITY_DEFAULT
//      The priority with which to start the new thread. Only used if onNewThread is true
//  - cb: () -> Void
//      The callback to run on the given thread
func delay(delay: Double, onNewThread: Bool = false, withPriority priority: dispatch_queue_priority_t = DISPATCH_QUEUE_PRIORITY_DEFAULT, cb: () -> Void) {
	guard delay > 0 else {
		async(onNewThread: onNewThread, withPriority: priority, cb: cb)
		return
	}
	
	let thread = onNewThread ? dispatch_get_global_queue(priority, 0) : dispatch_get_main_queue()
	
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		thread, cb)
}

// func: async
// Runs the given callback asyncronously, immediatly.
//  - onNewThread: Bool, defaults to false
//      If onNewThread is false, it runs on the main thread, otherwise it runs on a new thread with the given priority.
//  - withPriority: dispatch_queue_priority_t, defaults to DISPATCH_QUEUE_PRIORITY_DEFAULT
//      The priority with which to start the new thread. Only used if onNewThread is true
//  - cb: () -> Void
//      The callback to run on the given thread
func async(onNewThread onNewThread: Bool = false, withPriority priority: dispatch_queue_priority_t = DISPATCH_QUEUE_PRIORITY_DEFAULT, cb: () -> Void) {
	let thread = onNewThread ? dispatch_get_global_queue(priority, 0) : dispatch_get_main_queue()
	dispatch_async(thread, cb)
}

//MARK: - Overloads

//func += <KeyType, ValueType> (inout left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
//	for (k, v) in right {
//		left.updateValue(v, forKey: k)
//	}
//}
//
//func + <KeyType, ValueType> (left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) -> Dictionary<KeyType, ValueType> {
//	var out = left
//	out += right
//	return out
//}
//
//func + <KeyType, ValueType> (left: Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>?) -> Dictionary<KeyType, ValueType> {
//	guard right != nil else { return left }
//	return left + right!
//}

func + <ValueType> (left: ValueType, right: [ValueType]) -> [ValueType] {
	var out = right
	out.insert(left, atIndex: 0)
	return out
}
func + <ValueType> (left: [ValueType], right: ValueType) -> [ValueType] {
	var out = left
	out.append(right)
	return out
}

func += (left: NSMutableAttributedString, right: NSAttributedString) {
	left.appendAttributedString(right)
}
func += (left: NSMutableAttributedString, right: String) {
	left += NSAttributedString(string: right)
}

// Boolean operators
postfix operator <! {}
postfix func <!(inout left: Bool) {
	left = !left
}

infix operator &&= {}
func &&=(inout left: Bool, right: Bool) {
	left = left && right
}

// Int & CGFloat arithmetic
func +(left: CGFloat, right: Int) -> CGFloat {
	return left + CGFloat(right)
}
func +(left: Int, right: CGFloat) -> CGFloat {
	return right + left
}
func -(left: CGFloat, right: Int) -> CGFloat {
	return left - CGFloat(right)
}
func -(left: Int, right: CGFloat) -> CGFloat {
	return right - left
}
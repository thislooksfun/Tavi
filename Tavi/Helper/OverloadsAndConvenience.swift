//
//  OverloadsAndConvenience.swift
//  Tavi
//
//  Created by thislooksfun on 7/6/15.
//  Copyright (c) 2015 thislooksfun. All rights reserved.
//

import UIKit

//MARK: Extensions

/// Adds date -> time calculations
extension NSDate
{
	/// Calculates how long ago this date was
	///
	/// - Returns: the `NSDateComponents` of how long ago it was. (Uses `.Second`, `.Minute`, `.Hour`, `.Day`, `.WeekOfYear`, `.Month`, and `.Year`)
	func timeAgo() -> NSDateComponents {
		return self.timeTo(NSDate())
	}
	
	/// Calculates how long until the given date
	///
	/// - Parameter date: The date to calculate the time to
	///
	/// - Returns: the `NSDateComponents` of how long ago it was. (Uses `.Second`, `.Minute`, `.Hour`, `.Day`, `.WeekOfYear`, `.Month`, and `.Year`)
	func timeTo(date: NSDate) -> NSDateComponents {
		let calendar = NSCalendar.currentCalendar()
		calendar.timeZone = NSTimeZone(name: "GMT")!
		
		let units: NSCalendarUnit = [.Second, .Minute, .Hour, .Day, .WeekOfYear, .Month, .Year]
		return calendar.components(units, fromDate: self, toDate: date, options: [])
	}
}

/// Adds the ability to create gradient layers from general information
extension CAGradientLayer
{
	/// Creates a gradient layer
	///
	/// - Parameters:
	///   - bounds: The bounds of the layer
	///   - colors: The colors to use
	///   - start: The start point
	///   - end: The end point
	///
	/// - SeeAlso: `CAGradientLayer`
	class func gradientLayerForBounds(bounds: CGRect, andColors colors: [CGColor], andStartPoint start: CGPoint, andEndPoint end: CGPoint) -> CAGradientLayer {
		let layer = CAGradientLayer()
		layer.frame = bounds
		layer.colors = colors
		layer.startPoint = start
		layer.endPoint = end
		return layer
	}
}

/// Adds methods for finding the top-most view controller
extension UIViewController
{
	/// Finds the 'highest' view controller
	///
	/// - Returns: The 'highest' view controller
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
	
	/// Finds the 'highest' view controller for the current `rootViewController`
	/// This is identical to calling `UIViewController.rootViewController().findBestViewController()`
	///
	/// - Returns: The 'highest' view controller
	static func currentViewController() -> UIViewController {
		// Find best view controller
		return rootViewController().findBestViewController()
	}
	
	/// Gets the current root view controller for the app
	///
	/// - Returns: The current root view controller
	static func rootViewController() -> UIViewController {
		return UIApplication.sharedApplication().keyWindow!.rootViewController!
	}
}

/// A simple protocol of a hidable object
protocol Hidable
{
	/// Shows the object
	///
	/// - Parameters:
	///   - maxAlpha: The maximum alpha value
	///   - duration: The animation duration
	///   - delay: The animation delay
	///   - options: The animation options
	///   - completion: What to do when the animation finishes
	func show(maxAlpha maxAlpha: CGFloat, duration: Double, delay: Double, options: UIViewAnimationOptions, completion: ((finished: Bool) -> Void)?)
	
	/// Hides the object
	///
	/// - Parameters:
	///   - minAlpha: The minimum alpha value
	///   - duration: The animation duration
	///   - delay: The animation delay
	///   - options: The animation options
	///   - completion: What to do when the animation finishes
	func hide(minAlpha minAlpha: CGFloat, duration: Double, delay: Double, options: UIViewAnimationOptions, completion: ((finished: Bool) -> Void)?)
}

/// Adds simple hide/show functions
extension UIView
{
	/// Shows the view
	///
	/// - Parameters:
	///   - maxAlpha: The maximum alpha value (Default: `1`)
	///   - duration: The animation duration (Default: `0.3`)
	///   - delay: The animation delay (Default: `0`)
	///   - options: The animation options (Default: `[]`)
	///   - completion: What to do when the animation finishes (Default: `nil`)
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
	
	/// Hides the view
	///
	/// - Parameters:
	///   - minAlpha: The minimum alpha value (Default: `0`)
	///   - duration: The animation duration (Default: `0.3`)
	///   - delay: The animation delay (Default: `0`)
	///   - options: The animation options (Default: `[]`)
	///   - completion: What to do when the animation finishes (Default: `nil`)
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

/// Adds a method to force the device orientation
extension UIDevice
{
	/// Forces the device orientation
	///
	/// - Warning: This often causes problems with animations and various other visual glitches.
	///            Use carefully.
	///
	/// - Parameter orientation: The orientation to force
	func forceOrientation(orientation: UIInterfaceOrientation) {
		self.setValue(orientation.rawValue, forKey: "orientation")
	}
}

/// Adds a way to invert the boolean value
extension Bool
{
	/// Flips this Bool\
	/// `true` becomes `false` and `false` becomes `true`
	mutating func flip() {
		self = !self
	}
}

/// Adds find methods
extension SequenceType
{
	/// Finds an element in the sequence
	///
	/// - Parameter search: The closure to use to check if the current element is the currect one
	///
	/// - Returns: The found element, or `nil` if none was found
	func find(search: (Self.Generator.Element) -> Bool) -> Self.Generator.Element? {
		for el in self {
			if search(el) {
				return el
			}
		}
		return nil
	}
	
	/// Finds an element in the sequence
	///
	/// - Parameter search: The closure to use to check if the current element is the currect one
	///
	/// - Returns: `(index: Int, element: Self.Generator.Element?)`\
	///            where `index` is the index of the element in the sequence, or `-1` if no matching element was found
	///            and `element` is the found element, or `nil` if none was found
	func findWithPos(search: (Self.Generator.Element) -> Bool) -> (index: Int, element: Self.Generator.Element?) {
		for (index, el) in self.enumerate() {
			if search(el) {
				return (index, el)
			}
		}
		return (-1, nil)
	}
}
/// Adds find methods for `Equatable` objects
extension SequenceType where Generator.Element: Equatable
{
	/// Finds an element in the sequence
	///
	/// - Parameter element: The element to find
	///
	/// - Returns: The found element, or `nil` if none was found
	func find(element: Self.Generator.Element) -> Self.Generator.Element? {
		for el in self {
			if el == element {
				return el
			}
		}
		return nil
	}
	
	/// Finds an element in the sequence
	///
	/// - Parameter element: The element to find
	///
	/// - Returns: `(index: Int, element: Self.Generator.Element?)`\
	///            where `index` is the index of the element in the sequence, or -1 if no matching element was found
	///            and `element` is the found element, or `nil` if none was found
	func findWithPos(element: Self.Generator.Element) -> (index: Int, element: Self.Generator.Element?) {
		for (index, el) in self.enumerate() {
			if el == element {
				return (index, el)
			}
		}
		return (-1, nil)
	}
}

/// Adds a move method
extension Array
{
	/// Moves an element in the `Array`
	///
	/// - Parameters:
	///   - from: The index to move from
	///   - end: The index to move to
	mutating func moveElementFromPos(from: Int, toPos end: Int) {
		let tmp = self.removeAtIndex(from)
		self.insert(tmp, atIndex: end)
	}
}

/// Adds a way to remove duplicate entries from a sorted list
extension Array where Element: Comparable
{
	/// Removes any duplicate elements from a sorted array
	///
	/// - Warning: This array **must** be pre-sorted for this to work
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

/// A basic view orientation enum
public enum ViewOrientation {
	/// Is Portrait (Either Portrait or PortraitUpsideDown)
	case Portrait
	
	/// Is Landscape. (Either LandscapeLeft or LandscapeRight
	case Landscape
}

/// Adds methods to get the orientation from the views size
extension UIView
{
	/// Gets the `ViewOrientation` for a given size
	///
	/// - Parameter size: The size to check
	///
	/// - Returns: The `ViewOrientation` for the given size
	public class func viewOrientationForSize(size:CGSize) -> ViewOrientation {
		return (size.width > size.height) ? .Landscape : .Portrait
	}
	
	/// The current view orientation for this view
	public var viewOrientation:ViewOrientation {
		return UIView.viewOrientationForSize(self.bounds.size)
	}
	
	/// Whether or not the `viewOrientation` is Portrait
	public func isViewOrientationPortrait() -> Bool {
		return self.viewOrientation == .Portrait
	}
	
	/// Whether or not the `viewOrientation` is Landscape
	public func isViewOrientationLandscape() -> Bool {
		return self.viewOrientation == .Landscape
	}
}


//MARK: - Functions

/// Pases a string into a date
///
/// - Note: The string must be in the format `"yyyy-MM-dd'T'HH:mm:ssZ"`
///
/// - Parameter date: The string to parse
///
/// - Returns: An `NSDate`, or `nil` if the conversion was unsuccessful
func parseDate(date: String) -> NSDate?
{
	let formatter = NSDateFormatter()
	formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
	return formatter.dateFromString(date)
}

/// Runs the given callback asyncronously, after the specified delay.
///
/// - Parameters:
///   - delay: If `delay <= 0`, it behaves exactly the same as `async`
///   - onNewThread: If `onNewThread` is false, it runs on the main thread, otherwise it runs on a new thread with the given priority. (Default: `false`)
///   - withPriority: The priority with which to start the new thread. Only used if `onNewThread` is true. (Default: `DISPATCH_QUEUE_PRIORITY_DEFAULT`)
///   - cb: The callback to run on the given thread
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

/// Runs the given callback asyncronously, immediatly.
///
/// - Parameters:
///   - onNewThread: If onNewThread is false, it runs on the main thread, otherwise it runs on a new thread with the given priority. (Default: `false`)
///   - withPriority: The priority with which to start the new thread. Only used if onNewThread is true. (Default: `DISPATCH_QUEUE_PRIORITY_DEFAULT`)
///   - cb: The callback to run on the given thread
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

/// Inserts `left` into `right` at index `0`
///
/// - Returns: The expanded array
func + <ValueType> (left: ValueType, right: [ValueType]) -> [ValueType] {
	var out = right
	out.insert(left, atIndex: 0)
	return out
}

/// Appends `right` onto `left`
///
/// - Returns: The expanded array
func + <ValueType> (left: [ValueType], right: ValueType) -> [ValueType] {
	var out = left
	out.append(right)
	return out
}

/// Appends `right` onto `left`
func += <ValueType> (inout left: [ValueType], right: ValueType) {
	left = left + right
}

/// Appends `right` onto `left`
func += (left: NSMutableAttributedString, right: NSAttributedString) {
	left.appendAttributedString(right)
}

/// Converts `right` into a `NSAttributedString`, then appends it to `left`
func += (left: NSMutableAttributedString, right: String) {
	left += NSAttributedString(string: right)
}

// MARK: Boolean operators
/// Logically identical to `left = left && right`
infix operator &&= {}
/// Logically identical to `left = left && right`
func &&=(inout left: Bool, right: Bool) {
	left = left && right
}

// MARK: Int & CGFloat arithmetic
/// Adds a `CGFloat` to an `Int`
func +(left: CGFloat, right: Int) -> CGFloat {
	return left + CGFloat(right)
}
/// Adds an `Int` to an `CGFloat`
func +(left: Int, right: CGFloat) -> CGFloat {
	return right + left
}

/// Subtracts an `Int` from a `CGFloat`
func -(left: CGFloat, right: Int) -> CGFloat {
	return left - CGFloat(right)
}
/// Subtracts a `CGFloat` from an `Int`
func -(left: Int, right: CGFloat) -> CGFloat {
	return CGFloat(left) - right
}
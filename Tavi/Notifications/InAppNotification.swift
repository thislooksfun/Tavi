//
//  InAppNotification.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

/// A small class to display a notification in-app
class InAppNotification: UIView
{
	/// The slug the notification is for
	private var slug: String!
	
	/// The y constraint for when the view is shown
	private var shownYConstraint: NSLayoutConstraint!
	/// The y constraint for when the view is hidden
	private var hiddenYConstraint: NSLayoutConstraint!
	/// The label that actually displays the text
	private var label: UILabel!
	
	/// Creates a new instance
	///
	/// - Parameter frame: The frame to build from
	private override init(frame: CGRect) {
		super.init(frame: frame)
		buildView()
	}
	
	/// Throws an error (intentionally)
	required init(coder aDecoder: NSCoder) {
		fatalError("This class does not support NSCoding")
	}
	
	/// Constructs the view
	private func buildView()
	{
		self.translatesAutoresizingMaskIntoConstraints = false
		self.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 248/255, alpha: 1)
		
		let view = UIViewController.rootViewController().view
		view.addSubview(self)
		
		initSelfConstraints(view)
		addLabels()
		addButton()
		
		view.layoutIfNeeded()
	}
	
	/// Initalizes and adds all the constraints for the overall view
	///
	/// - Parameter view: The superview to which to add the constraints
	private func initSelfConstraints(view: UIView)
	{
		view.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0))
		
		shownYConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
		hiddenYConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
		view.addConstraint(hiddenYConstraint)
	}
	
	/// Creats and adds the labels
	private func addLabels()
	{
		self.label = UILabel()
		self.label.translatesAutoresizingMaskIntoConstraints = false
		self.label.numberOfLines = 0
		self.label.textAlignment = .Center
		
		self.addSubview(self.label)
		self.label.text = "Hello there!"
		
		initLabelConstraints()
	}
	
	/// Initalizes and adds all the constraints for the labels
	private func initLabelConstraints()
	{
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Top,    relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Top,            multiplier: 1, constant:  8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Bottom,         multiplier: 1, constant: -8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Left,   relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Left,           multiplier: 1, constant:  8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Right,  relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Right,          multiplier: 1, constant: -8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil,  attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant:  0))
	}
	
	/// Adds a button to go to the repository for which this notification was sent
	private func addButton()
	{
		let button = UIButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		
		button.addTarget(self, action: #selector(InAppNotification.goToRepo(_:)), forControlEvents: .TouchUpInside)
		
		self.addSubview(button)
		
		initButtonConstraints(button)
	}
	
	/// Initalizes and adds all the constraints for the button
	///
	/// - Parameter button: The button for which to add the constraints
	private func initButtonConstraints(button: UIButton)
	{
		self.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Top,    relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top,    multiplier: 1, constant: 0))
		self.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
		self.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Left,   relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Left,   multiplier: 1, constant: 0))
		self.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Right,  relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right,  multiplier: 1, constant: 0))
	}
	
	/// Displays an in-app notification.
	///
	/// - Note: If the current `ViewController` is a `DetailViewController` and it is displaying
	/// a repo where `detailView.slug == info["slug"]` or `detailView.repo.slug == info["slug"]`,
	/// no notification will be displayed
	///
	/// - NOTE: `info` **must** adhere to the following rules:
	///   - info["slug"] must be a non-nil String
	///   - info["build"] must be a non-nil Int
	///   - info["status"] must be a non-nil String
	///
	/// - Parameter info: The info dictionary to build the notification from
	static func display(info: [String: AnyObject])
	{
		let slug = info["slug"] as! String
		let build = info["build"] as! Int
		let status = info["status"] as! String
		
		//Don't display a notification if we're already looking at that repo, that's just silly.
		let currentView = UIViewController.currentViewController()
		if currentView is DetailViewController {
			if (currentView as! DetailViewController).slug == slug || (currentView as! DetailViewController).repo?.slug == slug {
				return
			}
		}
		
		let note = InAppNotification(frame: CGRect.zero)
		
		note.slug = slug
		
		var color: UIColor
		switch status {
		case "started":   color = TravisAPI.inProgressColor
		case "passed":    color = TravisAPI.passingColor
		case "failed":    color = TravisAPI.failingColor
		case "cancelled": color = TravisAPI.cancelColor
		default:
			Logger.error("'\(status)' is not a valid status")
			return
		}
		
		let text = NSMutableAttributedString()
		text += "\(slug)\n"
		text += NSAttributedString(string: "#\(build) \(status)", attributes: [NSForegroundColorAttributeName: color])
		
		note.label.attributedText = text
		
		note.display()
		delay(3, cb: note.remove)
	}
	
	/// Animates the displaying of the notification
	private func display() {
		self.superview!.removeConstraints([shownYConstraint, hiddenYConstraint])
		self.superview!.addConstraint(shownYConstraint)
		
		UIView.animateWithDuration(0.3) {
			self.superview!.layoutIfNeeded()
		}
	}
	
	/// Animates the removing of the notification
	private func remove() {
		self.superview!.removeConstraints([shownYConstraint, hiddenYConstraint])
		self.superview!.addConstraint(hiddenYConstraint)
		
		UIView.animateWithDuration(0.3, animations: {
			self.superview!.layoutIfNeeded()
		}, completion: { (done) in
			self.removeFromSuperview()
		})
	}
	
	/// Opens the repository when the notification is tapped
	func goToRepo(sender: AnyObject) {
		JLRoutes.routeURL(NSURL(string: "tavi://slug/\(self.slug)"))
	}
}
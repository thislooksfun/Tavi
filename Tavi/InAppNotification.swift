//
//  InAppNotification.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class InAppNotification: UIView
{
	private override init(frame: CGRect) {
		super.init(frame: frame)
		buildView()
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("This class does not support NSCoding")
	}
	
	private var shownYConstraint: NSLayoutConstraint!
	private var hiddenYConstraint: NSLayoutConstraint!
	private var label: UILabel!
	
	private func buildView()
	{
		self.translatesAutoresizingMaskIntoConstraints = false
		self.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 248/255, alpha: 1)
		
		let view = UIViewController.rootViewController().view
		view.addSubview(self)
		
		initSelfConstraints(view)
		addLabels(view)
		
		view.layoutIfNeeded()
	}
	
	private func initSelfConstraints(view: UIView)
	{
		view.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0))
		
		shownYConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
		hiddenYConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
		view.addConstraint(hiddenYConstraint)
		
//		view.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 50))
	}
	
	private func addLabels(view: UIView)
	{
		self.label = UILabel()
		self.label.translatesAutoresizingMaskIntoConstraints = false
		self.label.numberOfLines = 0
		self.label.textAlignment = .Center
		
		self.addSubview(self.label)
		self.label.text = "Hello there!"
		
		initLabelConstraints()
	}
	
	private func initLabelConstraints()
	{
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Top,    relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Top,            multiplier: 1, constant:  8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Bottom,         multiplier: 1, constant: -8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Left,   relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Left,           multiplier: 1, constant:  8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Right,  relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Right,          multiplier: 1, constant: -8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil,  attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant:  0))
	}
	
	
	static func display(info: [String: AnyObject])
	{
		let note = InAppNotification(frame: CGRect.zero)
		
		let slug = info["slug"] as! String
		let build = info["build"] as! Int
		let status = info["status"] as! String
		
		var color: UIColor
		switch status {
			case "passed": color = TravisAPI.passingColor
			case "failed": color = TravisAPI.failingColor
			default:
				//FIXME: add other statuses
				Logger.error("'\(status)' is not a valid status")
				return
		}
		
		let text = NSMutableAttributedString()
		text += "\(slug)\n"
		text += NSAttributedString(string: "#\(build) \(status)", attributes: [NSForegroundColorAttributeName: color])
		
		note.label.attributedText = text
		
		note.display()
		delay(2, cb: note.remove)
	}
	private func display() {
		self.superview!.removeConstraints([shownYConstraint, hiddenYConstraint])
		self.superview!.addConstraint(shownYConstraint)
		
		UIView.animateWithDuration(0.3) {
			self.superview!.layoutIfNeeded()
		}
	}
	private func remove() {
		self.superview!.removeConstraints([shownYConstraint, hiddenYConstraint])
		self.superview!.addConstraint(hiddenYConstraint)
		
		UIView.animateWithDuration(0.3, animations: {
			self.superview!.layoutIfNeeded()
		}, completion: { (done) in
			self.removeFromSuperview()
		})
	}
}
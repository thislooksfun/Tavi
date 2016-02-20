//
//  NoConnectionPopup.swift
//  Tavi
//
//  Created by thislooksfun on 1/29/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

class NoConnectionPopup: UIView
{
	private override init(frame: CGRect) {
		super.init(frame: frame)
		buildView()
	}
	
	required init(coder aDecoder: NSCoder) {
		fatalError("This class does not support NSCoding")
	}
	
	private var shownYConstraintTop:  NSLayoutConstraint!
	private var hiddenYConstraintTop: NSLayoutConstraint!
	private var heightConstraint:     NSLayoutConstraint!
	private var label: UILabel!
	
	private func buildView()
	{
		self.translatesAutoresizingMaskIntoConstraints = false
		self.backgroundColor = UIColor(red: 250/255, green: 100/255, blue: 100/255, alpha: 1)
		
		let view = UIViewController.rootViewController().view
		view.addSubview(self)
		
		initSelfConstraints(view)
		addLabels(view)
		
		view.layoutIfNeeded()
	}
	
	private func initSelfConstraints(view: UIView)
	{
		let gap: CGFloat = 30;
		view.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Left,  relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Left,  multiplier: 1, constant:  gap))
		view.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: -gap))
		
		shownYConstraintTop =  NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Top,    multiplier: 1, constant: gap)
		hiddenYConstraintTop = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: gap)
		
		heightConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: -(gap*2))
		
		view.addConstraint(hiddenYConstraintTop)
		view.addConstraint(heightConstraint)
	}
	
	private func addLabels(view: UIView)
	{
		self.label = UILabel()
		self.label.translatesAutoresizingMaskIntoConstraints = false
		self.label.numberOfLines = 0
		self.label.textAlignment = .Center
		
		self.addSubview(self.label)
		self.label.text = "Hello there!"
		
//		initLabelConstraints()
	}
	
	private func initLabelConstraints()
	{
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Top,    relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Top,            multiplier: 1, constant:  8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Bottom,         multiplier: 1, constant: -8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Left,   relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Left,           multiplier: 1, constant:  8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Right,  relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Right,          multiplier: 1, constant: -8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil,  attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant:  0))
	}
	
	
	static func display()
	{
		let note = NoConnectionPopup(frame: CGRect.zero)
		
		note.label.text = "No connection!"
		
		note.display()
		delay(2, cb: note.remove)
	}
	private func display() {
		self.superview!.removeConstraints([shownYConstraintTop, hiddenYConstraintTop])
		self.superview!.addConstraint(shownYConstraintTop)
		
		UIView.animateWithDuration(0.3) {
			self.superview!.layoutIfNeeded()
		}
	}
	private func remove() {
		self.superview!.removeConstraints([shownYConstraintTop, hiddenYConstraintTop])
		self.superview!.addConstraint(hiddenYConstraintTop)
		
		UIView.animateWithDuration(0.3, animations: {
			self.superview!.layoutIfNeeded()
			}, completion: { (done) in
				self.removeFromSuperview()
		})
	}
}
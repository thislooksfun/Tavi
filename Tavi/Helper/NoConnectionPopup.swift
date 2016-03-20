//
//  NoConnectionPopup.swift
//  Tavi
//
//  Created by thislooksfun on 1/29/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

/// A simple popup to let the user know that there is no internet connection
///
/// - TODO: Actually implement this
class NoConnectionPopup: UIView
{
	/// Creates an instance
	private override init(frame: CGRect) {
		super.init(frame: frame)
		buildView()
	}
	
	/// Throws an error (intentionally)
	required init(coder aDecoder: NSCoder) {
		fatalError("This class does not support NSCoding")
	}
	
	/// The top constraint for when the view is shown
	private var shownYConstraintTop: NSLayoutConstraint!
	
	/// The top constraint for when the view is hidden
	private var hiddenYConstraintTop: NSLayoutConstraint!
	
	/// The height constraint
	private var heightConstraint: NSLayoutConstraint!
	
	/// The label
	private var label: UILabel!
	
	/// Constructs the view
	private func buildView()
	{
		self.translatesAutoresizingMaskIntoConstraints = false
		self.backgroundColor = UIColor(red: 250/255, green: 100/255, blue: 100/255, alpha: 1)
		
		let view = UIViewController.rootViewController().view
		view.addSubview(self)
		
		initSelfConstraints(view)
		
		view.layoutIfNeeded()
	}
	
	/// Sets up the overall constraints
	///
	/// - Parameter view: The superview to which to add the constraints
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
	
	/// Adds the labels
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
	
	/// Sets up the constraints for the label
	private func initLabelConstraints()
	{
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Top,    relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Top,            multiplier: 1, constant:  8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Bottom,         multiplier: 1, constant: -8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Left,   relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Left,           multiplier: 1, constant:  8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Right,  relatedBy: NSLayoutRelation.Equal,              toItem: self, attribute: NSLayoutAttribute.Right,          multiplier: 1, constant: -8))
		self.addConstraint(NSLayoutConstraint(item: self.label, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil,  attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant:  0))
	}
	
	/// Creates and displays a view
	static func display()
	{
		let note = NoConnectionPopup(frame: CGRect.zero)
		
		note.label.text = "No connection!"
		
		note.display()
		delay(2, cb: note.remove)
	}
	
	/// Animates this view coming into frame
	private func display() {
		self.superview!.removeConstraints([shownYConstraintTop, hiddenYConstraintTop])
		self.superview!.addConstraint(shownYConstraintTop)
		
		UIView.animateWithDuration(0.3) {
			self.superview!.layoutIfNeeded()
		}
	}
	
	/// Animates this view going out of frame, and removes it once it has finished
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
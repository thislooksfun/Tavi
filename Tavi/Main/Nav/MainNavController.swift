//
//  MainNavController.swift
//  Tavi
//
//  Created by thislooksfun on 2/7/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

import UIKit

/// The main `UINavigationController`
class MainNavController: OrientationRespectfulNavController
{
	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationBar.tintColor = UIColor.whiteColor()
		self.navigationBar.titleTextAttributes = [ NSForegroundColorAttributeName: UIColor.whiteColor() ]
		self.navigationBar.setBackgroundImage(self.imageLayerForGradientBackground(), forBarMetrics: UIBarMetrics.Default)
		
		self.interactivePopGestureRecognizer?.delegate = nil
		
		self.navigationBar.shadowImage = UIImage()
	}
	
	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}
	
	/// Gets an gradient image to use in replacement of the default status bar
	///
	/// - Returns: The gradient image
	private func imageLayerForGradientBackground() -> UIImage
	{
		var updatedFrame = self.navigationBar.bounds
		// take into account the status bar
		updatedFrame.size.height += 20
		let colors = [ Settings.Tavi_Orange_Color.CGColor, Settings.Tavi_Yellow_Color.CGColor ]
		let layer = CAGradientLayer.gradientLayerForBounds(updatedFrame, andColors: colors, andStartPoint: CGPointMake(0.5, 0), andEndPoint: CGPointMake(0.5, 1.25))
		UIGraphicsBeginImageContext(layer.bounds.size)
		layer.renderInContext(UIGraphicsGetCurrentContext()!)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
}
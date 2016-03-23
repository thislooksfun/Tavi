//
//  MainNavController.swift
//  Tavi
//
//  Copyright (C) 2016 thislooksfun
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
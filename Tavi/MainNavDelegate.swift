//
//  MainNavController.swift
//  Tavi
//
//  Created by thislooksfun on 12/6/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class MainNavDelegate: NSObject, UINavigationControllerDelegate
{
	func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
	{
//		if fromVC is MasterViewController && toVC is MenuController {
//			return LeftToRightAnimator()
//		}
//		if fromVC is MenuController && toVC is MasterViewController {
//			return RightToLeftRevealAnimator()
//		}
		
		return nil
	}
}
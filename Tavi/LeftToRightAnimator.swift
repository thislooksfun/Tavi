//
//  LeftToRightAnimator.swift
//  Tavi
//
//  Created by thislooksfun on 12/6/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

class LeftToRightAnimator: NSObject, UIViewControllerAnimatedTransitioning
{
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return 0.35
	}
	
	func animateTransition(transitionContext: UIViewControllerContextTransitioning)
	{
		let containerView = transitionContext.containerView()!
		let fromView = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!.view
		let toView =   transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!.view
		
		toView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
		toView.layer.shadowColor = UIColor.blackColor().CGColor
		toView.layer.shadowRadius = 5.0;
		toView.layer.shadowOpacity = 0.5;
		toView.layer.shadowPath = UIBezierPath(rect: toView.bounds).CGPath
		
		toView.frame.origin.x = -toView.frame.width
		
		let grayOutView = UIView(frame: fromView.frame)
		grayOutView.backgroundColor = UIColor.blackColor()
		grayOutView.alpha = 0
		
		containerView.addSubview(grayOutView)
		containerView.addSubview(toView)
		
		let duration = transitionDuration(transitionContext)
		UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
			toView.frame.origin.x = 0
			fromView.frame.origin.x = fromView.frame.width / 3
			grayOutView.frame = fromView.frame
			grayOutView.alpha = 0.1
		}, completion: { finished in
			toView.layer.shadowOpacity = 0;
			grayOutView.removeFromSuperview()
			let cancelled = transitionContext.transitionWasCancelled()
			transitionContext.completeTransition(!cancelled)
		})
	}
}
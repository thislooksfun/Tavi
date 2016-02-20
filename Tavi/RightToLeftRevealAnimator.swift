//
//  RightToLeftAnimator.swift
//  Tavi
//
//  Created by thislooksfun on 12/6/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

class RightToLeftRevealAnimator: NSObject, UIViewControllerAnimatedTransitioning
{
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return 0.35
	}
	
	func animateTransition(transitionContext: UIViewControllerContextTransitioning)
	{
		let containerView = transitionContext.containerView()!
		let fromView = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!.view
		let toView =   transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!.view
		
		fromView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
		fromView.layer.shadowColor = UIColor.blackColor().CGColor
		fromView.layer.shadowRadius = 5.0;
		fromView.layer.shadowOpacity = 0.5;
		fromView.layer.shadowPath = UIBezierPath(rect: fromView.bounds).CGPath
		
		toView.frame.origin.x = toView.frame.width / 3
		
		let grayOutView = UIView(frame: toView.frame)
		grayOutView.backgroundColor = UIColor.blackColor()
		grayOutView.alpha = 0.1
		
		containerView.addSubview(grayOutView)
		containerView.addSubview(toView)
		containerView.sendSubviewToBack(grayOutView)
		containerView.sendSubviewToBack(toView)
		
		let duration = transitionDuration(transitionContext)
		UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
			fromView.frame.origin.x = -fromView.frame.width
			toView.frame.origin.x = 0
			grayOutView.frame = toView.frame
			grayOutView.alpha = 0
		}, completion: { finished in
			fromView.layer.shadowOpacity = 0;
			grayOutView.removeFromSuperview()
			let cancelled = transitionContext.transitionWasCancelled()
			transitionContext.completeTransition(!cancelled)
		})
	}
}
//
//  DetailViewController.swift
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

/// The controller for the individual repository views
class DetailViewController: LandscapeCapableViewController, UIGestureRecognizerDelegate, UIScrollViewDelegate
{
	/// The `ConsoleTableSource` instance
	@IBOutlet var consoleTableSource: ConsoleTableSource!
	/// The overall scroll view
	@IBOutlet var mainScrollView: UIScrollView!
	/// The sideways capable scroll view
	@IBOutlet var consoleSidewaysScroll: UIScrollView!
	/// The console table
	@IBOutlet var consoleTable: UITableView!
	/// The image of the outline of the favorite icon
	@IBOutlet var favoriteIconOutline: UIImageView!
	/// The image of the filled in favorite icon
	@IBOutlet var favoriteIconFilled: UIImageView!
	/// The loading box for the main (top) section
	@IBOutlet var loadingMain: UIView!
	/// The loading box for the console section
	@IBOutlet var loadingConsole: UIView!
	/// The bottom position of the `loadingMain` view
	@IBOutlet var loadingBottomConstraint: NSLayoutConstraint!
	
	/// The color bar on the left side
	@IBOutlet var colorBar: UIView!
	/// The build status image
	@IBOutlet var buildStatus: UIImageView!
	/// The branch label
	@IBOutlet var branchLabel: UILabel!
	/// The label for the commit message
	@IBOutlet var commitMsgLabel: UILabel!
	/// The build number label
	@IBOutlet var buildNumberLabel: UILabel!
	
	/// The `MasterViewController` instance. Used to tell it when the
	/// repository has updated so it can refresh accordingly.
	var master: MasterViewController?
	
	/// The ID to load from
	var repoId: Int? {
		didSet {
			self.idSet()
		}
	}
	
	/// The slug to load from
	var slug: String? {
		didSet {
			self.slugSet()
		}
	}
	
	/// The repository this controller represents
	var repo: TravisRepo? {
		didSet {
			if oldValue != nil && self.repo != nil && self.repo != oldValue {
				master?.detailRepoDidChange(self.repo!)
				self.consoleTableSource.clearRows()
			}
			self.repo?.setPusherEventCallback({ (_) in self.configureView(false) }, forObject: self)
		}
	}
	
	/// Whether or not the `buildStatus` image is rotating
	private var isRotating = false
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		self.automaticallyAdjustsScrollViewInsets = false
		
		self.favoriteIconFilled.hide(duration: 0)
		
		self.configureView(true)
		
		self.mainScrollView.scrollsToTop = true
		self.consoleSidewaysScroll.scrollsToTop = false
		self.consoleTable.scrollsToTop = false
		
		self.favoriteIconOutline.tintColorDidChange()
		self.favoriteIconFilled.tintColorDidChange()
		
		self.navigationController?.interactivePopGestureRecognizer?.delegate = self
		
		self.consoleTableSource.afterReloadResize = {
			self.scrollViewDidScroll(self.mainScrollView)
		}
		
		//TODO: Decide whether or not to implement this
//		self.mainScrollView.indicatorStyle = .White
//		self.consoleSidewaysScroll.indicatorStyle = .White
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailViewController.reload), name: UIApplicationDidBecomeActiveNotification, object: nil)
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.consoleSidewaysScroll.scrollEnabled = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.consoleSidewaysScroll.scrollEnabled = false //Keep the scroll view from scrolling while the the user is dragging to go back from the left edge
		self.repo?.removePusherEventCallbackForObject(self)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.consoleTableSource.didLayoutSubviews()
	}
	
	override func previewActionItems() -> [UIPreviewActionItem] {
		guard repo != nil || slug != nil else { return [] }
		
		let favToggleTitle = Favorites.isFavorite(self.repo?.slug ?? self.slug!) ? "Unfavorite" : "Favorite"
		let favToggle = UIPreviewAction(title: favToggleTitle, style: .Default) {
			(action, vc) in
			Favorites.toggleFavorite(self.repo?.slug ?? self.slug!)
			let nav = UIViewController.rootViewController() as! UINavigationController
			let master = nav.viewControllers.first as! MasterViewController
			master.tableView.reloadData()
		}
		
		let restartBuild = UIPreviewAction(title: "Restart Build", style: .Default) {
			(action, vc) in
			self.restartBuild(nil)
		}
		return [restartBuild, favToggle]
	}
	
	/// Called when the ID has been set
	private func idSet() {
		guard self.repoId != nil else { return }
		
		TravisRepo.repoForID(self.repoId!, done: gotRepo)
	}
	
	/// Called when the slug has been set
	private func slugSet() {
		guard slug != nil else { return }
		
		self.navigationItem.title = slug!
	
		TravisRepo.repoForSlug(self.slug!, done: gotRepo)
	}
	
	/// Called when a repository has been loaded.
	///
	/// - Note: If `newRepo` is `nil`, an alert will be displayed and this view will close
	///
	/// - Parameter newRepo: The new `TravisRepo` to set
	private func gotRepo(newRepo: TravisRepo?)
	{
		guard newRepo != nil else {
			if !Alert.isAlertShowing() {
				let action = Alert.getDefaultActionWithTitle("OK", andHandler: { (_) in self.navigationController?.popViewControllerAnimated(true) })
				Alert.showAlertWithTitle("Error", andMessage: "There was an error loading this repository. Check the slug or try again later", andActions: [action])
			}
			return
		}
		self.repo?.dismiss()
		self.repo = newRepo
		self.configureView(false)
	}
	
	/// Reloads the repo
	func reload() {
		self.moveToMainLoading(false)
		self.slug = self.repo?.slug ?? self.slug
	}
	
	/// Configures the view from the current information
	///
	/// - Parameter isInDidLoad: Whether or not this is being called from `viewDidLoad`
	func configureView(isInDidLoad: Bool)
	{
		if self.repo != nil {
			self.moveToConsoleLoading(!isInDidLoad)
			self.loadFromRepo(self.repo!)
		} else {
			self.hideAll()
			if self.slug != nil {
				self.moveToMainLoading(!isInDidLoad)
				setFavorite(Favorites.isFavorite(self.slug!))
			} else if self.repoId != nil {
				self.moveToMainLoading(!isInDidLoad)
			}
		}
		
		self.view.layoutIfNeeded()
	}
	
	/// Jumps the loading view to the 'main' (top) position
	///
	/// - Parameter animate: Whether or not to animate the transition
	private func moveToMainLoading(animate: Bool)
	{
		self.loadingMain.show(duration: 0)
		self.loadingConsole.show(duration: 0)
		
		self.loadingBottomConstraint.constant = 60
		if animate {
			UIView.animateWithDuration(0.4, animations: self.view.layoutIfNeeded)
		} else {
			self.view.layoutIfNeeded()
		}
	}
	
	/// Transitions the loading view to the console, or bottom, position
	///
	/// - Parameter animate: Whether or not to animate the transition
	private func moveToConsoleLoading(animate: Bool)
	{
		self.loadingMain.show(duration: 0)
		self.loadingConsole.show(duration: 0)
		
		self.loadingBottomConstraint.constant = -60
		if animate {
			UIView.animateWithDuration(0.4, animations: self.view.layoutIfNeeded)
		} else {
			self.view.layoutIfNeeded()
		}
		
		//TODO: After x seconds, display a message saying "it's still loading"
	}
	
	/// Hides all the hidable sections of the screen
	private func hideAll()
	{
		self.colorBar.hidden = true
		self.buildStatus.hidden = true
		self.branchLabel.alpha = 0.4
		self.commitMsgLabel.alpha = 0.4
		self.buildNumberLabel.hidden = true
	}
	
	/// Shows all the hidable sections of the screen
	private func showAll()
	{
		self.colorBar.show()
		self.buildStatus.show()
		self.branchLabel.show()
		self.branchLabel.show()
		self.commitMsgLabel.show()
		self.buildNumberLabel.show()
	}
	
	/// Loads from a `TravisRepo` object
	///
	/// - Parameter repo: The repo object to load from
	private func loadFromRepo(repo: TravisRepo)
	{
		Logger.info(repo.slug)
		
		self.navigationItem.title = repo.slug
		
		repo.lastBuild?.loadJobs() { (jobs) in
			if let first = jobs.first {
				self.consoleTableSource.load(first) { self.loadingConsole.hide() }
			} else {
				self.loadingConsole.hide()
			}
		}
		
		setFavorite(Favorites.isFavorite(repo.slug))
		
		var sideColor: UIColor
		var textColor: UIColor?
		
		if repo.lastBuild == nil {
			//TODO: Special view when there have been no builds.
			self.buildNumberLabel.hidden = true
			
			sideColor = TravisAPI.noBuildColor
			textColor = TravisAPI.cancelColor
			self.buildStatus.image = UIImage(named: "icon-no-builds")
		} else {
			self.buildNumberLabel.text = "#\(repo.lastBuild!.buildNumber)"
			switch repo.lastBuild!.status {
			case .Passing:
				sideColor = TravisAPI.passingColor
				self.buildStatus.image = UIImage(named: "icon-passed")
			case .Failing:
				sideColor = TravisAPI.failingColor
				self.buildStatus.image = UIImage(named: "icon-failed")
			case .Created, .Started:
				sideColor = TravisAPI.inProgressColor
				self.buildStatus.image = UIImage(named: "icon-in-progress")
			case .Cancelled:
				sideColor = TravisAPI.cancelColor
				self.buildStatus.image = UIImage(named: "icon-cancelled")
			case .Unknown:
				sideColor = TravisAPI.noBuildColor
				textColor = TravisAPI.cancelColor
				self.buildStatus.image = UIImage(named: "icon-no-builds")
			}
		}
		
		if repo.lastBuild?.status == .Created || repo.lastBuild?.status == .Started {
			self.startRotating()
		} else {
			self.stopRotating()
		}
		
		self.colorBar.backgroundColor = sideColor
		self.branchLabel.textColor = textColor ?? sideColor
		self.commitMsgLabel.textColor = textColor ?? sideColor
		self.buildNumberLabel.textColor = textColor ?? sideColor
		
		if let last = repo.lastBuild {
			self.branchLabel.text = last.commit.branch
			self.commitMsgLabel.text = last.commit.message
			//TODO: Handle no builds
		}
		
		//TODO: Make these work:
//		formatDuration(repo)
//		formatFinishDate(repo.lastBuild?.finishedAt)
		
		self.showAll()
	}
	
	/// Start rotating the `buildStatus` image
	private func startRotating() {
		guard !self.isRotating else { return }
		self.isRotating = true
		self.rotate()
	}
	
	/// Rotates the icon halfway around
	///
	/// - Note: While this technically does have a parameter, it is
	///         unused. It is only there to allow this function to be
	///         passed directly to the `completion:` section of `UIView.animateWithDuration`
	private func rotate(_: Bool? = nil) {
		guard self.isRotating else { return }
		
		self.buildStatus.transform = CGAffineTransformMakeRotation(0)
		
		UIView.animateWithDuration(1.5, delay: 0.25, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
			self.buildStatus.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
			}, completion: self.rotate)
	}
	
	override func animationDidStart(anim: CAAnimation) {
		if self.isRotating {
			self.rotate()
		}
	}
	
	/// Stop rotating the `buildStatus` image
	private func stopRotating() {
		guard self.isRotating else { return }
		self.isRotating = false
		
		UIView.animateWithDuration(0, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
			self.buildStatus.transform = CGAffineTransformMakeRotation(0)
			}, completion: self.rotate)
	}
	
//	func formatDuration(repo: TravisRepo)
//	{
//		guard let start = repo.lastBuild?.startedAt else {
//			self.durationLabel.text = "Duration: -"
//			return
//		}
//		
//		let end = repo.lastBuild?.finishedAt ?? NSDate()
//		let comps = start.timeTo(end)
//		
//		var out = ""
//		if comps.year > 0 || comps.month > 0 || comps.weekOfYear > 0 || comps.day > 0 {
//			out = "more than 24 hrs"
//		} else {
//			if comps.hour > 0 {
//				if comps.hour == 1 {
//					out = "1 hr"
//				} else {
//					out = "\(comps.hour) hrs \(comps.minute) min \(comps.second) sec"
//				}
//			} else if comps.minute > 0 {
//				out = "\(comps.minute) min \(comps.second) sec"
//			} else {
//				out = "\(comps.second) sec"
//			}
//		}
//		
//		self.durationLabel.text = "Duration: \(out)"
//	}
	
//	private func formatFinishDate(finishDate: NSDate?)
//	{
//		guard let date = finishDate else {
//			self.finishDateLabel.text = "Finished: -"
//			return
//		}
//		
//		let comps = date.timeAgo()
//		
//		var out = ""
//		if comps.year > 0 {
//			if comps.year == 1 {
//				out = "about a year"
//			} else {
//				out = "\(comps.year) years"
//			}
//		} else if comps.month > 0 {
//			if comps.month == 1 {
//				out = "about a month"
//			} else {
//				out = "\(comps.month) months"
//			}
//		} else if comps.weekOfYear > 0 {
//			if comps.weekOfYear == 1 {
//				out = "about a week"
//			} else {
//				out = "\(comps.weekOfYear) weeks"
//			}
//		} else if comps.day > 0 {
//			if comps.day == 1 {
//				out = "about a day"
//			} else {
//				out = "\(comps.day) days"
//			}
//		} else if comps.hour > 0 {
//			if comps.hour == 1 {
//				out = "about an hour"
//			} else {
//				out = "\(comps.hour) hours"
//			}
//		} else if comps.minute > 0 {
//			if comps.minute == 1 {
//				out = "about a minute"
//			} else {
//				out = "\(comps.minute) minutes"
//			}
//		} else {
//			out = "less than a minute"
//		}
//		
//		self.finishDateLabel.text =  "Finished: \(out) ago"
//	}
	
	/// Shows the appropriate state of the favorite icon
	///
	/// - Parameter state: Whether or not this repo is favorited
	private func setFavorite(state: Bool) {
		if state {
			self.favoriteIconFilled.show()
		} else {
			self.favoriteIconFilled.hide()
		}
	}
	
	func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return self.consoleSidewaysScroll.gestureRecognizers?.contains(otherGestureRecognizer) ?? false
	}
	
	@IBAction func restartBuild(sender: AnyObject?) {
		Logger.trace("Restarting build")
		guard self.repo != nil else { return }
		guard self.repo!.builds.count > 0 else { return }
		TravisAPI.restartBuild(self.repo!.builds[0].buildID)
	}
	
	/// Toggles the favorited state of the repo
	@IBAction func favorite(sender: AnyObject) {
		guard self.repo != nil || self.slug != nil else { return }
		Favorites.toggleFavorite(self.repo?.slug ?? self.slug!)
		setFavorite(Favorites.isFavorite(self.repo?.slug ?? self.slug!))
	}
	
	/// Called when one of the console table cells is long pressed
	@IBAction func longPress(sender: UILongPressGestureRecognizer)
	{
		guard sender.state == UIGestureRecognizerState.Began else { return }
		guard let sendView = sender.view else { return }
		
		let position = sender.locationInView(sendView)
		guard let indexPath : NSIndexPath = (sendView as! UITableView).indexPathForRowAtPoint(position) else { return }
		
		self.becomeFirstResponder()
		
		let menu = UIMenuController.sharedMenuController()
		let rect = self.consoleTable.rectForRowAtIndexPath(indexPath)
		
		let scroll = mainScrollView.contentOffset
		let screenWidth = UIScreen.mainScreen().bounds.width
		let rectOffset = CGRectMake(0, rect.origin.y - scroll.y + 200, screenWidth, 20)
		
		consoleTableSource.highlightIndex(indexPath)
		
		menu.setTargetRect(rectOffset, inView: self.view)
		menu.setMenuVisible(true, animated: true)
		
	}
	
	override func becomeFirstResponder() -> Bool {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIResponder.resignFirstResponder), name: UIMenuControllerWillHideMenuNotification, object: nil)
		return super.becomeFirstResponder()
	}
	
	override func resignFirstResponder() -> Bool {
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerDidHideMenuNotification, object: nil)
		consoleTableSource.dehighlightAll()
		return super.resignFirstResponder()
	}
	
	override func canBecomeFirstResponder() -> Bool {
		return true
	}
	
	override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
		/* UIMenuController (edit menu) options:
		cut:
		copy:
		select:
		selectAll:
		paste:
		delete:
		_promptForReplace:
		_transliterateChinese:
		_showTextStyleOptions:
		_define:
		_addShortcut:
		_accessibilitySpeak:
		_accessibilitySpeakLanguageSelection:
		_accessibilityPauseSpeaking:
		_share:
		makeTextWritingDirectionRightToLeft:
		makeTextWritingDirectionLeftToRight:
		*/
		
		if action.description == "copy:" { return true }
		if action.description == "_accessibilitySpeak:" { return true }
//		if action.description == "_accessibilityPauseSpeaking:" { return true }
		return false
	}
	
	func scrollViewDidScroll(scrollView: UIScrollView) {
		guard scrollView == self.mainScrollView else { return }
		guard let navControl = self.navigationController else { return }
		
		let navBarHeight = navControl.navigationBarHidden ? 0 : navControl.navigationBar.frame.height
		let distanceFromTop = navBarHeight + UIApplication.sharedApplication().statusBarFrame.size.height
		let bottom = scrollView.contentSize.height - scrollView.contentOffset.y - UIScreen.mainScreen().bounds.height + distanceFromTop
		self.consoleSidewaysScroll.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
	}
	
	override func copy(sender: AnyObject?) {
		self.consoleTableSource.copyHighlightedRow()
	}
	
	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
		
		//Transition will start
		coordinator.animateAlongsideTransition({ (context) in
			//Animate transition
			if UIView.viewOrientationForSize(size) == .Landscape {
				self.navigationController?.setNavigationBarHidden(true, animated: true)
				self.navigationController?.interactivePopGestureRecognizer?.enabled = false
			} else {
				self.navigationController?.setNavigationBarHidden(false, animated: true)
				self.navigationController?.interactivePopGestureRecognizer?.enabled = true
			}
			
			// Update the position of the bottom scroll bar
			self.scrollViewDidScroll(self.mainScrollView)
			}, completion: { (_) in
				// Update the console table info labels
				self.consoleTableSource.scrollViewDidScroll(self.consoleSidewaysScroll)
		})
	}
}
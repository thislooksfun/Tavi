//
//  DetailViewController.swift
//  Tavi
//
//  Created by thislooksfun on 12/2/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

/// The controller for the individual repository views
class DetailViewController: LandscapeCapableViewController, UIGestureRecognizerDelegate
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
	var id: Int? {
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
			if self.repo != nil {
				master?.detailRepoDidChange(self.repo!)
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
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "reload", name: UIApplicationDidBecomeActiveNotification, object: nil)
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.consoleSidewaysScroll.scrollEnabled = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.consoleSidewaysScroll.scrollEnabled = false
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
		return [favToggle]
	}
	
	/// Called when the ID has been set
	private func idSet() {
		guard id != nil else { return }
		
		TravisRepo.repoForID(self.id!, done: gotRepo)
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
			let action = Alert.getDefaultActionWithTitle("OK", andHandler: { (_) in self.navigationController!.popViewControllerAnimated(true) })
			Alert.showAlertWithTitle("Error", andMessage: "There was an error loading this repository. Check the slug or try again later", andActions: [action])
			return
		}
		self.repo = newRepo
		self.configureView(false)
	}
	
	/// Reloads the repo
	func reload() {
		self.jumpToMainLoading()
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
				self.jumpToMainLoading()
				setFavorite(Favorites.isFavorite(self.slug!))
			} else if self.id != nil {
				self.jumpToMainLoading()
			}
		}
		
		self.view.layoutIfNeeded()
	}
	
	/// Jumps the loading view to the 'main' (top) position
	private func jumpToMainLoading() {
		self.loadingMain.show()
		self.loadingConsole.show()
		self.loadingBottomConstraint.constant = 40
		self.view.layoutIfNeeded()
	}
	
	/// Transitions the loading view to the console, or bottom, position
	///
	/// - Parameter animate: Whether or not to animate the transition
	private func moveToConsoleLoading(animate: Bool)
	{
		self.loadingBottomConstraint.constant = -60
		if animate {
			UIView.animateWithDuration(0.4, animations: self.view.layoutIfNeeded, completion: { (_) in self.loadingMain.hide() })
		} else {
			self.view.layoutIfNeeded()
		}
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
		
//		if let first = repo.lastBuild?.jobs.first {
			//TODO: add callback for when jobs are done
//			self.consoleTableSource.load(first, done: { self.loadingBottom.hide() })
//		}
		
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
	
	/// Toggles the favorited state of the repo
	@IBAction func favorite(sender: AnyObject) {
		guard self.repo != nil || self.slug != nil else { return }
		Favorites.toggleFavorite(self.repo?.slug ?? self.slug!)
		setFavorite(Favorites.isFavorite(self.repo?.slug ?? self.slug!))
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
		}, completion: nil)
	}
}
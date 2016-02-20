//
//  DetailViewController.swift
//  Tavi
//
//  Created by thislooksfun on 12/2/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class DetailViewController: LandscapeCapableViewController, UIGestureRecognizerDelegate {

	@IBOutlet var consoleTableSource: ConsoleTableSource!
	@IBOutlet var mainScrollView: UIScrollView!
	@IBOutlet var consoleSidewaysScroll: UIScrollView!
	@IBOutlet var consoleTable: UITableView!
	@IBOutlet var favoriteIconOutline: UIImageView!
	@IBOutlet var favoriteIconFilled: UIImageView!
	@IBOutlet var loading: UIView!
	
	var slug: String? {
		didSet {
			self.slugSet()
		}
	}
	
	private var repo: TravisRepo?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.automaticallyAdjustsScrollViewInsets = false
		
		self.favoriteIconFilled.hide(duration: 0)
		
		self.configureView()
		
		self.mainScrollView.scrollsToTop = true
		self.consoleSidewaysScroll.scrollsToTop = false
		self.consoleTable.scrollsToTop = false
		
		self.favoriteIconOutline.tintColorDidChange()
		self.favoriteIconFilled.tintColorDidChange()
		
		self.navigationController?.interactivePopGestureRecognizer?.delegate = self
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.consoleSidewaysScroll.scrollEnabled = true
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.consoleSidewaysScroll.scrollEnabled = false
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.consoleTableSource.didLayoutSubviews()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func previewActionItems() -> [UIPreviewActionItem] {
		let favToggleTitle = Favorites.isFavorite(self.slug!) ? "Unfavorite" : "Favorite"
		let favToggle = UIPreviewAction(title: favToggleTitle, style: .Default) {
			(action, vc) in
			guard self.slug	!= nil else { return }
			Favorites.toggleFavorite(self.slug!)
			let nav = UIViewController.rootViewController() as! UINavigationController
			let master = nav.viewControllers.first as! MasterViewController
			master.tableView.reloadData()
		}
		return [favToggle]
	}
	
	func slugSet() {
		guard slug != nil else { return }
		
		self.navigationItem.title = slug!
		
		TravisRepo.repoForSlug(self.slug!) {
			(newRepo) in
			guard newRepo != nil else {
				let action = Alert.getDefaultActionWithTitle("OK", andHandler: { (_) in self.navigationController!.popViewControllerAnimated(true) })
				Alert.showAlertWithTitle("Error", andMessage: "There was an error loading this repository. Check the slug or try again later", andActions: [action])
				return
			}
			self.repo = newRepo
			self.configureView()
		}
	}
	func configureView() {
		if self.repo != nil {
			self.loading.hidden = true
			
			if let first = self.repo!.lastBuild?.jobs.first {
				self.consoleTableSource.load(first)
			}
		} else if self.slug != nil {
			self.loading.hidden = false
			setFavorite(Favorites.isFavorite(self.slug!))
		}
	}
	
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
	
	@IBAction func favorite(sender: AnyObject) {
		guard self.slug != nil else { return }
		Favorites.toggleFavorite(self.slug!)
		setFavorite(Favorites.isFavorite(self.slug!))
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
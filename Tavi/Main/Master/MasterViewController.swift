//
//  MasterViewController.swift
//  Tavi
//
//  Created by thislooksfun on 12/2/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class MasterViewController: PortraitTableViewController
{
	private let octicons = UIFont(name: "octicons", size: 20)
	var repos = [TravisRepo]()
	
	private var noBuildBackground: UIView!
	private var notAuthedBackground: UIView!
	
	private var timer: NSTimer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let refresh = self.refreshControl {
			refresh.addTarget(self, action: "reloadFromRefresh:", forControlEvents: UIControlEvents.ValueChanged)
			refresh.superview!.sendSubviewToBack(refresh)
			async() {
				refresh.beginRefreshing()
				refresh.endRefreshing()
			}
		}
		
		self.view.backgroundColor = UIColor(red: (250/255), green: (249/255), blue: (247/255), alpha: 1)
		
		self.constructNoBuilds()
		self.constructNotAuthed()
		
		self.timer = NSTimer(timeInterval: 0.25, target: self, selector: "timerTick", userInfo: nil, repeats: true)
		NSRunLoop.currentRunLoop().addTimer(self.timer, forMode: NSRunLoopCommonModes)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.tableView.reloadData()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if (Settings.HasReadDisclaimer.get()) != true {
			DisclaimerController.display()
		}
		
		if self.repos.count == 0 {
			async(cb: self.reload)
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func unwindFromMenu(sender: UIStoryboardSegue) {}
	
	func cellDidLoadFromRepo() {
		let preSort = self.repos
		self.repos.sortInPlace(self.repoSort)
		if self.repos != preSort {
			self.tableView.reloadData()
		}
	}
	
	private func repoSort(repo1: TravisRepo, repo2: TravisRepo) -> Bool
	{
		if repo1.lastBuild == nil && repo2.lastBuild == nil {
			return repo1.slug.compare(repo2.slug) == NSComparisonResult.OrderedDescending
		} else if repo1.lastBuild == nil && repo2.lastBuild != nil {
			return false
		} else if repo1.lastBuild != nil && repo2.lastBuild == nil {
			return true
		}
		
		let build1 = repo1.lastBuild!
		let build2 = repo2.lastBuild!
		
		if build1.status.isInProgress() && build2.status.isInProgress() {
			return build1.buildID > build2.buildID
		} else if build1.status.isInProgress() && !build2.status.isInProgress() {
			return true
		} else if !build1.status.isInProgress() && build2.status.isInProgress() {
			return false
		} else {
			return build1.finishedAt!.compare(build2.finishedAt!) == NSComparisonResult.OrderedDescending
		}
	}
	
	func reloadFromRefresh(sender: AnyObject?) {
		reload()
	}
	func reload()
	{
		self.refreshControl?.endRefreshing()
		let hud = MBProgressHUD.showHUDAddedTo(self.navigationController!.view, animated: true)
		hud.labelText = "Loading"
		hud.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
		hud.color = UIColor(white: 0.0, alpha: 0.7)
		Logger.info("Reloading!")
		TravisAPI.load()
		{ (let authState, let repos) in
			if authState == .Success && repos != nil
			{
				self.hideBackground()
				hud.mode = .AnnularDeterminate
				
				var count = repos!.count
				var newRepos = [TravisRepo]()
				
				func addNewRepo(rp: TravisRepo?) {
					Logger.info(count - 1)
					
					if rp != nil {
						rp!.setBindingCallback(self.onRepoEventForRepo)
						newRepos.append(rp!)
					}
					
					if --count <= 0 {
						newRepos.sortInPlace(self.repoSort)
						if newRepos != self.repos {
							self.repos.forEach({ (repo) in repo.dismiss() })
							self.repos = newRepos
							self.tableView.reloadData()
						}
						async() {
							hud.hide(true)
						}
					} else {
						hud.progress = Float(repos!.count - count)/Float(repos!.count)
					}
				}
				
				for repo in repos! {
					TravisRepo.repoFromJson(repo, done: addNewRepo)
				}
			} else if authState == .NeedsGithub {
				self.clearTable()
				hud.hide(true)
				self.showNotAuthed()
				Logger.info("Authing...")
				AuthHelper.auth(finished: { (success) in
					if success {
						self.reload()
					}
				})
			} else {
				self.clearTable()
				hud.hide(true)
				self.showNoBuilds()
				Logger.warn("Problem loading Travis")
			}
		}
	}
	
	func onRepoEventForRepo(repo: TravisRepo)
	{
		let (index, repo) = self.repos.findWithPos(repo)
		
		guard index > -1 else { return }
		guard let last = repo?.lastBuild else { return }
		
		Logger.info("Got status \(last.status), for repo \(repo!.slug), at index \(index)")
		if last.status == .Created && index > 0 {
			Logger.info("Created, moving")
			self.tableView.reloadData()
			self.repos.moveElementFromPos(index, toPos: 0)
			self.tableView.moveSection(index, toSection: 0)
		} else if !last.status.isInProgress() {
			Logger.info("Not in progress")
			self.tableView.reloadSections(NSIndexSet(index: index), withRowAnimation: .None)
			
			var newIndex = index
			
			for i in (index+1)..<repos.count {
				if repos[i].lastBuild == nil || (!repos[i].lastBuild!.status.isInProgress()) {
					newIndex = i-1
					break;
				}
			}
			Logger.info("New index: \(newIndex)")
			self.tableView.reloadData()
			self.repos.moveElementFromPos(index, toPos: newIndex)
			self.tableView.moveSection(index, toSection: newIndex)
		} else {
			Logger.info("Other")
			self.tableView.reloadSections(NSIndexSet(index: index), withRowAnimation: .None)
		}
	}
	
	func constructNoBuilds() {
		noBuildBackground = UIView()
		noBuildBackground.hidden = true
		noBuildBackground.alpha = 0
		
		let noBuildsLabel = UILabel()
		noBuildsLabel.text = "No builds found"
		noBuildsLabel.translatesAutoresizingMaskIntoConstraints = false
		noBuildsLabel.font = UIFont.systemFontOfSize(25)
		noBuildsLabel.textColor = UIColor(white: 0.4, alpha: 1)
		
		let pullToRefreshLabel = UILabel()
		pullToRefreshLabel.text = "Pull to refresh"
		pullToRefreshLabel.translatesAutoresizingMaskIntoConstraints = false
		pullToRefreshLabel.font = UIFont.systemFontOfSize(25)
		pullToRefreshLabel.textColor = UIColor(white: 0.4, alpha: 1)
		
		noBuildBackground.addSubview(noBuildsLabel)
		noBuildBackground.addConstraint(NSLayoutConstraint(item: noBuildsLabel, attribute: .CenterX, relatedBy: .Equal, toItem: noBuildBackground, attribute: .CenterX, multiplier: 1, constant: 0))
		noBuildBackground.addConstraint(NSLayoutConstraint(item: noBuildsLabel, attribute: .CenterY, relatedBy: .Equal, toItem: noBuildBackground, attribute: .CenterY, multiplier: 1, constant: -40))
		
		noBuildBackground.addSubview(pullToRefreshLabel)
		noBuildBackground.addConstraint(NSLayoutConstraint(item: pullToRefreshLabel, attribute: .CenterX, relatedBy: .Equal, toItem: noBuildBackground, attribute: .CenterX, multiplier: 1, constant: 0))
		noBuildBackground.addConstraint(NSLayoutConstraint(item: pullToRefreshLabel, attribute: .CenterY, relatedBy: .Equal, toItem: noBuildBackground, attribute: .CenterY, multiplier: 1, constant: 0))
	}
	
	func constructNotAuthed() {
		notAuthedBackground = UIView()
		notAuthedBackground.hidden = true
		notAuthedBackground.alpha = 0
		
		let notAuthedLabel = UILabel()
		notAuthedLabel.text = "Not logged in"
		notAuthedLabel.translatesAutoresizingMaskIntoConstraints = false
		notAuthedLabel.font = UIFont.systemFontOfSize(25)
		notAuthedLabel.textColor = UIColor(white: 0.4, alpha: 1)
		
		let pullToRefreshLabel = UILabel()
		pullToRefreshLabel.text = "Pull to refresh"
		pullToRefreshLabel.translatesAutoresizingMaskIntoConstraints = false
		pullToRefreshLabel.font = UIFont.systemFontOfSize(25)
		pullToRefreshLabel.textColor = UIColor(white: 0.4, alpha: 1)
		
		notAuthedBackground.addSubview(notAuthedLabel)
		notAuthedBackground.addConstraint(NSLayoutConstraint(item: notAuthedLabel, attribute: .CenterX, relatedBy: .Equal, toItem: notAuthedBackground, attribute: .CenterX, multiplier: 1, constant: 0))
		notAuthedBackground.addConstraint(NSLayoutConstraint(item: notAuthedLabel, attribute: .CenterY, relatedBy: .Equal, toItem: notAuthedBackground, attribute: .CenterY, multiplier: 1, constant: -40))
		
		notAuthedBackground.addSubview(pullToRefreshLabel)
		notAuthedBackground.addConstraint(NSLayoutConstraint(item: pullToRefreshLabel, attribute: .CenterX, relatedBy: .Equal, toItem: notAuthedBackground, attribute: .CenterX, multiplier: 1, constant: 0))
		notAuthedBackground.addConstraint(NSLayoutConstraint(item: pullToRefreshLabel, attribute: .CenterY, relatedBy: .Equal, toItem: notAuthedBackground, attribute: .CenterY, multiplier: 1, constant: 0))
	}
	
	func showNoBuilds() {
		guard self.tableView.backgroundView != self.noBuildBackground else { return }
		self.hideBackground() {
			self.tableView.backgroundView = self.noBuildBackground
			self.showBackground()
		}
	}
	func showNotAuthed() {
		guard self.tableView.backgroundView != self.notAuthedBackground else { return }
		self.hideBackground() {
			self.tableView.backgroundView = self.notAuthedBackground
			self.showBackground()
		}
	}
	
	func showBackground() {
		guard let background = self.tableView.backgroundView else { return }
		background.show()
	}
	
	func hideBackground(done: (() -> Void)? = nil) {
		guard let background = self.tableView.backgroundView else {
			done?()
			return
		}
		background.hide() { (_) in
			done?()
		}
	}
	
	func clearTable() {
		Logger.info("Clearing table...")
		while self.repos.count > 0 {
			self.repos.removeFirst().dismiss()
		}
		self.tableView.reloadData()
		Logger.info("Done!")
	}
	
	func timerTick() {
		for i in 0..<repos.count {
			let repo = repos[i]
			
			guard repo.lastBuild != nil && repo.lastBuild!.status.isInProgress() else { break }
			
			let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: i))
			guard cell is RepoCell else { continue }
			
			(cell as! RepoCell).formatDuration(repo)
		}
	}
	
	// MARK: - Segues
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		Logger.info("Segue = \(segue.identifier)")
		MBProgressHUD.hideHUDForView(self.navigationController!.view, animated: true)
		if segue.identifier == "showDetail" {
			if let indexPath = self.tableView.indexPathForSelectedRow {
				let detail = segue.destinationViewController as! DetailViewController
				detail.repo = repos[indexPath.section]
			} else if sender is RepoCell {
				let detail = segue.destinationViewController as! DetailViewController
				self.navigationController?.interactivePopGestureRecognizer?.delegate = detail
			}
		} else if segue.identifier == "showDetailPeek" {
			if let cell = sender as? RepoCell {
				let detail = segue.destinationViewController as! DetailViewController
				detail.slug = cell.repoSlugLabel.text
				//TODO: replace that (^) with this (v)
//				detail.repo = repos[self.tableView.indexPathForCell(cell)!.section]
			}
		}
	}
	
	// MARK: - Table View
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return repos.count
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("RepoCell", forIndexPath: indexPath) as! RepoCell
		cell.selectionStyle = UITableViewCellSelectionStyle.None
		
		let repo = repos[indexPath.section]
		cell.loadFromRepo(repo)
		
		return cell
	}
	
	override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
		self.repos.moveElementFromPos(sourceIndexPath.section, toPos: destinationIndexPath.section)
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: false)
	}
	
	// MARK: Disable editing
	override func tableView(tableView: UITableView, canFocusRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return false
	}
	
	// MARK: Header/footer settings
	override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return section == 0 ? 7 : 5
	}
	override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 5
	}
	override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		(view as! UITableViewHeaderFooterView).contentView.backgroundColor = tableView.backgroundColor
	}
	override func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
		(view as! UITableViewHeaderFooterView).contentView.backgroundColor = tableView.backgroundColor
	}
}
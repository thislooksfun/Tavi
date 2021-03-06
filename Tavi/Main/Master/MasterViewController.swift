//
//  MasterViewController.swift
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
import MBProgressHUD

/// The main view of the app.
class MasterViewController: PortraitTableViewController
{
	/// The array of repos currently tracked
	var repos = [TravisRepo]()
	
	/// The view to put in the background when no repos have been found
	private var noBuildBackground: UIView!
	/// The view to put in the background when the user isn't authed
	private var notAuthedBackground: UIView!
	
	/// Used by `reload` to track whether or not a reload is already scheduled
	private var reloadScheduled = false
	
	/// The timer used for ticking all the in-progress builds
	private var timer: NSTimer!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		if let refresh = self.refreshControl {
			refresh.addTarget(self, action: #selector(MasterViewController.reloadFromRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
			refresh.superview!.sendSubviewToBack(refresh)
			async() {
				refresh.beginRefreshing()
				refresh.endRefreshing()
			}
		}
		
		self.view.backgroundColor = UIColor(red: (250/255), green: (249/255), blue: (247/255), alpha: 1)
		
		self.constructNoBuilds()
		self.constructNotAuthed()
		
		self.timer = NSTimer(timeInterval: 0.25, target: self, selector: #selector(MasterViewController.timerTick), userInfo: nil, repeats: true)
		NSRunLoop.currentRunLoop().addTimer(self.timer, forMode: NSRunLoopCommonModes)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.tableView.reloadData()
		
		for repo in self.repos {
			repo.setPusherEventCallback(self.onRepoEventForRepo, forObject: self)
		}
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MasterViewController.reload), name: UIApplicationDidBecomeActiveNotification, object: nil)
	}
	
	override func viewDidAppear(animated: Bool)
	{
		super.viewDidAppear(animated)
		
		if (Settings.HasReadDisclaimer.get()) != true {
			DisclaimerController.display()
		}
		
		if self.repos.count == 0 {
			async(cb: self.reload)
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillAppear(animated)
		
		for repo in self.repos {
			repo.removePusherEventCallbackForObject(self)
		}
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	/// Reloads and sorts the information when a repo is updated
	func cellDidLoadFromRepo() {
		let preSort = self.repos
		self.repos.sortInPlace(self.repoSort)
		if self.repos != preSort {
			self.tableView.reloadData()
		}
	}
	
	/// Compares two repositories and determines whether or not they are in the correct order.
	///
	/// - Returns: `true` if they are in the correct order, else `false`
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
	
	/// Updates and re-orders the repository list
	///
	/// Used by `DetailViewController` to tell the main view it
	/// needs to refresh a certain repo
	///
	/// - Parameter newRepo: The repository to update
	func detailRepoDidChange(newRepo: TravisRepo) {
		self.onRepoEventForRepo(newRepo)
	}
	
	/// A wrapper for `reload()` to used by the `UIRefreshControl`,
	/// since its callback needs a `sender` parameter
	func reloadFromRefresh(sender: AnyObject?) {
		reload()
	}
	
	/// A wrapper for `reload_do` to ensure that the connection exists
	/// Used to prevent the screen from darkening repeatly on app re-entry
	func reload() {
		guard !reloadScheduled else { return } //If there is already going to be a reload, don't bother
		reloadScheduled = true
		Connection.checkConnectionAndPerform(reload_do)
	}
	
	/// Reloads all the repositories in the view
	///
	/// - Warning: This should never be called! Use `reload` instead
	///
	/// - Note: This doesn't actually technically reload anything.
	///         It fetches a complete list from the API, and if it is different,
	///         it throws away the old list and replaces it with the new one.
	func reload_do()
	{
		reloadScheduled = false
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
						rp!.setPusherEventCallback(self.onRepoEventForRepo, forObject: self)
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
	
	/// Updates the given repository when its state changes
	///
	/// - Parameter newRepo: The newly updated repository
	func onRepoEventForRepo(newRepo: TravisRepo)
	{
		let (index, repo) = self.repos.findWithPos({ (testRepo) -> Bool in return testRepo.slug == newRepo.slug && testRepo.repoID == newRepo.repoID})
		
		guard index > -1 else { return }
		
		self.repos[index] = newRepo
		
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
	
	/// Assembles the `noBuildBackground` view
	func constructNoBuilds()
	{
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
	
	/// Assembles the `notAuthedBackground` view
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
	
	/// Displays the `noBuildBackground` background
	func showNoBuilds() {
		guard self.tableView.backgroundView != self.noBuildBackground else { return }
		self.hideBackground() {
			self.tableView.backgroundView = self.noBuildBackground
			self.showBackground()
		}
	}
	
	/// Displays the `notAuthedBackground` background
	func showNotAuthed() {
		guard self.tableView.backgroundView != self.notAuthedBackground else { return }
		self.hideBackground() {
			self.tableView.backgroundView = self.notAuthedBackground
			self.showBackground()
		}
	}
	
	/// Displays whatever table background is currently set
	func showBackground() {
		guard let background = self.tableView.backgroundView else { return }
		background.show()
	}
	
	/// Hides whatever table background is currently set
	///
	/// - Parameter done: The closure to execute after the animation finishes
	func hideBackground(done: (() -> Void)? = nil) {
		guard let background = self.tableView.backgroundView else {
			done?()
			return
		}
		background.hide() { (_) in
			done?()
		}
	}
	
	/// Responsibly clears all information from the `repos` table
	func clearTable() {
		Logger.info("Clearing table...")
		while self.repos.count > 0 {
			self.repos.removeFirst().dismiss()
		}
		self.tableView.reloadData()
		Logger.info("Done!")
	}
	
	/// Ticks all the in-progress `RepoCell`s
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
				
				detail.master = self
				detail.repo = repos[indexPath.section]
			} else if sender is RepoCell {
				let detail = segue.destinationViewController as! DetailViewController
				self.navigationController?.interactivePopGestureRecognizer?.delegate = detail
			}
		} else if segue.identifier == "showDetailPeek" {
			if let cell = sender as? RepoCell {
				let detail = segue.destinationViewController as! DetailViewController
				
				detail.master = self
				detail.repo = repos[self.tableView.indexPathForCell(cell)!.section]
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
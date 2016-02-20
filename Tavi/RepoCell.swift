//
//  RepoCell.swift
//  Tavi
//
//  Created by thislooksfun on 12/5/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class RepoCell: UITableViewCell
{
	@IBOutlet var colorBar: UIView!
	
	@IBOutlet var buildStatus: UIImageView!
	@IBOutlet var repoSlugLabel: UILabel!
	@IBOutlet var buildNumberLabel: UILabel!
	@IBOutlet var buildHash: UIImageView!
	@IBOutlet var durationLabel: UILabel!
	@IBOutlet var finishDateLabel: UILabel!
	@IBOutlet var heartIcon: UIImageView!
	
	var isRotating = false
	
	func loadFromRepo(repo: TravisRepo)
	{
		Logger.info(repo.slug)
		self.repoSlugLabel.text = repo.slug
		
		var sideColor: UIColor
		var textColor: UIColor?
		
		if repo.lastBuild == nil {
			self.buildNumberLabel.hidden = true
			self.buildHash.hidden = true
			
			sideColor = TravisAPI.noBuildColor
			textColor = TravisAPI.cancelColor
			self.buildStatus.image = UIImage(named: "icon-no-builds")
		} else {
			self.buildNumberLabel.text = "\(repo.lastBuild!.buildNumber)"
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
		self.repoSlugLabel.textColor = textColor ?? sideColor
		self.buildNumberLabel.textColor = textColor ?? sideColor
		
		formatDuration(repo)
		formatFinishDate(repo.lastBuild?.finishedAt)
		
		self.heartIcon.hidden = !Favorites.isFavorite(repo.slug)
		self.heartIcon.tintColorDidChange()
	}
	

	// MARK: Helper functions
	
	private func startRotating() {
		guard !self.isRotating else { return }
		self.isRotating = true
		self.rotate()
	}
	
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
	
	private func stopRotating() {
		guard self.isRotating else { return }
		self.isRotating = false
		
		UIView.animateWithDuration(0, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
			self.buildStatus.transform = CGAffineTransformMakeRotation(0)
		}, completion: self.rotate)
	}
	
	private func formatDuration(repo: TravisRepo)
	{
		guard let start = repo.lastBuild?.startedAt else {
			self.durationLabel.text = "Duration: -"
			return
		}
		
		var end: NSDate
		if repo.lastBuild?.finishedAt != nil {
			end = repo.lastBuild!.finishedAt!
		} else {
			end = NSDate()
			delay(0.5, cb: { self.formatDuration(repo) })
		}
		
		let comps = start.timeTo(end)
		
		var out = ""
		if comps.year > 0 || comps.month > 0 || comps.weekOfYear > 0 || comps.day > 0 {
			out = "more than 24 hrs"
		} else {
			if comps.hour > 0 {
				if comps.hour == 1 {
					out = "1 hr"
				} else {
					out = "\(comps.hour) hrs \(comps.minute) min \(comps.second) sec"
				}
			} else if comps.minute > 0 {
				out = "\(comps.minute) min \(comps.second) sec"
			} else {
				out = "\(comps.second) sec"
			}
		}
		
		self.durationLabel.text = "Duration: \(out)"
	}
	
	private func formatFinishDate(finishDate: NSDate?)
	{
		guard let date = finishDate else {
			self.finishDateLabel.text = "Finished: -"
			return
		}
		
		let comps = date.timeAgo()
		
		var out = ""
		if comps.year > 0 {
			if comps.year == 1 {
				out = "about a year"
			} else {
				out = "\(comps.year) years"
			}
		} else if comps.month > 0 {
			if comps.month == 1 {
				out = "about a month"
			} else {
				out = "\(comps.month) months"
			}
		} else if comps.weekOfYear > 0 {
			if comps.weekOfYear == 1 {
				out = "about a week"
			} else {
				out = "\(comps.weekOfYear) weeks"
			}
		} else if comps.day > 0 {
			if comps.day == 1 {
				out = "about a day"
			} else {
				out = "\(comps.day) days"
			}
		} else if comps.hour > 0 {
			if comps.hour == 1 {
				out = "about an hour"
			} else {
				out = "\(comps.hour) hours"
			}
		} else if comps.minute > 0 {
			if comps.minute == 1 {
				out = "about a minute"
			} else {
				out = "\(comps.minute) minutes"
			}
		} else {
			out = "less than a minute"
		}
		
		self.finishDateLabel.text =  "Finished: \(out) ago"
	}
}
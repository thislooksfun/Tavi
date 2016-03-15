//
//  AuthHelper.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

class AuthHelper
{
	static func generateAuthString(user: String, pass: String) -> String {
		let userPass = "\(user):\(pass)"
		return "Basic \(userPass.dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions([]))"
	}
	
	static func auth(finished finished: ((Bool) -> Void)? = nil)
	{
		if TravisAPI.authed() {
			return
		} else if GithubAPI.signedIn() {
			TravisAPI.auth() {
				(state) in
				
				switch state {
				case .Success: finished?(true)  // Success!
				case .NeedsGithub: LoginController.openLogin(cb: finished)
				case .NoJson, .Other:
					Logger.warn("Other error")
					finished?(false)
				}
			}
		} else {
			LoginController.openLogin(cb: finished)
		}
	}
}
//
//  AuthHelper.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

/// A simple class to help with authorizations
class AuthHelper
{
	/// Generats an authorization string to use with [Basic auth](https://en.wikipedia.org/wiki/Basic_access_authentication) systems
	///
	/// - Parameters:
	///   - user: The username
	///   - pass: The password
	static func generateAuthString(user: String, pass: String) -> String {
		let userPass = "\(user):\(pass)"
		return "Basic \(userPass.dataUsingEncoding(NSUTF8StringEncoding)!.base64EncodedStringWithOptions([]))"
	}
	
	/// Runs through Tavi's authorization flow
	///
	/// - Parameter finished: The callback to call when the auth flow is finished. Signature: `(success: Bool) -> Void` (Default: `nil`)
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
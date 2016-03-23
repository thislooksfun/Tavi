//
//  AuthHelper.swift
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
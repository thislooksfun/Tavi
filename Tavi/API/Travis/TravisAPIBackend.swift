//
//  TravisAPIBackend.swift
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

/// The class for interacting directly with the [Travis](https://travis-ci.org) API
class TravisAPIBackend: TLFAPIBackend
{
	/// Connects to the API
	///
	/// - Note: If the path given does not start with a forward slash (`/`), one will be prepended
	///
	/// - Parameters:
	///   - path: The relative path to connect to. The path will be appended as follows: `"https://api.travis-ci.org"+path`
	///   - method: The `HTTPMethod` with which to connect
	///   - headers: Any headers to use (Default: `nil`)
	///   - accept: Any parameters to append to the Accept header (Default: `"application/vnd.travis-ci.2+json"`)
	///   - json: Any JSON to connect with (Default: `nil`)
	///   - customHandler: A custom handler to give to the `NSURLSession`
	///   - callback: The callback to use
	static func apiCall(path: String, method: HTTPMethod, headers: [NSObject: AnyObject]? = nil, accept: String = "application/vnd.travis-ci.2+json", json: [NSObject: AnyObject]? = nil, customHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil, callback: (String?, JSON?, NSHTTPURLResponse?) -> Void)
	{
		var useHeaders: [NSObject: AnyObject] = headers ?? [:]
		
		let version = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"]! ?? ""
		useHeaders["User-Agent"] = "Travis/1.6.x Tavi/\(version!)"
		if let authToken = Settings.Travis_Token.get() {
			useHeaders["Authorization"] = "token \(authToken)"
		}
		
		apiCall_internal("https://api.travis-ci.org", path: path, method: method, headers: useHeaders, accept: accept, json: json, customHandler: customHandler, callback: callback)
	}
}
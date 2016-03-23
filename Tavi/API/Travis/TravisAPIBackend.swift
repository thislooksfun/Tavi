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
class TravisAPIBackend
{
	/// Connects to the API
	///
	/// - Note: If the path given does not start with a forward slash (`/`), one will be prepended
	///
	/// - Parameters:
	///   - path: The relative path to connect to. The path will be appended as follows: `"https://api.travis-ci.org"+path`
	///   - method: The `HTTPMethod` with which to connect
	///   - headers: Any headers to use (Default: `nil`)
	///   - json: Any JSON to connect with (Default: `nil`)
	///   - errorCallback: The callback to use if something goes wrong
	///   - callback: The callback to use if nothing goes wrong
	static func apiCall(path: String, method: HTTPMethod, headers: [NSObject: AnyObject]? = nil, json: [NSObject: AnyObject]? = nil, callback: (String?, JSON?, NSHTTPURLResponse?) -> Void)
	{
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.HTTPAdditionalHeaders = headers
		let session = NSURLSession(configuration: config)
		
		var relpath = path
		if relpath.characters.first != "/" {
			relpath = "/"+relpath
		}
		
		let url = NSURL(string: "https://api.travis-ci.org"+relpath)
		
		guard url != nil else {
			callback("url can't be found!", nil, nil)
			return
		}
		
		let request = NSMutableURLRequest(URL: url!)
		
		let version = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"]! ?? ""
		request.HTTPMethod = method.name
		request.setValue("Travis/1.6.x Tavi/\(version!)", forHTTPHeaderField: "User-Agent")
		request.setValue("application/vnd.travis-ci.2+json", forHTTPHeaderField: "Accept")
		if let authToken = Settings.Travis_Token.get() {
			request.setValue("token \(authToken)", forHTTPHeaderField: "Authorization")
		}
		
		
		if json != nil {
			do {
				request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(json!, options: NSJSONWritingOptions.PrettyPrinted)
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			} catch _ {
				callback("Serializing json failed\njson: \(json!)", nil, nil)
				return
			}
		}
		
		let cb = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
			
			guard error == nil else {
				callback("Error: "+error!.localizedDescription, nil, nil)
				return
			}
			
			var parseJSON: JSON?
			do {
				parseJSON = try JSON(data: data!)
			} catch _ {
				parseJSON = nil
			}
			
			guard let httpResponse = response as? NSHTTPURLResponse  else {
				callback("Error: reponse is nil or not an instance of NSHTTPURLResponse", nil, nil)
				return
			}
			
			if parseJSON == nil {
				callback("Error reading JSON:\n\(NSString(data: data!, encoding: NSUTF8StringEncoding)! as String)", nil, nil)
			} else {
				callback(nil, parseJSON!, httpResponse)
			}
		}
		
		let task = session.dataTaskWithRequest(request, completionHandler: cb)
		task.resume()
	}
}
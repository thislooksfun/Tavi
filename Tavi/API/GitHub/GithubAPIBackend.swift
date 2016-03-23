//
//  GithubAPIBackend.swift
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

/// The class for interacting directly with the [GitHub](https://github.com) API
class GithubAPIBackend
{
	/// Connects to the API
	///
	/// - Note: If the path given does not start with a forward slash (`/`), one will be prepended
	///
	/// - Parameters:
	///   - path: The relative path to connect to. The path will be appended as follows: `"https://api.github.com"+path`
	///   - method: The `HTTPMethod` with which to connect
	///   - headers: Any headers to use (Default: `nil`)
	///   - json: Any JSON to connect with (Default: `nil`)
	///   - errorCallback: The callback to use if something goes wrong
	///   - callback: The callback to use if nothing goes wrong
	static func apiCall(path: String, method: HTTPMethod, headers: [NSObject: AnyObject]? = nil, json: [NSObject: AnyObject]? = nil, errorCallback: ((String?) -> Void)?, callback: (JSON, NSHTTPURLResponse) -> Void)
	{
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.HTTPAdditionalHeaders = headers
		let session = NSURLSession(configuration: config)
		
		var relPath = path
		if relPath.characters.first != "/" {
			relPath = "/"+relPath
		}
		
		let url = NSURL(string: "https://api.github.com"+relPath)
		
		guard url != nil else {
			errorCallback?("url can't be found!")
			return
		}
		
		let request: NSMutableURLRequest? = (json == nil) ? nil : NSMutableURLRequest(URL: url!)
		
		if json != nil {
			do {
				request!.HTTPMethod = method.name
				request!.HTTPBody = try NSJSONSerialization.dataWithJSONObject(json!, options: NSJSONWritingOptions.PrettyPrinted)
				request!.setValue("application/json", forHTTPHeaderField: "Accept")
				request!.setValue("application/json", forHTTPHeaderField: "Content-Type")
			} catch _ {
				errorCallback?("Serializing json failed\njson: \(json!)")
				return
			}
		}
		
		let cb = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
			
			guard error == nil else {
				errorCallback?("Error: "+error!.localizedDescription)
				return
			}
			
			var parseJSON: JSON?
			do {
				parseJSON = try JSON(data: data!)
			} catch _ {
				parseJSON = nil
			}
			
			guard let httpResponse = response as? NSHTTPURLResponse  else {
				errorCallback?("Error: reponse is nil or not an instance of NSHTTPURLResponse")
				return
			}
			
			if parseJSON == nil {
				errorCallback?("Error reading JSON:\n\(NSString(data: data!, encoding: NSUTF8StringEncoding)! as String)")
			} else {
				callback(parseJSON!, httpResponse)
			}
		}
		
		let task = (request == nil) ? session.dataTaskWithURL(url!, completionHandler: cb) : session.dataTaskWithRequest(request!, completionHandler: cb)
		task.resume()
	}
}
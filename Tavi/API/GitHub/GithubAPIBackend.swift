//
//  GithubAPIBackend.swift
//  Tavi
//
//  Created by thislooksfun on 7/8/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
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
	static func apiCall(var path: String, method: HTTPMethod, headers: [NSObject: AnyObject]? = nil, json: [NSObject: AnyObject]? = nil, errorCallback: ((String?) -> Void)?, callback: (JSON, NSHTTPURLResponse) -> Void)
	{
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.HTTPAdditionalHeaders = headers
		let session = NSURLSession(configuration: config)
		
		if path.characters.first != "/" {
			path = "/"+path
		}
		
		let url = NSURL(string: "https://api.github.com"+path)
		
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
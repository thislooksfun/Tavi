//
//  GithubAPIBackend.swift
//  Tavi
//
//  Created by thislooksfun on 7/8/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class GithubAPIBackend
{
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
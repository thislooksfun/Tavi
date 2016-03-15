//
//  TravisAPIBackend.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import UIKit

class TravisAPIBackend
{
	static func apiCall(var path: String, method: HTTPMethod, headers: [NSObject: AnyObject]? = nil, json: [NSObject: AnyObject]? = nil, callback: (String?, JSON?, NSHTTPURLResponse?) -> Void)
	{
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.HTTPAdditionalHeaders = headers
		let session = NSURLSession(configuration: config)
		
		if path.characters.first != "/" {
			path = "/"+path
		}
		
		let url = NSURL(string: "https://api.travis-ci.org"+path)
		
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
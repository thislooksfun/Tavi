//
//  TLFAPIBackend.swift
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

import Foundation

protocol TLFAPIBackend
{
	static func apiCall(path: String, method: HTTPMethod, headers: [NSObject: AnyObject]?, accept: String, json: [NSObject: AnyObject]?, customHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)?, callback: (String?, JSON?, NSHTTPURLResponse?) -> Void)
}

/// Add the apiCall_internal function
extension TLFAPIBackend
{
	/// Connects to an API and checks whether or not there is an internet connection
	///
	/// - Note: Whether or not `apiURL` ends with a forward slash doesn't matter
	/// - Note: Whether or not `path` starts with a forward slash doesn't matter
	///
	/// - Parameters:
	///   - apiURL: The base URL the api uses
	///   - path: The relative path to connect to. The path will be appended as follows: `{apiURL}/{path}`
	///   - method: The `HTTPMethod` with which to connect
	///   - headers: Any headers to use
	///   - accept: Any parameters to append to the Accept header
	///   - json: Any JSON to connect with
	///   - customHandler: A custom handler to give to the `NSURLSession`
	///   - callback: The callback to use
	static final func apiCall_internal(apiURL: String, path: String, method: HTTPMethod, headers: [NSObject: AnyObject]?, accept: String, json: [NSObject: AnyObject]?, customHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)?, callback: (String?, JSON?, NSHTTPURLResponse?) -> Void)
	{
		Connection.checkConnectionAndPerform() {
			self.apiCall_internal_do(apiURL, path: path, method: method, headers: headers, accept: accept, json: json, customHandler: customHandler, callback: callback)
		}
	}
	
	/// Actually performs the connection to the API
	///
	/// - Note: Whether or not `apiURL` ends with a forward slash doesn't matter
	/// - Note: Whether or not `path` starts with a forward slash doesn't matter
	///
	/// - Parameters:
	///   - apiURL: The base URL the api uses
	///   - path: The relative path to connect to. The path will be appended as follows: `{apiURL}/{path}`
	///   - method: The `HTTPMethod` with which to connect
	///   - headers: Any headers to use
	///   - accept: Any parameters to append to the Accept header
	///   - json: Any JSON to connect with
	///   - customHandler: A custom handler to give to the `NSURLSession`
	///   - callback: The callback to use
	private static final func apiCall_internal_do(apiURL: String, path: String, method: HTTPMethod, headers: [NSObject: AnyObject]?, accept: String, json: [NSObject: AnyObject]?, customHandler: ((NSData?, NSURLResponse?, NSError?) -> Void)?, callback: (String?, JSON?, NSHTTPURLResponse?) -> Void)
	{
		Logger.info("apiCall_internal_do")
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.HTTPAdditionalHeaders = headers
		let session = NSURLSession(configuration: config)
		
		var baseURL = apiURL
		// If the base url ends with a forward slash, remove it
		if baseURL.characters.last == "/" {
			baseURL = baseURL.substringToIndex(baseURL.endIndex.predecessor())
		}
		
		var relPath = path
		// If the relative path starts with a forward slash, remove it
		if relPath.characters.first == "/" {
			relPath = relPath.substringFromIndex(relPath.startIndex.successor())
		}
		
		let url = NSURL(string: "\(baseURL)/\(relPath)")
		
		guard url != nil else {
			callback("url can't be found!", nil, nil)
			return
		}
		
		let request = NSMutableURLRequest(URL: url!)
		request.HTTPMethod = method.name
		request.setValue(accept, forHTTPHeaderField: "Accept")
		
		if json != nil {
			do {
				request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(json!, options: NSJSONWritingOptions.PrettyPrinted)
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			} catch _ {
				callback("Serializing json failed\njson: \(json!)", nil, nil)
				return
			}
		}
		
		let cb = customHandler != nil ? customHandler! : { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
			
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
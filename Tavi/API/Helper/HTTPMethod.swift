//
//  HTTPMethod.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

/// A collection of all the HTTP connection methods
struct HTTPMethod
{
	/// A POST request
	static let POST = HTTPMethod(name: "POST")
	
	/// A PUT request
	static let PUT = HTTPMethod(name: "PUT")
	
	/// A GET request
	static let GET = HTTPMethod(name: "GET")
	
	/// A DELETE request
	static let DELETE = HTTPMethod(name: "DELETE")
	
	
	/// The name of the method
	let name: String
	
	/// Initalize the method
	///
	/// - Parameter name: The name of the method
	private init(name: String) {
		self.name = name
	}
}
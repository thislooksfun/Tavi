//
//  HTTPMethod.swift
//  Tavi
//
//  Created by thislooksfun on 12/4/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

struct HTTPMethod {
	static let POST = HTTPMethod(name: "POST")
	static let PUT = HTTPMethod(name: "PUT")
	static let GET = HTTPMethod(name: "GET")
	static let DELETE = HTTPMethod(name: "DELETE")
	
	let name: String
	private init(name: String) {
		self.name = name
	}
}
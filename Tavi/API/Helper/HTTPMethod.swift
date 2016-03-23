//
//  HTTPMethod.swift
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
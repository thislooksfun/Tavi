//
//  Connection.swift
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
import SystemConfiguration

/// A simple way to check if the device has internet
class Connection
{
	private static var callQueue: [() -> Void] = []
	
	//TODO: Remove this once testing is done
	static var x = 0
	
	/// Please use `checkConnection` instead
	///
	/// Checks whether or not there is an internet connection
	///
	/// - Returns: `true` if there is an internet connection, otherwise `false`
	static func connectedToNetwork() -> Bool {
		
		var zeroAddress = sockaddr_in()
		zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
		zeroAddress.sin_family = sa_family_t(AF_INET)
		
		guard let defaultRouteReachability = withUnsafePointer(&zeroAddress, {
			SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
		}) else {
			return false
		}
		
		var flags : SCNetworkReachabilityFlags = []
		if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
			return false
		}
		
		let isReachable = flags.contains(.Reachable)
		let needsConnection = flags.contains(.ConnectionRequired)
		
		return (isReachable && !needsConnection) && (++x % 9 != 0)
	}
	
	/// Whether or not the no connection view is being displayed
	private static var isDisplayingNoConnection = false
	
	/// Checks whether or not there is an internet connection\
	/// and displays the no connection popup if it can't connect
	static func checkConnection() -> Bool
	{
		// We already know there's no connection, don't try again
		guard !isDisplayingNoConnection else { return false }
		
		// There is a network connection, look no farther!
		if connectedToNetwork() { return true }
		
		// We are not connected
		self.isDisplayingNoConnection = true
		
		NoConnectionController.display(cb: { (_) -> Void in
			self.isDisplayingNoConnection = false
			for fun in callQueue {
				fun()
			}
		})
		return false
	}
	
	/// Checks whether or not there is an internet connection, same as `checkConnection:`\
	/// but also adds the given closure to a queue to be executed after the connection is regained
	///
	/// - Parameter fun: The closure to execute only when there is an internet connection
	static func checkConnectionAndPerform(fun: () -> Void)
	{
		if checkConnection() {
			// There is a connection, just execute it
			fun()
		} else {
			// No connection, store the request until it comes back
			callQueue.append(fun)
		}
	}
}
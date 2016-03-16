//
//  Connection.swift
//  Tavi
//
//  Created by thislooksfun on 7/8/15.
//  Copyright © 2015 thislooksfun. All rights reserved.
//

import Foundation
import SystemConfiguration

class Connection
{
	static var x = 0
	
	//TODO: add this in many places
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
		
		x++
		return (isReachable && !needsConnection) && (x % 3 != 0)
	}
}
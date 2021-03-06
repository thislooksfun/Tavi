//
//  Pusher.swift
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

import Pusher

//TODO: Figure out how to automatically reconnect when the connection times out (maybe implement PTPusherConnectionDelegate?)

/// A simple class for interacting with [libPusher](https://github.com/lukeredpath/libPusher)
class Pusher: NSObject, PTPusherDelegate
{
	/// The way to interact with the `Pusher` class
	static private var instance: Pusher {
		get {
			if internal_instance == nil {
				start()
			}
			return internal_instance!
		}
	}
	
	/// The internally stored instance variable
	static private var internal_instance: Pusher?
	
	/// The `PTPusher` client
	///
	/// This is a forced optional `!` only because
	/// the compiler really doesn't like the way I've
	/// set the initalizer up.
	var client: PTPusher!
	
	/// The internal create method
	///
	/// - Parameter key: The key to initalize `PTPusher` with
	private init(key: String) {
		super.init()
		
		self.client = PTPusher(key: key, delegate: self, encrypted: true)
		self.client.connect()
	}
	
	/// Fires up the instance, if it doesn't already exist
	static func start() {
		guard internal_instance == nil else { return } //Don't try to start twice
		
		internal_instance = Pusher(key: "5df8ac576dcccf4fd076")
		
		TravisAPI.getConfig()
		{ (authState, json) in
			if authState == .Success {
				Logger.info(json!)
//				instance = Pusher(key: json!.getJson("config")!.getJson("pusher")!.getString("key")!)
			} else {
				Logger.error("Oh dear")
			}
		}
	}
	
	/// Bind to every event fired a specific channel
	///
	/// - Parameters:
	///   - chann: The channel to bind to
	///   - handler: The closure to call when an event fires
	///
	/// - Returns: The `NSObjectProtocol` returned by `NSNotificationCenter`
	static func bindToAllEventsForChannel(chann: String, withHandler handler: (PTPusherEvent?) -> Void) -> NSObjectProtocol {
		let channel = instance.client.subscribeToChannelNamed(chann)
		
		return NSNotificationCenter.defaultCenter().addObserverForName(PTPusherEventReceivedNotification, object: channel, queue: nil, usingBlock: blockForHandler(handler))
	}
	
	/// Binds a channel for a certain list of events
	///
	/// - Parameters:
	///   - chann: The channel to bind to
	///   - events: The list of event names to bind to
	///   - handler: The closure to call when an event fires
	///
	/// - Returns: An `Array` of `PTPusherEventBinding`s for the bound events
	static func bindToChannel(chann: String, forEvents events: [String], withHandler handler: (PTPusherEvent!) -> Void) -> [PTPusherEventBinding] {
		guard events.count > 0 else { return [] }
		
		var out = [PTPusherEventBinding]()
		let channel = instance.client.subscribeToChannelNamed(chann)
		
		for event in events {
			out.append(channel.bindToEventNamed(event, handleWithBlock: handler))
		}
		
		return out
	}
	
	/// Binds a channel for a specific event
	///
	/// - Parameters:
	///   - chann: The channel to bind to
	///   - event: The event name to bind to
	///   - handler: The closure to call when the event fires
	///
	/// - Returns: The `PTPusherEventBinding` for the bound event
	static func bindToChannel(chann: String, forEvent event: String, withHandler handler: (PTPusherEvent!) -> Void) -> PTPusherEventBinding {
		let channel = instance.client.subscribeToChannelNamed(chann)
		return channel.bindToEventNamed(event, handleWithBlock: handler)
	}
	
	/// Unbinds a channel for all events
	///
	/// - Parameters:
	///   - chann: The channel to unbind from
	///   - binding: The `NSObjectProtocol` to unbind. Given from `bindToAllEventsForChannel`
	static func unbindChannel(chann: String, withBinding binding: NSObjectProtocol? = nil) {
		if binding != nil {
			NSNotificationCenter.defaultCenter().removeObserver(binding!)
		}
		
		let channel = instance.client.channelNamed(chann)
		channel?.unsubscribe()
	}
	
	/// Unbinds an event
	///
	/// - Parameter bind: The `PTPusherEventBinding` to unbind. Given from `bindToChannel`
	static func unbindEvent(bind: PTPusherEventBinding?) {
		instance.client.removeBinding(bind)
	}
	
	/// Unbinds all bindings not bound through `bindToAllEventsForChannel`
	static func unbindAll() {
		instance.client.removeAllBindings()
	}
	
	/// Connects `PTPusher` to the Pusher servers
	static func connect() {
		instance.client.connect()
	}
	
	/// Connects `PTPusher` from the Pusher servers
	static func disconnect() {
		instance.client.disconnect()
	}
	
	/// Creates a block to unwrap the given `NSNotification` into a `PTPusherEvent` for event handling
	///
	/// - Parameter handler: the handler to wrap
	///
	/// - Returns: A closure wrapping `handler`
	private static func blockForHandler(handler: (PTPusherEvent?) -> Void) -> (NSNotification?) -> Void {
		return { (note: NSNotification?) in
			handler(note?.userInfo?[PTPusherEventUserInfoKey] as? PTPusherEvent)
		}
	}
}
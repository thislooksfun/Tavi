//
//  Pusher.swift
//  Tavi
//
//  Created by thislooksfun on 2/2/16.
//  Copyright © 2016 thislooksfun. All rights reserved.
//

class Pusher: NSObject, PTPusherDelegate
{
	static private var instance: Pusher {
		get {
			if internal_instance == nil {
				start()
			}
			return internal_instance!
		}
	}
	static private var internal_instance: Pusher?
	static private var channels = [String: PTPusherChannel]()
	
	var client: PTPusher!
	
	private init(key: String) {
		super.init()
		self.client = PTPusher(key: key, delegate: self, encrypted: true)
		self.client.connect()
	}
	
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
	
	static func bindToAllEventsForChannel(chann: String, withHandler handler: (PTPusherEvent?) -> Void) -> NSObjectProtocol{
		let channel = instance.client.subscribeToChannelNamed(chann)
		
		return NSNotificationCenter.defaultCenter().addObserverForName(PTPusherEventReceivedNotification, object: channel, queue: nil, usingBlock: blockForHandler(handler))
	}
	static func bindToChannel(chann: String, forEvents events: [String], withHandler handler: (PTPusherEvent!) -> Void) -> [PTPusherEventBinding] {
		guard events.count > 0 else { return [] }
		
		var out = [PTPusherEventBinding]()
		let channel = instance.client.subscribeToChannelNamed(chann)
		
		for event in events {
			out.append(channel.bindToEventNamed(event, handleWithBlock: handler))
		}
		
		return out
	}
	static func bindToChannel(chann: String, forEvent event: String, withHandler handler: (PTPusherEvent!) -> Void) -> PTPusherEventBinding {
		let channel = instance.client.subscribeToChannelNamed(chann)
		return channel.bindToEventNamed(event, handleWithBlock: handler)
	}
	
	static func unbindChannel(chann: String, withBinding binding: NSObjectProtocol? = nil) {
		if binding != nil {
			NSNotificationCenter.defaultCenter().removeObserver(binding!)
		}
		
		let channel = instance.client.channelNamed(chann)
		channel.unsubscribe()
	}
	
	static func unbindEvent(bind: PTPusherEventBinding?) {
		instance.client.removeBinding(bind)
	}
	
	static func unbindAll() {
		instance.client.removeAllBindings()
	}
	
	static func connect() {
		instance.client.connect()
	}
	
	static func disconnect() {
		instance.client.disconnect()
	}
	
	private static func blockForHandler(handler: (PTPusherEvent?) -> Void) -> (NSNotification?) -> Void {
		return { (note: NSNotification?) in
			handler(note?.userInfo?[PTPusherEventUserInfoKey] as? PTPusherEvent)
		}
	}
}
//
//  MMLocalNotifications.swift
//
//  Created by Andrey K. on 12/09/16.
//
//

import Foundation

struct LocalNotificationKeys {
	static let pushPayload = "com.mobile-messaging.ln.k.pushPayload"
	static let createdDate = "com.mobile-messaging.ln.k.createdDate"
}

class MMLocalNotification {
	class func presentLocalNotification(with message: MTMessage) {
		guard !message.isSilent || (message is MMGeoMessage) else {
			return
		}
		
		UIApplication.shared.presentLocalNotificationNow(localNotification(with: message))
	}
	
	class func localNotification(with message: MTMessage) -> UILocalNotification {
		let localNotification = UILocalNotification()
		localNotification.userInfo = [LocalNotificationKeys.pushPayload: message.originalPayload,
		                              LocalNotificationKeys.createdDate: message.createdDate]
		localNotification.alertBody = message.text
		localNotification.soundName = message.sound
		return localNotification
	}
}

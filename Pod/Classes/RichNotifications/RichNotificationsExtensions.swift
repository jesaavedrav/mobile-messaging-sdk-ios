//
//  RichNotificationsExtensions.swift
//
//  Created by Andrey Kadochnikov on 23/05/2017.
//
//

import Foundation
import UserNotifications

extension MTMessage {
	
	static let attachmentsUrlSessionManager = MM_AFHTTPSessionManager(sessionConfiguration: MobileMessaging.urlSessionConfiguration)
	
	@discardableResult func downloadImageAttachment(completion: @escaping (URL?, Error?) -> Void) -> URLSessionDownloadTask? {
		guard let contentUrlString = contentUrl, let contentURL = URL.init(string: contentUrlString) else {
			completion(nil, nil)
			return nil
		}

		let destination: ((URL, URLResponse) -> URL) = { url, _ -> URL in
			let tempFolderUrl = URL.init(fileURLWithPath: NSTemporaryDirectory())
			var destinationFolderURL = tempFolderUrl.appendingPathComponent("com.mobile-messaging.rich-notifications-attachments", isDirectory: true)
			
			var isDir: ObjCBool = true
			if !FileManager.default.fileExists(atPath: destinationFolderURL.path, isDirectory: &isDir) {
				do {
					try FileManager.default.createDirectory(at: destinationFolderURL, withIntermediateDirectories: true, attributes: nil)
				} catch _ {
					destinationFolderURL = tempFolderUrl
				}
			}
			return destinationFolderURL.appendingPathComponent(String(url.absoluteString.hashValue) + "." + contentURL.pathExtension)
		}
		MTMessage.attachmentsUrlSessionManager.session.configuration.timeoutIntervalForResource = 20 //this will help to avoid too long downloading task (in case of big pictures)
		MTMessage.attachmentsUrlSessionManager.session.configuration.timeoutIntervalForRequest = 20
		let task = MTMessage.attachmentsUrlSessionManager.downloadTask(with: URLRequest(url: contentURL), progress: nil, destination: destination) { (urlResponse, url, error) in
			completion(url, error)
		}
		task.resume()
		return task
	}
}

@available(iOS 10.0, *)
final public class MobileMessagingNotificationServiceExtension: NSObject {
	
	public class func startWithApplicationCode(_ code: String, appGroupId: String) {
		if sharedInstance == nil {
			sharedInstance = MobileMessagingNotificationServiceExtension(appCode: code, appGroupId: appGroupId)
		}
		sharedInstance?.sharedNotificationExtensionStorage = DefaultSharedDataStorage(applicationCode: code, appGroupId: appGroupId)
	}
	
	public class func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
		guard let sharedInstance = sharedInstance, let mtMessage = MTMessage(payload: request.content.userInfo, createdDate: Date()) else
		{
			contentHandler(request.content)
			return
		}
		
		sharedInstance.reportDelivery(mtMessage) { result in
			sharedInstance.persistMessage(mtMessage, isDelivered: result.error == nil)
		}
		
		sharedInstance.currentTask = mtMessage.downloadImageAttachment { (url, error) in
			guard let url = url,
				let mContent = (request.content.mutableCopy() as? UNMutableNotificationContent),
				let attachment = try? UNNotificationAttachment(identifier: String(url.absoluteString.hash), url: url, options: nil) else
			{
				contentHandler(request.content)
				return
			}
			
			mContent.attachments = [attachment]
			
			let result: UNNotificationContent
			if let contentWithAttach = mContent.copy() as? UNNotificationContent {
				result = contentWithAttach
			} else {
				result = request.content
			}
			contentHandler(result)
		}
	}
	
	public class func serviceExtensionTimeWillExpire() {
		sharedInstance?.currentTask?.cancel()
	}
	
	//MARK: Internal
	static var sharedInstance: MobileMessagingNotificationServiceExtension?
	private init(appCode: String, appGroupId: String) {
		self.applicationCode = appCode
		self.appGroupId = appGroupId
	}
	
	private func reportDelivery(_ message: MTMessage, completion: @escaping (Result<DeliveryReportResponse>) -> Void) {
		deliveryReporter.report(messageIds: [message.messageId], completion: completion)
	}
	
	private func persistMessage(_ message: MTMessage, isDelivered: Bool) {
		sharedNotificationExtensionStorage?.save(message: message, isDelivered: isDelivered)
	}
	
	let appGroupId: String
	let applicationCode: String
	let remoteAPIBaseURL = APIValues.prodBaseURLString
	var currentTask: URLSessionDownloadTask?
	var sharedNotificationExtensionStorage: AppGroupMessageStorage?
	lazy var deliveryReporter: DeliveryReporting! = DeliveryReporter(applicationCode: self.applicationCode, baseUrl: self.remoteAPIBaseURL)
}

protocol DeliveryReporting {
	init(applicationCode: String, baseUrl: String)
	func report(messageIds: [String], completion: @escaping (Result<DeliveryReportResponse>) -> Void)
}

class DeliveryReporter: DeliveryReporting {
	let applicationCode: String, baseUrl: String
	
	required init(applicationCode: String, baseUrl: String) {
		self.applicationCode = applicationCode
		self.baseUrl = baseUrl
	}
	
	func report(messageIds: [String], completion: @escaping (Result<DeliveryReportResponse>) -> Void) {
		guard let dlr = DeliveryReportRequest(dlrIds: messageIds) else {
			completion(Result.Cancel)
			return
		}
		dlr.responseObject(applicationCode: applicationCode, baseURL: baseUrl, completion: completion)
	}
}

protocol AppGroupMessageStorage {
	init?(applicationCode: String, appGroupId: String)
	func save(message: MTMessage, isDelivered: Bool)
	func retrieveMessages() -> [MTMessage]
	func cleanupMessages()
}

@available(iOS 10.0, *)
class DefaultSharedDataStorage: AppGroupMessageStorage {
	let applicationCode: String
	let appGroupId: String
	required init?(applicationCode: String, appGroupId: String) {
		self.appGroupId = appGroupId
		self.applicationCode = applicationCode
	}
	
	func save(message: MTMessage, isDelivered: Bool) {
		guard let ud = UserDefaults.init(suiteName: appGroupId) else {
			return
		}
		var savedMessageDicts = ud.object(forKey: applicationCode) as? [StringKeyPayload] ?? []
		savedMessageDicts.append(["p": message.originalPayload, "d": message.createdDate, "dlr": isDelivered])
		ud.set(savedMessageDicts, forKey: applicationCode)
		ud.synchronize()
	}
	
	func retrieveMessages() -> [MTMessage] {
		guard let ud = UserDefaults.init(suiteName: appGroupId), let messageDataDicts = ud.array(forKey: applicationCode) as? [StringKeyPayload] else
		{
			return []
		}
		let messages = messageDataDicts.flatMap({ messageDataTuple -> MTMessage? in
			guard let payload = messageDataTuple["p"] as? StringKeyPayload, let date = messageDataTuple["d"] as? Date, let dlrSent =  messageDataTuple["dlr"] as? Bool else {
				return nil
			}
			let newMessage = MTMessage(payload: payload, createdDate: date)
			newMessage?.isDeliveryReportSent = dlrSent
			return newMessage
		})
		return messages
	}
	
	func cleanupMessages() {
		guard let ud = UserDefaults.init(suiteName: appGroupId) else {
			return
		}
		ud.removeObject(forKey: applicationCode)
	}
}

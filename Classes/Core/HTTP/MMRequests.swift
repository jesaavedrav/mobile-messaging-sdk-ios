//
//  MMRequests.swift
//  MobileMessaging
//
//  Created by Andrey K. on 23/02/16.
//

enum APIPath: String {
	case SeenMessages = "/mobile/1/messages/seen"
	case SyncMessages = "/mobile/5/messages"
	case MOMessage = "/mobile/1/messages/mo"
	case LibraryVersion = "/mobile/3/version"
	case GeoEventsReports = "/mobile/4/geo/event"
	case DeliveryReport = "/mobile/1/messages/deliveryreport"

	case AppInstancePersonalize = "/mobile/1/appinstance/{pushRegistrationId}/personalize"
	case AppInstanceDepersonalize = "/mobile/1/appinstance/{pushRegistrationId}/depersonalize"
	case AppInstanceUser_CRUD = "/mobile/1/appinstance/{pushRegistrationId}/user"
	case AppInstance_xRUD = "/mobile/1/appinstance/{pushRegistrationId}"
	case AppInstance_Cxxx = "/mobile/1/appinstance"
	case UserSession = "/mobile/1/appinstance/{pushRegistrationId}/user/events/session"
	case CustomEvents = "/mobile/1/appinstance/{pushRegistrationId}/user/events/custom"
	
	case ChatWidget = "/mobile/1/chat/widget"
}

class SeenStatusSendingRequest: PostRequest {
	typealias ResponseType = EmptyResponse

	init(applicationCode: String, pushRegistrationId: String?, body: RequestBody) {
		super.init(applicationCode: applicationCode, path: .SeenMessages, pushRegistrationId: pushRegistrationId, body: body)
	}
}

class LibraryVersionRequest: GetRequest {
	typealias ResponseType = LibraryVersionResponse

	init(applicationCode: String, pushRegistrationId: String?) {
		super.init(applicationCode: applicationCode, path: .LibraryVersion, pushRegistrationId: pushRegistrationId, parameters: [Consts.PushRegistration.platform: Consts.APIValues.platformType])
	}
}

class MessagesSyncRequest: PostRequest {
	typealias ResponseType = MessagesSyncResponse

	init(applicationCode: String, pushRegistrationId: String, body: RequestBody) {
		super.init(applicationCode: applicationCode, path: .SyncMessages, pushRegistrationId: pushRegistrationId, body: body, parameters: {
			var params = RequestParameters()
			params[Consts.PushRegistration.platform] = Consts.APIValues.platformType
			return params
		}())
	}
}

class DeliveryReportRequest: PostRequest {
	typealias ResponseType = EmptyResponse

	init(applicationCode: String, body: RequestBody) {
		super.init(applicationCode: applicationCode, path: .DeliveryReport, body: body)
	}
}

class MOMessageSendingRequest: PostRequest {
	typealias ResponseType = MOMessageSendingResponse

	init(applicationCode: String, pushRegistrationId: String, body: RequestBody) {
		super.init(applicationCode: applicationCode, path: .MOMessage, pushRegistrationId: pushRegistrationId, body: body, parameters: [Consts.PushRegistration.platform : Consts.APIValues.platformType])
	}
}

class PostCustomEvent: PostRequest {
	typealias ResponseType = EmptyResponse

	init(applicationCode: String, pushRegistrationId: String, validate: Bool, requestBody: RequestBody?) {
		super.init(applicationCode: applicationCode, path: .CustomEvents, pushRegistrationId: pushRegistrationId, body: requestBody, parameters: ["validate": validate], pathParameters: ["{pushRegistrationId}": pushRegistrationId])
	}
}

class PostUserSession: PostRequest {
	typealias ResponseType = EmptyResponse

	init(applicationCode: String, pushRegistrationId: String, requestBody: RequestBody?) {
		super.init(applicationCode: applicationCode, path: .UserSession, pushRegistrationId: pushRegistrationId, body: requestBody, pathParameters: ["{pushRegistrationId}": pushRegistrationId])
	}
}

class GetInstance: GetRequest {
	typealias ResponseType = Installation

	init(applicationCode: String, pushRegistrationId: String, returnPushServiceToken: Bool) {
		super.init(applicationCode: applicationCode, path: .AppInstance_xRUD, pushRegistrationId: pushRegistrationId, parameters: ["rt": returnPushServiceToken], pathParameters: ["{pushRegistrationId}": pushRegistrationId])
	}
}

class PatchInstance: PatchRequest {
	typealias ResponseType = EmptyResponse

	init?(applicationCode: String, authPushRegistrationId: String, refPushRegistrationId: String, body: RequestBody, returnPushServiceToken: Bool) {
		super.init(applicationCode: applicationCode, path: .AppInstance_xRUD, pushRegistrationId: authPushRegistrationId, body: body, parameters: ["rt": returnPushServiceToken], pathParameters: ["{pushRegistrationId}": refPushRegistrationId])
		if self.body?.isEmpty ?? true {
			return nil
		}
	}
}

class PostInstance: PostRequest {
	typealias ResponseType = Installation

	init?(applicationCode: String, body: RequestBody, returnPushServiceToken: Bool) {
		super.init(applicationCode: applicationCode, path: .AppInstance_Cxxx, body: body, parameters: ["rt": returnPushServiceToken])
		if self.body?.isEmpty ?? true {
			return nil
		}
	}
}

class DeleteInstance: DeleteRequest {
	typealias ResponseType = EmptyResponse

	init(applicationCode: String, pushRegistrationId: String, expiredPushRegistrationId: String) {
		super.init(applicationCode: applicationCode, path: .AppInstance_xRUD, pushRegistrationId: pushRegistrationId, pathParameters: ["{pushRegistrationId}": expiredPushRegistrationId])
	}
}

class GetUser: GetRequest {
	typealias ResponseType = User

	init(applicationCode: String, pushRegistrationId: String, returnInstance: Bool, returnPushServiceToken: Bool) {
		super.init(applicationCode: applicationCode, path: .AppInstanceUser_CRUD, pushRegistrationId: pushRegistrationId, parameters: ["rt": returnPushServiceToken, "ri": returnInstance], pathParameters: ["{pushRegistrationId}": pushRegistrationId])
	}
}

class PatchUser: PatchRequest {
	typealias ResponseType = EmptyResponse

	init?(applicationCode: String, pushRegistrationId: String, body: RequestBody, returnInstance: Bool, returnPushServiceToken: Bool) {
		super.init(applicationCode: applicationCode, path: .AppInstanceUser_CRUD, pushRegistrationId: pushRegistrationId, body: body, parameters: ["rt": returnPushServiceToken, "ri": returnInstance], pathParameters: ["{pushRegistrationId}": pushRegistrationId])
		if self.body?.isEmpty ?? true {
			return nil
		}
	}
}

class PostDepersonalize: PostRequest {
	typealias ResponseType = EmptyResponse

	init(applicationCode: String, pushRegistrationId: String, pushRegistrationIdToDepersonalize: String) {
		super.init(applicationCode: applicationCode, path: .AppInstanceDepersonalize, pushRegistrationId: pushRegistrationId, pathParameters: ["{pushRegistrationId}": pushRegistrationIdToDepersonalize])
	}
}

class PostPersonalize: PostRequest {
	typealias ResponseType = User

	init(applicationCode: String, pushRegistrationId: String, body: RequestBody, forceDepersonalize: Bool) {
		super.init(applicationCode: applicationCode, path: .AppInstancePersonalize, pushRegistrationId: pushRegistrationId, body: body, parameters: ["forceDepersonalize": forceDepersonalize], pathParameters: ["{pushRegistrationId}": pushRegistrationId])
	}
}


//MARK: - Base

typealias RequestBody = [String: Any]
typealias RequestParameters = [String: Any]

class RequestData {
	init(applicationCode: String, method: HTTPMethod, path: APIPath, pushRegistrationId: String? = nil, body: RequestBody? = nil, parameters: RequestParameters? = nil, pathParameters: [String: String]? = nil) {
		self.applicationCode = applicationCode
		self.method = method
		self.path = path
		self.pushRegistrationId = pushRegistrationId
		self.body = body
		self.parameters = parameters
		self.pathParameters = pathParameters
	}
	let applicationCode: String
	let pushRegistrationId: String?
	let method: HTTPMethod
	let path: APIPath

	var headers: HTTPHeaders? {
		var headers: HTTPHeaders = [:]
		headers["Authorization"] = "App \(self.applicationCode)"
		headers["applicationcode"] = calculateAppCodeHash(self.applicationCode)
		headers["User-Agent"] = MobileMessaging.userAgent.currentUserAgentString
		headers["foreground"] = String(MobileMessaging.application.isInForegroundState)
		headers["pushregistrationid"] = self.pushRegistrationId
		headers["sessionId"] = MobileMessaging.sharedInstance?.userSessionService.currentSessionId
		headers["Accept"] = "application/json"
		headers["Content-Type"] = "application/json"
		headers["installationid"] = MobileMessaging.sharedInstance?.installationService?.getUniversalInstallationId()
		return headers
	}
	let body: RequestBody?
	let parameters: RequestParameters?
	let pathParameters: [String: String]?

	var resolvedPath: String {
		var ret: String = path.rawValue
		pathParameters?.forEach { (pathParameterName, pathParameterValue) in
			ret = ret.replacingOccurrences(of: pathParameterName, with: pathParameterValue)
		}
		return ret
	}
}

class GetRequest: RequestData {
	init(applicationCode: String, path: APIPath, pushRegistrationId: String? = nil, body: RequestBody? = nil, parameters: RequestParameters? = nil, pathParameters: [String: String]? = nil) {
		super.init(applicationCode: applicationCode, method: .get, path: path, pushRegistrationId: pushRegistrationId, body: body, parameters: parameters, pathParameters: pathParameters)
	}
}

class PostRequest: RequestData {
	init(applicationCode: String, path: APIPath, pushRegistrationId: String? = nil, body: RequestBody? = nil, parameters: RequestParameters? = nil, pathParameters: [String: String]? = nil) {
		super.init(applicationCode: applicationCode, method: .post, path: path, pushRegistrationId: pushRegistrationId, body: body, parameters: parameters, pathParameters: pathParameters)
	}
}

class DeleteRequest: RequestData {
	init(applicationCode: String, path: APIPath, pushRegistrationId: String? = nil, body: RequestBody? = nil, parameters: RequestParameters? = nil, pathParameters: [String: String]? = nil) {
		super.init(applicationCode: applicationCode, method: .delete, path: path, pushRegistrationId: pushRegistrationId, body: body, parameters: parameters, pathParameters: pathParameters)
	}
}

class PutRequest: RequestData {
	init(applicationCode: String, path: APIPath, pushRegistrationId: String? = nil, body: RequestBody? = nil, parameters: RequestParameters? = nil, pathParameters: [String: String]? = nil) {
		super.init(applicationCode: applicationCode, method: .put, path: path, pushRegistrationId: pushRegistrationId, body: body, parameters: parameters, pathParameters: pathParameters)
	}
}

class PatchRequest: RequestData {
	init(applicationCode: String, path: APIPath, pushRegistrationId: String? = nil, body: RequestBody? = nil, parameters: RequestParameters? = nil, pathParameters: [String: String]? = nil) {
		super.init(applicationCode: applicationCode, method: .patch, path: path, pushRegistrationId: pushRegistrationId, body: body, parameters: parameters, pathParameters: pathParameters)
	}
}

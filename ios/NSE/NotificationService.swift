import UserNotifications
import KeychainSwift
import Alamofire

class NotificationService: UNNotificationServiceExtension {
    let keychainSharingId = "KUT463DS29.com.linagora.ios.twake.shared"
    let keychainSharingKey = "keychain_sharing_data"

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    lazy var keychain: KeychainSwift = {
        let keychain = KeychainSwift()
        keychain.accessGroup = keychainSharingId
        return keychain
    }()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        let userInfo = request.content.userInfo
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent,
              let roomId = userInfo["room_id"] as? String,
              let eventId = userInfo["event_id"] as? String,
              let keychainSharingJson = keychain.get(keychainSharingKey),
              let keychainSharingData = try? KeychainSharingData(keychainSharingJson)
        else {
            contentHandler(request.content)
            return
        }
        
        let client = MatrixHttpClient(
            homeserverUrl: keychainSharingData.homeserverUrl,
            token: keychainSharingData.token)
        
        client.getEvent(eventId: eventId, roomId: roomId) { event in
            if let body = event?.content?.body {
                bestAttemptContent.body = body
            }
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

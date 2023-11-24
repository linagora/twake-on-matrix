import UserNotifications
import KeychainSwift

class NotificationService: UNNotificationServiceExtension {
    let keychainSharingId = "KUT463DS29.com.linagora.ios.twake.shared"
    let accessTokenKey = "accessToken"

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    lazy var keychain: KeychainSwift = {
        let keychain = KeychainSwift()
        keychain.accessGroup = keychainSharingId
        return keychain
    }()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            let accessToken = keychain.get(accessTokenKey)
            bestAttemptContent.title = accessToken ?? "null"
            
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

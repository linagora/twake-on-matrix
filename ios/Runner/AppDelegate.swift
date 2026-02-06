import UIKit
import Flutter
import receive_sharing_intent

let apnTokenKey = "apnToken"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  var twakeApnChannel: FlutterMethodChannel?
  var initialNotiInfo: Any?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    initialNotiInfo = launchOptions?[.remoteNotification]
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        twakeApnChannel = createApnChannel(engineBridge.applicationRegistrar.messenger())
    }
    
    func createApnChannel(_ messenger: FlutterBinaryMessenger) -> FlutterMethodChannel {
        let twakeApnChannel = FlutterMethodChannel(
            name: "twake_apn",
            binaryMessenger: messenger)
        twakeApnChannel.setMethodCallHandler { [weak self ] call, result in
            switch call.method {
            case "getToken":
                result(UserDefaults.standard.string(forKey: apnTokenKey))
            case "getInitialNoti":
                result(self?.initialNotiInfo)
                self?.initialNotiInfo = nil
            case "clearAll":
                UIApplication.shared.applicationIconBadgeNumber = 0
                let center = UNUserNotificationCenter.current()
                center.removeAllDeliveredNotifications()
                center.removeAllPendingNotificationRequests()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        return twakeApnChannel
    }
    
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.base64EncodedString()
        // Save the token to use in the future
        UserDefaults.standard.set(token, forKey: apnTokenKey)
    }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let sharingIntent = SwiftReceiveSharingIntentPlugin.instance
        if sharingIntent.hasMatchingSchemePrefix(url: url) {
            return sharingIntent.application(app, open: url, options: options)
        }

        return super.application(app, open: url, options:options)
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        twakeApnChannel?.invokeMethod("willPresent", arguments: userInfo)
        let isRemoteNotification = userInfo["event_id"] != nil
        // Hide remote noti when in foreground, decrypted noti will show by dart
        completionHandler(isRemoteNotification ? [] : [.alert, .badge, .sound])
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        twakeApnChannel?.invokeMethod("didReceive", arguments: userInfo)
        completionHandler()
    }
}

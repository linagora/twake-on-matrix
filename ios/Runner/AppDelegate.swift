import UIKit
import Flutter
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var twakeApnChannel: FlutterMethodChannel?
  var initialNotiInfo: Any?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    twakeApnChannel = createApnChannel()
    initialNotiInfo = launchOptions?[.remoteNotification]
    
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    func createApnChannel() -> FlutterMethodChannel {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let twakeApnChannel = FlutterMethodChannel(
            name: "twake_apn",
            binaryMessenger: controller.binaryMessenger)
        twakeApnChannel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "getToken":
                Messaging.messaging().token { token, error in
                    result(token)
                }
            case "getInitialNoti":
                result(self?.initialNotiInfo)
                self?.initialNotiInfo = nil
            default:
                break
            }
        }
        return twakeApnChannel
    }
    
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Still need apn token because FirebaseAppDelegateProxyEnabled disabled
        Messaging.messaging().apnsToken = deviceToken
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        twakeApnChannel?.invokeMethod("willPresent", arguments: userInfo)
        let isRemoteNotification = userInfo["event_id"] != nil && userInfo["room_id"] != nil
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
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any])
      -> UIBackgroundFetchResult {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print full message.
      print(userInfo)

      return UIBackgroundFetchResult.newData
    }
}

import UIKit
import Flutter

let apnTokenKey = "apnToken"

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var twakeApnChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    self.twakeApnChannel = createApnChannel()
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
        twakeApnChannel.setMethodCallHandler({
          (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getToken" {
                result(UserDefaults.standard.string(forKey: apnTokenKey))
            }
        })
        return twakeApnChannel
    }
    
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.base64EncodedString()
        // Save the token to use in the future
        UserDefaults.standard.set(token, forKey: apnTokenKey)
    }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        twakeApnChannel?.invokeMethod("willPresent", arguments: userInfo)
        switch UIApplication.shared.applicationState {
        case .active:
            // Do not show notification when app in foreground
            return completionHandler([])
        default:
            return completionHandler([.alert, .badge, .sound])
        }
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        twakeApnChannel?.invokeMethod("didReceive", arguments: userInfo)
        completionHandler()
    }
}

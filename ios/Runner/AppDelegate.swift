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
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
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
}

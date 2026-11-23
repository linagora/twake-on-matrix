import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // True (quit on last window closed) until Dart says an account is signed in.
  private var keepRunningWhenWindowClosed = false

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // The window must survive a close so a Dock click can bring it back.
    mainFlutterWindow?.isReleasedWhenClosed = false
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "app.twake/lifecycle", binaryMessenger: controller.engine.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "setKeepRunningWhenWindowClosed",
          let keep = call.arguments as? Bool
        else { return result(FlutterMethodNotImplemented) }
        self?.keepRunningWhenWindowClosed = keep
        result(nil)
      }
    }
    super.applicationDidFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return !keepRunningWhenWindowClosed
  }

  // Dock click with the window closed: bring the window back.
  override func applicationShouldHandleReopen(
    _ sender: NSApplication, hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag {
      mainFlutterWindow?.makeKeyAndOrderFront(nil)
      sender.activate(ignoringOtherApps: true)
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

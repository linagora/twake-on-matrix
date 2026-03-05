import Foundation
import Flutter

/// Flutter method channel plugin that persists Megolm session keys from
/// `m.room_key` to-device events into the shared App Group container.
///
/// The NSE reads these keys to perform fallback decryption when the Rust SDK's
/// crypto store is empty (i.e. when the user logs in via the Dart SDK).
class AppGroupMegolmPlugin {
    private static let sessionsFileName = "megolm_sessions.json"
    private static let lock = NSLock()

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "megolm_session_store",
            binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            guard call.method == "writeSession",
                  let args = call.arguments as? [String: String],
                  let roomId = args["roomId"],
                  let sessionId = args["sessionId"],
                  let sessionKey = args["sessionKey"]
            else {
                result(FlutterMethodNotImplemented)
                return
            }
            writeSession(roomId: roomId, sessionId: sessionId, sessionKey: sessionKey)
            result(nil)
        }
    }

    private static func writeSession(roomId: String, sessionId: String, sessionKey: String) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return
        }
        let fileURL = containerURL.appendingPathComponent(sessionsFileName)
        let key = "\(roomId):\(sessionId)"

        lock.lock()
        defer { lock.unlock() }

        var sessions: [String: String] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            sessions = existing
        }
        sessions[key] = sessionKey
        if let data = try? JSONSerialization.data(withJSONObject: sessions) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private static var appGroupIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "appGroupIdentifier") as? String
            ?? "group.app.twake.ios.chat"
    }
}

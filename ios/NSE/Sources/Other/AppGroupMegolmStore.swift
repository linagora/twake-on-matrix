import Foundation

/// Reads Megolm session keys written by `AppGroupMegolmPlugin` from the shared App Group container.
struct AppGroupMegolmStore {
    private static let sessionsFileName = "megolm_sessions.json"

    static func sessionKey(roomId: String, sessionId: String) -> String? {
        let fileURL = URL.appGroupContainerDirectory.appendingPathComponent(sessionsFileName)
        guard let data = try? Data(contentsOf: fileURL),
              let sessions = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else {
            return nil
        }
        return sessions["\(roomId):\(sessionId)"]
    }
}

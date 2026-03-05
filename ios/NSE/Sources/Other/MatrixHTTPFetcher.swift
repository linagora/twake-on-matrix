import Foundation

/// Fetches Matrix events, profiles, room state, and media from the homeserver CS API.
struct MatrixHTTPFetcher {
    private let accessToken: String
    private let homeserverURL: String

    init(accessToken: String, homeserverURL: String) {
        self.accessToken = accessToken
        // Trim trailing slash so URL construction is consistent.
        self.homeserverURL = homeserverURL.hasSuffix("/")
            ? String(homeserverURL.dropLast())
            : homeserverURL
    }

    private func fetchJson(url: URL) async -> [String: Any]? {
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                MXLog.error("MatrixHTTPFetcher: unexpected HTTP status for \(url)")
                return nil
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json
        } catch {
            MXLog.error("MatrixHTTPFetcher: fetch failed: \(error)")
            return nil
        }
    }

    /// Fetches a single Matrix event as a generic dictionary.
    func fetchEvent(roomId: String, eventId: String) async -> [String: Any]? {
        guard let encodedRoomId = roomId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedEventId = eventId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(homeserverURL)/_matrix/client/v3/rooms/\(encodedRoomId)/event/\(encodedEventId)")
        else {
            MXLog.error("MatrixHTTPFetcher: invalid URL for roomId=\(roomId) eventId=\(eventId)")
            return nil
        }
        return await fetchJson(url: url)
    }

    /// Fetches a user's profile information.
    func fetchProfile(userId: String) async -> [String: Any]? {
        guard let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(homeserverURL)/_matrix/client/v3/profile/\(encodedUserId)")
        else {
            MXLog.error("MatrixHTTPFetcher: invalid URL for userId=\(userId)")
            return nil
        }
        return await fetchJson(url: url)
    }

    /// Fetches a room state event.
    func fetchRoomState(roomId: String, eventType: String) async -> [String: Any]? {
        guard let encodedRoomId = roomId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedType = eventType.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(homeserverURL)/_matrix/client/v3/rooms/\(encodedRoomId)/state/\(encodedType)/")
        else {
            MXLog.error("MatrixHTTPFetcher: invalid URL for roomId=\(roomId) eventType=\(eventType)")
            return nil
        }
        return await fetchJson(url: url)
    }

    /// Fetches media data from an mxc:// URL.
    func fetchMedia(mxcURL: String) async -> Data? {
        guard mxcURL.hasPrefix("mxc://") else { return nil }
        let index = mxcURL.index(mxcURL.startIndex, offsetBy: 6)
        let path = String(mxcURL[index...]) // domain/hash
        guard let url = URL(string: "\(homeserverURL)/_matrix/media/v3/download/\(path)") else {
            MXLog.error("MatrixHTTPFetcher: invalid media URL for \(mxcURL)")
            return nil
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                MXLog.error("MatrixHTTPFetcher: failed to fetch media HTTP status for \(url)")
                return nil
            }
            return data
        } catch {
            MXLog.error("MatrixHTTPFetcher: fetch media failed: \(error)")
            return nil
        }
    }
}

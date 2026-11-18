//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import MatrixRustSDK
import UIKit

/// Notification built from plain Matrix HTTP calls (no Rust client, no crypto).
/// `body == nil` means the event is still encrypted, unless `isInvite` is set.
struct HTTPNotificationItem: NotificationItemProxyProtocol {
    let eventID: String
    let roomID: String
    let receiverID: String
    let senderID: String
    let senderDisplayName: String?
    let senderAvatarMediaSource: MediaSourceProxy?
    let roomDisplayName: String
    let roomAvatarMediaSource: MediaSourceProxy?
    let isRoomDirect: Bool
    let body: String?
    let isInvite: Bool

    var event: NotificationEvent? { nil }
    var roomCanonicalAlias: String? { nil }
    // ponytail: no push rules evaluated over HTTP, always play the sound
    var isNoisy: Bool { true }
    // ponytail: a direct room is assumed to have 2 members
    var roomJoinedMembers: Int { isRoomDirect ? 2 : 0 }
}

struct NSEHTTPSession: MediaProviderProtocol {
    let credentials: HTTPCredentials

    // MARK: - Notification

    /// Returns nil when the notification must stay neutral (redacted, other event type, any HTTP failure).
    func notificationItem(roomID: String, eventID: String) async -> HTTPNotificationItem? {
        guard let event = await fetchEvent(roomID: roomID, eventID: eventID),
              let sender = event["sender"] as? String,
              (event["unsigned"] as? [String: Any])?["redacted_because"] == nil else {
            return nil
        }
        let content = event["content"] as? [String: Any]
        let body: String?
        var isInvite = false
        switch event["type"] as? String {
        case "m.room.encrypted":
            body = nil
        case "m.room.message":
            guard let text = messageText(content) else { return nil }
            body = text
        case "m.room.member":
            guard content?["membership"] as? String == "invite", event["state_key"] as? String == credentials.userId else { return nil }
            isInvite = true
            body = nil
        default:
            return nil
        }

        func item(sender senderName: String?, senderAvatar: String?, roomName: String?, roomAvatar: String?, isDirect: Bool) -> HTTPNotificationItem {
            HTTPNotificationItem(eventID: eventID,
                                 roomID: roomID,
                                 receiverID: credentials.userId,
                                 senderID: sender,
                                 senderDisplayName: senderName,
                                 senderAvatarMediaSource: senderAvatar.flatMap(mediaSource),
                                 // ponytail: an unnamed group is titled after its sender
                                 roomDisplayName: roomName ?? senderName ?? sender,
                                 roomAvatarMediaSource: roomAvatar.flatMap(mediaSource),
                                 isRoomDirect: isDirect,
                                 body: body,
                                 isInvite: isInvite)
        }

        if isInvite {
            // The user is not in the room yet: its state may be forbidden, so every field is optional.
            async let profile = json("/_matrix/client/v3/profile/\(enc(sender))", timeout: 4)
            async let avatar = state(roomID, "m.room.avatar")
            async let name = state(roomID, "m.room.name")
            let (profileContent, avatarContent, nameContent) = await (profile, avatar, name)
            return item(sender: profileContent?["displayname"] as? String,
                        senderAvatar: profileContent?["avatar_url"] as? String,
                        roomName: (nameContent?["name"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                        roomAvatar: avatarContent?["url"] as? String,
                        isDirect: content?["is_direct"] as? Bool ?? false)
        }

        guard body != nil else {
            return item(sender: nil, senderAvatar: nil, roomName: nil, roomAvatar: nil, isDirect: false)
        }

        async let member = state(roomID, "m.room.member", sender)
        async let avatar = state(roomID, "m.room.avatar")
        async let name = state(roomID, "m.room.name")
        async let direct = json("/_matrix/client/v3/user/\(enc(credentials.userId))/account_data/m.direct", timeout: 4)
        let (memberContent, avatarContent, nameContent, directContent) = await (member, avatar, name, direct)

        let isDirect = directContent?.values.contains { ($0 as? [String]).map { $0.contains(roomID) } ?? false } ?? false
        return item(sender: memberContent?["displayname"] as? String,
                    senderAvatar: memberContent?["avatar_url"] as? String,
                    roomName: (nameContent?["name"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                    roomAvatar: avatarContent?["url"] as? String,
                    isDirect: isDirect)
    }

    /// A user who is not in the room (invitation) cannot read the event: look for it in the notifications instead.
    private func fetchEvent(roomID: String, eventID: String) async -> [String: Any]? {
        if let event = await json("/_matrix/client/v3/rooms/\(enc(roomID))/event/\(enc(eventID))", timeout: 8) {
            return event
        }
        let notifications = await json("/_matrix/client/v3/notifications?limit=20", timeout: 4)
        return (notifications?["notifications"] as? [[String: Any]])?
            .first { $0["room_id"] as? String == roomID && ($0["event"] as? [String: Any])?["event_id"] as? String == eventID }?["event"] as? [String: Any]
    }

    private func messageText(_ content: [String: Any]?) -> String? {
        switch content?["msgtype"] as? String {
        case "m.image": return L10n.commonImage
        case "m.video": return L10n.commonVideo
        case "m.audio": return L10n.commonAudio
        case "m.file": return L10n.commonFile
        default:
            let edited = content?["m.new_content"] as? [String: Any]
            if let body = edited?["body"] as? String { return body }
            guard let body = content?["body"] as? String else { return nil }
            let isReply = (content?["m.relates_to"] as? [String: Any])?["m.in_reply_to"] != nil
            return isReply ? withoutQuoteFallback(body) : body
        }
    }

    /// A reply body starts with the quoted lines ("> ..."), then a blank line, then the real text.
    private func withoutQuoteFallback(_ body: String) -> String {
        let lines = body.components(separatedBy: "\n")
        guard lines.first?.hasPrefix("> ") == true,
              let blank = lines.firstIndex(of: "") else { return body }
        return lines[(blank + 1)...].joined(separator: "\n")
    }

    private func state(_ roomID: String, _ type: String, _ key: String = "") async -> [String: Any]? {
        await json("/_matrix/client/v3/rooms/\(enc(roomID))/state/\(type)/\(enc(key))", timeout: 4)
    }

    private func mediaSource(_ mxc: String) -> MediaSourceProxy? {
        URL(string: mxc).flatMap { MediaSourceProxy(url: $0, mimeType: nil) }
    }

    // MARK: - HTTP

    private func enc(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~"))) ?? value
    }

    private func json(_ path: String, timeout: TimeInterval) async -> [String: Any]? {
        guard let data = await get(path, timeout: timeout) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// The body of a 200 answer, nil for anything else. The access token is never logged.
    private func get(_ path: String, timeout: TimeInterval) async -> Data? {
        let base = credentials.homeserverUrl.hasSuffix("/") ? String(credentials.homeserverUrl.dropLast()) : credentials.homeserverUrl
        guard let url = URL(string: base + path) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else {
            MXLog.info("NSE HTTP: \(path.components(separatedBy: "?")[0]) failed")
            return nil
        }
        return data
    }

    // MARK: - MediaProviderProtocol

    func loadThumbnailForSource(_ source: MediaSourceProxy, size: CGSize) async -> Result<Data, MediaProviderError> {
        guard let server = source.url.host else { return .failure(.failedRetrievingImage) }
        let tail = "thumbnail/\(enc(server))/\(enc(source.url.lastPathComponent))?width=\(Int(size.width))&height=\(Int(size.height))&method=crop"
        // Authenticated media first, legacy endpoint for older homeservers.
        for prefix in ["/_matrix/client/v1/media/", "/_matrix/media/v3/"] {
            if let data = await get(prefix + tail, timeout: 3) {
                return .success(data)
            }
        }
        return .failure(.failedRetrievingImage)
    }

    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage? { nil }

    func loadImageFromSource(_ source: MediaSourceProxy, size: CGSize?) async -> Result<UIImage, MediaProviderError> {
        .failure(.failedRetrievingImage)
    }

    func loadImageDataFromSource(_ source: MediaSourceProxy) async -> Result<Data, MediaProviderError> {
        .failure(.failedRetrievingImage)
    }

    func loadFileFromSource(_ source: MediaSourceProxy, body: String?) async -> Result<MediaFileHandleProxy, MediaProviderError> {
        .failure(.failedRetrievingFile)
    }
}

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
/// `isNeutral` means the room state is unknown: the builder shows the default text.
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
    let isNoisy: Bool
    let isNeutral: Bool
    let threadRootID: String?

    var event: NotificationEvent? { nil }
    var roomCanonicalAlias: String? { nil }
    /// Encrypted events carry no body: `body == nil` is handled by the builder.
    var isRoomEncrypted: Bool { false }
    // a direct room is assumed to have 2 members
    var roomJoinedMembers: Int { isRoomDirect ? 2 : 0 }
}

/// What the `m.room.encryption` lookup said: 404 is clear, 200 encrypted, anything else unknown.
private enum RoomEncryption {
    case clear, encrypted, unknown
}

private struct ClassifiedEvent {
    var body: String?
    var isInvite = false
    var encryption = RoomEncryption.encrypted
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
        guard let classified = await classify(event, content: content, roomID: roomID) else { return nil }
        let body = classified.body
        let isInvite = classified.isInvite
        let neutral = classified.encryption == .unknown
        var noisy = true
        // The relation stays in clear in an encrypted event.
        let relation = content?["m.relates_to"] as? [String: Any]
        let threadRootID = relation?["rel_type"] as? String == "m.thread" ? relation?["event_id"] as? String : nil

        func item(sender senderName: String?, senderAvatar: String?, roomName: String?, roomAvatar: String?, isDirect: Bool) -> HTTPNotificationItem {
            HTTPNotificationItem(eventID: eventID,
                                 roomID: roomID,
                                 receiverID: credentials.userId,
                                 senderID: sender,
                                 senderDisplayName: senderName,
                                 senderAvatarMediaSource: senderAvatar.flatMap(mediaSource),
                                 // an unnamed group is titled after its sender
                                 roomDisplayName: roomName ?? senderName ?? sender,
                                 roomAvatarMediaSource: roomAvatar.flatMap(mediaSource),
                                 isRoomDirect: isDirect,
                                 body: body,
                                 isInvite: isInvite,
                                 isNoisy: noisy,
                                 isNeutral: neutral,
                                 threadRootID: threadRootID)
        }

        if isInvite {
            // The user is not in the room yet: its state may be forbidden, so every field is optional.
            async let profile = json("/_matrix/client/v3/profile/\(enc(sender))", label: "profile", timeout: 4)
            async let avatar = state(roomID, "m.room.avatar")
            async let name = state(roomID, "m.room.name")
            let (profileContent, avatarContent, nameContent) = await (profile, avatar, name)
            return item(sender: profileContent?["displayname"] as? String,
                        senderAvatar: profileContent?["avatar_url"] as? String,
                        roomName: (nameContent?["name"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                        roomAvatar: avatarContent?["url"] as? String,
                        isDirect: content?["is_direct"] as? Bool ?? false)
        }

        // Unknown room state: nothing else is read, the default text is shown.
        // Silent, like a failed push rule lookup: the room may be muted.
        guard !neutral else {
            noisy = false
            return item(sender: nil, senderAvatar: nil, roomName: nil, roomAvatar: nil, isDirect: false)
        }

        guard body != nil else {
            // An encrypted event hides its mentions: only a rule or a direct room can ring.
            let ruleSound = await roomRuleSound(roomID)
            let isDirect = await isDirectRoom(roomID)
            noisy = ruleSound ?? isDirect
            return item(sender: nil, senderAvatar: nil, roomName: nil, roomAvatar: nil, isDirect: false)
        }

        async let member = state(roomID, "m.room.member", sender)
        async let avatar = state(roomID, "m.room.avatar")
        async let name = state(roomID, "m.room.name")
        async let direct = isDirectRoom(roomID)
        async let ruleSound = roomRuleSound(roomID)
        let (memberContent, avatarContent, nameContent, isDirect) = await (member, avatar, name, direct)
        // A mention rings whatever the room rule says (.m.rule.is_user_mention outranks room rules).
        // Otherwise the room rule decides, and without one the server defaults: a sound for direct rooms only.
        let rule = await ruleSound
        noisy = isMentioned(content)
        if !noisy { noisy = rule ?? isDirect }
        return item(sender: memberContent?["displayname"] as? String,
                    senderAvatar: memberContent?["avatar_url"] as? String,
                    roomName: (nameContent?["name"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                    roomAvatar: avatarContent?["url"] as? String,
                    isDirect: isDirect)
    }

    private func classify(_ event: [String: Any], content: [String: Any]?, roomID: String) async -> ClassifiedEvent? {
        switch event["type"] as? String {
        case "m.room.encrypted":
            return ClassifiedEvent()
        case "m.room.message":
            guard let text = messageText(content) else { return nil }
            // A clear event can sit in an encrypted room (bots, bridges): the room decides.
            let encryption = await roomEncryption(roomID)
            return ClassifiedEvent(body: encryption == .clear ? text : nil, encryption: encryption)
        case "m.room.member":
            guard content?["membership"] as? String == "invite", event["state_key"] as? String == credentials.userId else { return nil }
            return ClassifiedEvent(isInvite: true)
        default:
            return nil
        }
    }

    /// A user who is not in the room (invitation) cannot read the event: look for it in the notifications instead.
    private func fetchEvent(roomID: String, eventID: String) async -> [String: Any]? {
        if let event = await json("/_matrix/client/v3/rooms/\(enc(roomID))/event/\(enc(eventID))", label: "event", timeout: 8) {
            return event
        }
        let notifications = await json("/_matrix/client/v3/notifications?limit=20", label: "notifications", timeout: 4)
        return (notifications?["notifications"] as? [[String: Any]])?
            .first { $0["room_id"] as? String == roomID && ($0["event"] as? [String: Any])?["event_id"] as? String == eventID }?["event"] as? [String: Any]
    }

    private func messageText(_ content: [String: Any]?) -> String? {
        switch content?["msgtype"] as? String {
        case "m.image": return L10n.commonImage
        case "m.video": return L10n.commonVideo
        case "m.audio": return L10n.commonAudio
        case "m.file": return L10n.commonFile
        case "m.text", "m.notice", "m.emote":
            let edited = content?["m.new_content"] as? [String: Any]
            if let body = edited?["body"] as? String { return body }
            guard let body = content?["body"] as? String else { return nil }
            let isReply = (content?["m.relates_to"] as? [String: Any])?["m.in_reply_to"] != nil
            return isReply ? withoutQuoteFallback(body) : body
        default:
            // Location, verification requests and unknown types stay neutral.
            return nil
        }
    }

    /// A reply body starts with the quoted lines ("> ..."), then a blank line, then the real text.
    private func withoutQuoteFallback(_ body: String) -> String {
        let lines = body.components(separatedBy: "\n")
        guard lines.first?.hasPrefix("> ") == true,
              let blank = lines.firstIndex(of: "") else { return body }
        return lines[(blank + 1)...].joined(separator: "\n")
    }

    private func roomEncryption(_ roomID: String) async -> RoomEncryption {
        switch await fetch("/_matrix/client/v3/rooms/\(enc(roomID))/state/m.room.encryption/", label: "state/m.room.encryption", timeout: 4).status {
        case 404: return .clear
        case 200: return .encrypted
        default: return .unknown
        }
    }

    private func isDirectRoom(_ roomID: String) async -> Bool {
        let direct = await json("/_matrix/client/v3/user/\(enc(credentials.userId))/account_data/m.direct", label: "account_data/m.direct", timeout: 4)
        return direct?.values.contains { ($0 as? [String]).map { $0.contains(roomID) } ?? false } ?? false
    }

    private func isMentioned(_ content: [String: Any]?) -> Bool {
        let mentions = content?["m.mentions"] as? [String: Any]
        if (mentions?["user_ids"] as? [String])?.contains(credentials.userId) == true { return true }
        return mentions?["room"] as? Bool == true
    }

    /// Whether the room rule of the user rings: nil without a rule (404), the server defaults then decide.
    /// A rule that notifies without a sound tweak is silent; an empty rule ("mentions only") means the push is a mention, so it rings.
    /// Any other failure is silent, like the Rust path (`isNoisy ?? false`): a banner without a ring beats a ring in a silenced room.
    private func roomRuleSound(_ roomID: String) async -> Bool? {
        let answer = await fetch("/_matrix/client/v3/pushrules/global/room/\(enc(roomID))", label: "pushrules/room", timeout: 4)
        if answer.status == 404 { return nil }
        guard let data = answer.data,
              let rule = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        guard rule["enabled"] as? Bool != false, let actions = rule["actions"] as? [Any] else { return nil }
        let notifies = actions.contains { $0 as? String == "notify" }
        let sounds = actions.contains { ($0 as? [String: Any])?["set_tweak"] as? String == "sound" }
        return sounds || !notifies
    }

    private func state(_ roomID: String, _ type: String, _ key: String = "") async -> [String: Any]? {
        await json("/_matrix/client/v3/rooms/\(enc(roomID))/state/\(type)/\(enc(key))", label: "state/\(type)", timeout: 4)
    }

    private func mediaSource(_ mxc: String) -> MediaSourceProxy? {
        URL(string: mxc).flatMap { MediaSourceProxy(url: $0, mimeType: nil) }
    }

    // MARK: - HTTP

    private func enc(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~"))) ?? value
    }

    private func json(_ path: String, label: String, timeout: TimeInterval) async -> [String: Any]? {
        guard let data = await get(path, label: label, timeout: timeout) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// The body of a 200 answer, nil for anything else.
    private func get(_ path: String, label: String, timeout: TimeInterval) async -> Data? {
        await fetch(path, label: label, timeout: timeout).data
    }

    /// `status` is 0 without an answer. Logs only `label` and the status: paths hold Matrix IDs, and the access token is never logged.
    private func fetch(_ path: String, label: String, timeout: TimeInterval) async -> (data: Data?, status: Int) {
        let base = credentials.homeserverUrl.hasSuffix("/") ? String(credentials.homeserverUrl.dropLast()) : credentials.homeserverUrl
        guard let url = URL(string: base + path) else { return (nil, 0) }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let status = (response as? HTTPURLResponse)?.statusCode else {
            MXLog.info("NSE HTTP: \(label) failed (no answer)")
            return (nil, 0)
        }
        guard status == 200 else {
            MXLog.info("NSE HTTP: \(label) failed (\(status))")
            return (nil, status)
        }
        return (data, status)
    }

    // MARK: - MediaProviderProtocol

    func loadThumbnailForSource(_ source: MediaSourceProxy, size: CGSize) async -> Result<Data, MediaProviderError> {
        guard let host = source.url.host else { return .failure(.failedRetrievingImage) }
        // `host` drops the port of a server name such as media.example.org:8448.
        let server = source.url.port.map { "\(host):\($0)" } ?? host
        let tail = "thumbnail/\(enc(server))/\(enc(source.url.lastPathComponent))?width=\(Int(size.width))&height=\(Int(size.height))&method=crop"
        // Authenticated media first, legacy endpoint for older homeservers.
        for prefix in ["/_matrix/client/v1/media/", "/_matrix/media/v3/"] {
            if let data = await get(prefix + tail, label: "thumbnail", timeout: 3) {
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

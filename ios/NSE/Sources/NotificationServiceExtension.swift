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

import Intents
import UserNotifications

class NotificationServiceExtension: UNNotificationServiceExtension {
    private lazy var keychainController = KeychainController(service: .sessions,
                                                             accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
    private var handler: ((UNNotificationContent) -> Void)?
    private var originalContent: UNNotificationContent?
    private var modifiedContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard let roomId = request.roomId,
              let eventId = request.eventId,
              let clientID = request.pusherNotificationClientIdentifier,
              let credentials = keychainController.restorationTokens().first(where: {
                  $0.restorationToken.pusherNotificationClientIdentifier == clientID
              })
        else {
            return contentHandler(request.content)
        }

        handler = contentHandler
        originalContent = request.content
        modifiedContent = request.content.mutableCopy() as? UNMutableNotificationContent

        NSELogger.configure()
        NSELogger.logMemory(with: tag)

        MXLog.info("\(tag) #########################################")
        MXLog.info("\(tag) Payload came: \(request.content.userInfo)")

        Task {
            await processEvent(credentials: credentials, roomId: roomId, eventId: eventId)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        MXLog.warning("\(tag) serviceExtensionTimeWillExpire")
        notify()
    }

    // MARK: - Content decoration

    private func decorateModifiedContent(
        roomId: String,
        eventId: String,
        sender: String,
        body: String,
        receiverId: String,
        fetcher: MatrixHTTPFetcher,
        mediaData: Data? = nil,
        mediaFileExtension: String? = nil
    ) async {
        let newContent = UNMutableNotificationContent()
        newContent.body = body

        async let profileResponse = fetcher.fetchProfile(userId: sender)
        async let roomNameResponse = fetcher.fetchRoomState(roomId: roomId, eventType: "m.room.name")
        async let roomAvatarResponse = fetcher.fetchRoomState(roomId: roomId, eventType: "m.room.avatar")

        let profile = await profileResponse
        let senderDisplayName = profile?["displayname"] as? String ?? sender
        let senderAvatarUrl = profile?["avatar_url"] as? String

        let roomNameState = await roomNameResponse
        let isDM = roomNameState == nil || roomNameState?["name"] == nil
        let roomName = roomNameState?["name"] as? String ?? senderDisplayName

        let roomAvatarState = await roomAvatarResponse
        let roomAvatarUrl = roomAvatarState?["url"] as? String

        var avatarData: Data?
        if isDM, let url = senderAvatarUrl {
            avatarData = await fetcher.fetchMedia(mxcURL: url)
        } else if !isDM, let url = roomAvatarUrl {
            avatarData = await fetcher.fetchMedia(mxcURL: url)
        }

        newContent.title = senderDisplayName
        if senderDisplayName != roomName {
            newContent.subtitle = roomName
        }
        newContent.categoryIdentifier = NotificationConstants.Category.message
        newContent.receiverID = receiverId
        newContent.roomID = roomId
        newContent.eventID = eventId
        newContent.threadIdentifier = "\(receiverId)\(roomId)".replacingOccurrences(of: "@", with: "")
        newContent.sound = modifiedContent?.sound ?? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf"))
        newContent.badge = modifiedContent?.badge

        do {
            let icon = NotificationIcon(
                fallbackImageData: avatarData,
                groupInfo: isDM ? nil : NotificationIcon.GroupInfo(name: roomName, id: roomId)
            )
            modifiedContent = try await newContent.addSenderIcon(
                senderID: sender,
                senderName: senderDisplayName,
                icon: icon
            )
        } catch {
            MXLog.error("\(tag) decorateModifiedContent: failed to add sender icon: \(error)")
            modifiedContent = newContent
        }

        if let data = mediaData, let ext = mediaFileExtension {
            modifiedContent?.addMediaAttachment(data: data, fileExtension: ext)
        }
    }

    // MARK: - Event processing

    private func processEvent(
        credentials: KeychainCredentials,
        roomId: String,
        eventId: String
    ) async {
        let session = credentials.restorationToken.session
        let fetcher = MatrixHTTPFetcher(
            accessToken: session.accessToken,
            homeserverURL: session.homeserverUrl)

        guard let event = await fetcher.fetchEvent(roomId: roomId, eventId: eventId) else {
            MXLog.info("\(tag) processEvent: could not fetch event")
            return discard()
        }

        let type = event["type"] as? String
        let content = event["content"] as? [String: Any]
        let sender = event["sender"] as? String ?? "@unknown"

        if type == "m.room.message" {
            if let body = friendlyBody(from: content) {
                MXLog.info("\(tag) processEvent: unencrypted message processed successfully")
                let (mediaData, mediaExt) = await fetchUnencryptedMedia(from: content, fetcher: fetcher)
                await decorateModifiedContent(roomId: roomId, eventId: eventId, sender: sender, body: body,
                                              receiverId: credentials.userID, fetcher: fetcher,
                                              mediaData: mediaData, mediaFileExtension: mediaExt)
                notify()
            } else {
                MXLog.info("\(tag) processEvent: unencrypted message has no usable body")
                discard()
            }
            return
        }

        guard type == "m.room.encrypted",
              let algorithm = content?["algorithm"] as? String, algorithm == "m.megolm.v1.aes-sha2",
              let sessionId = content?["session_id"] as? String,
              let ciphertext = content?["ciphertext"] as? String
        else {
            MXLog.info("\(tag) processEvent: unsupported event type or missing fields")
            return discard()
        }

        guard let sessionKey = AppGroupMegolmStore.sessionKey(roomId: roomId, sessionId: sessionId) else {
            MXLog.info("\(tag) processEvent: no session key for sessionId=\(sessionId)")
            return discard()
        }
        MXLog.info("\(tag) processEvent: found session key, ciphertext len=\(ciphertext.count)")

        do {
            let plaintextJSON = try MegolmDecryptor.decrypt(
                ciphertextBase64: ciphertext,
                sessionKeyBase64url: sessionKey)
            guard let decryptedContent = MegolmDecryptor.extractContent(from: plaintextJSON),
                  let body = friendlyBody(from: decryptedContent) else {
                MXLog.info("\(tag) processEvent: could not extract body from decrypted content")
                return discard()
            }
            MXLog.info("\(tag) processEvent: decryption successful")
            let (mediaData, mediaExt) = await fetchEncryptedMedia(from: decryptedContent, fetcher: fetcher)
            await decorateModifiedContent(roomId: roomId, eventId: eventId, sender: sender, body: body,
                                          receiverId: credentials.userID, fetcher: fetcher,
                                          mediaData: mediaData, mediaFileExtension: mediaExt)
            notify()
        } catch {
            MXLog.error("\(tag) processEvent: decryption failed: \(error)")
            discard()
        }
    }

    /// Maps a Matrix message event content dict to a user-friendly notification body string.
    /// Media types (image, video, audio, file, location) return localized type labels
    /// instead of raw filenames. Text-like types return the raw body.
    private func friendlyBody(from content: [String: Any]?) -> String? {
        guard let content else { return nil }
        let msgtype = content["msgtype"] as? String
        switch msgtype {
        case "m.image":    return L10n.commonImage
        case "m.video":    return L10n.commonVideo
        case "m.audio":    return L10n.commonAudio
        case "m.file":     return L10n.commonFile
        case "m.location": return L10n.commonSharedLocation
        default:           return content["body"] as? String
        }
    }

    // MARK: - Media helpers

    /// Returns downloaded media data and file extension for an unencrypted `m.room.message`.
    /// Only `m.image`, `m.video`, and `m.audio` are fetched; other types return `(nil, nil)`.
    private func fetchUnencryptedMedia(from content: [String: Any]?, fetcher: MatrixHTTPFetcher) async -> (Data?, String?) {
        guard let content,
              let msgtype = content["msgtype"] as? String,
              mediaCapableType(msgtype),
              let mxcURL = content["url"] as? String else { return (nil, nil) }
        let mimeType = (content["info"] as? [String: Any])?["mimetype"] as? String
        let ext = fileExtension(for: mimeType) ?? defaultExtension(for: msgtype)
        guard let data = await fetcher.fetchMedia(mxcURL: mxcURL) else { return (nil, nil) }
        return (data, ext)
    }

    /// Returns decrypted media data and file extension for an encrypted `m.room.message`.
    /// Reads `content["file"]` (Matrix EncryptedFile spec) and decrypts with AES-256-CTR.
    private func fetchEncryptedMedia(from content: [String: Any]?, fetcher: MatrixHTTPFetcher) async -> (Data?, String?) {
        guard let content,
              let msgtype = content["msgtype"] as? String,
              mediaCapableType(msgtype),
              let file = content["file"] as? [String: Any],
              let mxcURL = file["url"] as? String,
              let keyDict = file["key"] as? [String: Any],
              let key = keyDict["k"] as? String,
              let iv = file["iv"] as? String,
              let sha256 = (file["hashes"] as? [String: Any])?["sha256"] as? String else { return (nil, nil) }
        let mimeType = (content["info"] as? [String: Any])?["mimetype"] as? String
        let ext = fileExtension(for: mimeType) ?? defaultExtension(for: msgtype)
        guard let encryptedData = await fetcher.fetchMedia(mxcURL: mxcURL) else { return (nil, nil) }
        do {
            let decrypted = try MatrixAttachmentDecryptor.decrypt(
                encryptedData: encryptedData,
                keyBase64url: key,
                ivBase64: iv,
                sha256Base64: sha256)
            return (decrypted, ext)
        } catch {
            MXLog.warning("\(tag) fetchEncryptedMedia: decryption failed: \(error)")
            return (nil, nil)
        }
    }

    private func mediaCapableType(_ msgtype: String) -> Bool {
        msgtype == "m.image" || msgtype == "m.video" || msgtype == "m.audio"
    }

    private func fileExtension(for mimeType: String?) -> String? {
        switch mimeType {
        case "image/jpeg", "image/jpg": return "jpg"
        case "image/png": return "png"
        case "image/gif": return "gif"
        case "image/webp": return "webp"
        case "video/mp4": return "mp4"
        case "video/quicktime": return "mov"
        case "audio/mpeg", "audio/mp3": return "mp3"
        case "audio/ogg": return "ogg"
        case "audio/wav": return "wav"
        default: return nil
        }
    }

    private func defaultExtension(for msgtype: String) -> String {
        switch msgtype {
        case "m.image": return "jpg"
        case "m.video": return "mp4"
        case "m.audio": return "mp3"
        default: return "bin"
        }
    }

    // MARK: - Notification delivery

    private func notify() {
        MXLog.info("\(tag) notify")
        guard let modifiedContent else {
            return discard()
        }
        handler?(modifiedContent)
        cleanUp()
    }

    private func discard() {
        MXLog.info("\(tag) discard")
        handler?(originalContent ?? UNMutableNotificationContent())
        cleanUp()
    }

    private var tag: String {
        "[NSE][\(Unmanaged.passUnretained(self).toOpaque())][\(Unmanaged.passUnretained(Thread.current).toOpaque())]"
    }

    private func cleanUp() {
        handler = nil
        originalContent = nil
        modifiedContent = nil
    }

    deinit {
        cleanUp()
        NSELogger.logMemory(with: tag)
        MXLog.info("\(tag) deinit")
    }
}

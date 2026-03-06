//
// Copyright 2023 New Vector Ltd
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
import Intents
import SwiftUI
import UserNotifications

import Version

struct NotificationIcon {
    struct GroupInfo {
        let name: String
        let id: String
    }

    let fallbackImageData: Data?
    let groupInfo: GroupInfo?

    var shouldDisplayAsGroup: Bool {
        groupInfo != nil
    }
}

extension UNNotificationContent {
    @objc var receiverID: String? {
        userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] as? String
    }

    @objc var roomID: String? {
        userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String
    }

    @objc var eventID: String? {
        userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String
    }
}

extension UNMutableNotificationContent {
    override var receiverID: String? {
        get { userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] as? String }
        set { userInfo[NotificationConstants.UserInfoKey.receiverIdentifier] = newValue }
    }

    override var roomID: String? {
        get { userInfo[NotificationConstants.UserInfoKey.roomIdentifier] as? String }
        set { userInfo[NotificationConstants.UserInfoKey.roomIdentifier] = newValue }
    }

    override var eventID: String? {
        get { userInfo[NotificationConstants.UserInfoKey.eventIdentifier] as? String }
        set { userInfo[NotificationConstants.UserInfoKey.eventIdentifier] = newValue }
    }

    /// Writes `data` to a temporary file and adds it as a `UNNotificationAttachment`.
    /// Silently ignores failures — the notification is delivered without the attachment.
    func addMediaAttachment(data: Data, fileExtension: String) {
        let fileName = UUID().uuidString + "." + fileExtension
        let fileURL = URL.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            let attachment = try UNNotificationAttachment(identifier: fileName, url: fileURL, options: nil)
            attachments = [attachment]
        } catch {
            MXLog.error("UNMutableNotificationContent: addMediaAttachment failed: \(error)")
        }
    }

    func addSenderIcon(senderID: String,
                       senderName: String,
                       icon: NotificationIcon) async throws -> UNMutableNotificationContent {
        let image: INImage

        if let data = icon.fallbackImageData {
            image = INImage(imageData: data)
        } else if let data = await getPlaceholderAvatarImageData(name: icon.groupInfo?.name ?? senderName,
                                                                 id: icon.groupInfo?.id ?? senderID) {
            image = INImage(imageData: data)
        } else {
            image = INImage(named: "")
        }

        let senderHandle = INPersonHandle(value: senderID, type: .unknown)
        let sender = INPerson(personHandle: senderHandle,
                              nameComponents: nil,
                              displayName: senderName,
                              image: !icon.shouldDisplayAsGroup ? image : nil,
                              contactIdentifier: nil,
                              customIdentifier: nil)

        var speakableGroupName: INSpeakableString?
        var recipients: [INPerson]?
        if let groupInfo = icon.groupInfo {
            let meHandle = INPersonHandle(value: receiverID, type: .unknown)
            let me = INPerson(personHandle: meHandle, nameComponents: nil, displayName: nil, image: nil, contactIdentifier: nil, customIdentifier: nil, isMe: true)
            speakableGroupName = INSpeakableString(spokenPhrase: groupInfo.name)
            recipients = [sender, me]
        }

        let intent = INSendMessageIntent(recipients: recipients,
                                         outgoingMessageType: .outgoingMessageText,
                                         content: nil,
                                         speakableGroupName: speakableGroupName,
                                         conversationIdentifier: roomID,
                                         serviceName: nil,
                                         sender: sender,
                                         attachments: nil)
        if speakableGroupName != nil {
            intent.setImage(image, forParameterNamed: \.speakableGroupName)
        }

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        try await interaction.donate()
        let updatedContent = try updating(from: intent)

        // swiftlint:disable:next force_cast
        return updatedContent.mutableCopy() as! UNMutableNotificationContent
    }

    private func getPlaceholderAvatarImageData(name: String, id: String) async -> Data? {
        let isIOS17Available = isIOS17Available()
        let prefix = "notification_placeholder\(isIOS17Available ? "V3" : "V2")"
        let fileName = "\(prefix)_\(name)_\(id).png"
        if let data = try? Data(contentsOf: URL.temporaryDirectory.appendingPathComponent(fileName)) {
            return data
        }

        let image = PlaceholderAvatarImage(name: name, contentID: id)
            .clipShape(Circle())
            .frame(width: 50, height: 50)
        let renderer = await ImageRenderer(content: image)
        guard let uiImage = await renderer.uiImage else { return nil }

        let data: Data?
        #if targetEnvironment(simulator)
        data = uiImage.pngData()
        #else
        if ProcessInfo.processInfo.isiOSAppOnMac || isIOS17Available {
            data = uiImage.pngData()
        } else {
            data = uiImage.flippedVertically().pngData()
        }
        #endif

        if let data {
            try? FileManager.default.writeDataToTemporaryDirectory(data: data, fileName: fileName)
        }
        return data
    }

    private func isIOS17Available() -> Bool {
        guard let version = Version(UIDevice.current.systemVersion) else { return false }
        return version.major >= 17
    }
}

private extension UIImage {
    func flippedVertically() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            context.cgContext.concatenate(CGAffineTransform(scaleX: 1, y: -1))
            self.draw(at: CGPoint(x: 0, y: -size.height))
        }
    }
}

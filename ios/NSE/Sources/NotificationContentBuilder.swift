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
import MatrixRustSDK
import UserNotifications

struct NotificationContentBuilder {
    let messageEventStringBuilder: RoomMessageEventStringBuilder
    
    /// Process the given notification item proxy
    /// - Parameters:
    ///   - notificationItem: The notification item
    ///   - mediaProvider: Media provider to process also media. May be passed nil to ignore media operations.
    /// - Returns: A notification content object if the notification should be displayed. Otherwise nil.
    func content(for notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        switch notificationItem.event {
        case .none:
            return processEmpty(notificationItem: notificationItem)
        case .invite:
            return try await processInvited(notificationItem: notificationItem, mediaProvider: mediaProvider)
        case .timeline:
            return try await processTimeline(notificationItem: notificationItem, mediaProvider: mediaProvider)
        }
    }

    /// Same as `content(for:mediaProvider:)` for an item fetched over HTTP.
    func content(for item: HTTPNotificationItem, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        if item.isNeutral {
            return processEmpty(notificationItem: item)
        }
        if item.isInvite {
            return try await processInvited(notificationItem: item, mediaProvider: mediaProvider)
        }
        guard let body = item.body else {
            return processEmpty(notificationItem: item, body: encryptedBody)
        }
        let notification = try await processCommonRoomMessage(notificationItem: item, mediaProvider: mediaProvider)
        notification.body = body
        return notification
    }

    // MARK: - Private

    private var encryptedBody: String {
        L10n.tr("Localizable", "newEncryptedMessageInTwake")
    }
    
    func baseMutableContent(for notificationItem: NotificationItemProxyProtocol) -> UNMutableNotificationContent {
        let notification = UNMutableNotificationContent()
        notification.receiverID = notificationItem.receiverID
        notification.roomID = notificationItem.roomID
        notification.eventID = notificationItem.eventID
        notification.sound = notificationItem.isNoisy ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "message.caf")) : nil
        // So that the UI groups notification that are received for the same room but also for the same user
        // Removing the @ fixes an iOS bug where the notification crashes if the mute button is tapped
        notification.threadIdentifier = "\(notificationItem.receiverID)\(notificationItem.roomID)".replacingOccurrences(of: "@", with: "")
        return notification
    }
    
    private func processTimeline(notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        // Encrypted rooms never show content, even when the extension could decrypt it.
        if notificationItem.isRoomEncrypted || notificationItem.isEncrypted {
            return processEmpty(notificationItem: notificationItem, body: encryptedBody)
        }
        guard case .timeline(let event) = notificationItem.event,
              case .messageLike(content: .roomMessage(messageType: let messageType, inReplyToEventId: _)) = try? event.content() else {
            return processEmpty(notificationItem: notificationItem)
        }
        return try await processRoomMessage(notificationItem: notificationItem, messageType: messageType, mediaProvider: mediaProvider)
    }

    private func processEmpty(notificationItem: NotificationItemProxyProtocol, body: String = L10n.notification) -> UNMutableNotificationContent {
        let notification = baseMutableContent(for: notificationItem)
        notification.title = InfoPlistReader(bundle: .app).bundleDisplayName
        notification.body = body
        notification.categoryIdentifier = NotificationConstants.Category.message
        return notification
    }

    private func processInvited(notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = baseMutableContent(for: notificationItem)

        notification.categoryIdentifier = NotificationConstants.Category.invite

        let body: String
        if !notificationItem.isDM {
            body = L10n.notificationRoomInviteBody
        } else {
            body = L10n.notificationInviteBody
        }

        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderID: notificationItem.senderID,
                                                            senderName: notificationItem.senderDisplayName ?? notificationItem.roomDisplayName,
                                                            icon: icon(for: notificationItem))
        notification.body = body
        
        return notification
    }

    private func processRoomMessage(notificationItem: NotificationItemProxyProtocol, messageType: MessageType, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = try await processCommonRoomMessage(notificationItem: notificationItem, mediaProvider: mediaProvider)
        
        let senderDisplayName = notificationItem.senderDisplayName ?? notificationItem.roomDisplayName
        notification.body = String(messageEventStringBuilder.buildAttributedString(for: messageType, senderDisplayName: senderDisplayName, prefixWithSenderName: false).characters)
        
        switch messageType {
        case .image(content: let content):
            notification = await notification.addMediaAttachment(using: mediaProvider,
                                                                 mediaSource: .init(source: content.source,
                                                                                    mimeType: content.info?.mimetype))
        case .audio(content: let content):
            notification = await notification.addMediaAttachment(using: mediaProvider,
                                                                 mediaSource: .init(source: content.source,
                                                                                    mimeType: content.info?.mimetype))
        case .video(content: let content):
            notification = await notification.addMediaAttachment(using: mediaProvider,
                                                                 mediaSource: .init(source: content.source,
                                                                                    mimeType: content.info?.mimetype))
        default:
            break
        }
        
        return notification
    }

    private func processCommonRoomMessage(notificationItem: NotificationItemProxyProtocol, mediaProvider: MediaProviderProtocol?) async throws -> UNMutableNotificationContent {
        var notification = baseMutableContent(for: notificationItem)
        notification.title = notificationItem.senderDisplayName ?? notificationItem.roomDisplayName
        if notification.title != notificationItem.roomDisplayName {
            notification.subtitle = notificationItem.roomDisplayName
        }
        notification.categoryIdentifier = NotificationConstants.Category.message

        notification = try await notification.addSenderIcon(using: mediaProvider,
                                                            senderID: notificationItem.senderID,
                                                            senderName: notificationItem.senderDisplayName ?? notificationItem.roomDisplayName,
                                                            icon: icon(for: notificationItem))
        return notification
    }
    
    func icon(for notificationItem: NotificationItemProxyProtocol) -> NotificationIcon {
        if notificationItem.isDM {
            return NotificationIcon(mediaSource: notificationItem.senderAvatarMediaSource, groupInfo: nil)
        } else {
            return NotificationIcon(mediaSource: notificationItem.roomAvatarMediaSource,
                                    groupInfo: .init(name: notificationItem.roomDisplayName, id: notificationItem.roomID))
        }
    }
}

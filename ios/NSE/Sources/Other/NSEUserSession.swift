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

final class NSEUserSession {
    private let baseClient: Client
    private let notificationClient: NotificationClient
    private let userID: String
    private let delegateHandle: TaskHandle?
    private(set) lazy var mediaProvider: MediaProviderProtocol = MediaProvider(mediaLoader: MediaLoader(client: baseClient),
                                                                               imageCache: .onlyOnDisk,
                                                                               backgroundTaskService: nil)

    init(credentials: KeychainCredentials,
         roomID: String,
         clientSessionDelegate: ClientSessionDelegate,
         recoveryKey: String?) async throws {
        userID = credentials.userID
        baseClient = try await ClientBuilder()
            .sessionPaths(dataPath: URL.sessionsBaseDirectory(userId: userID, deviceId: credentials.restorationToken.session.deviceId).path,
                          cachePath: URL.cacheBaseDirectory(userId: userID, deviceId: credentials.restorationToken.session.deviceId).path)
            .username(username: credentials.userID)
            .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent())
            .backupDownloadStrategy(backupDownloadStrategy: .afterDecryptionFailure)
            .crossProcessStoreLocksHolderName(holderName: InfoPlistReader.main.bundleIdentifier)
            .setSessionDelegate(sessionDelegate: clientSessionDelegate)
            .build()
        
        delegateHandle = try baseClient.setDelegate(delegate: ClientDelegateWrapper())
        try await baseClient.restoreSessionWith(session: credentials.restorationToken.session,
                                                roomLoadSettings: .one(roomId: roomID))
        
        if let recoveryKey {
            do {
                MXLog.info("NSE: Registering backup recovery key...")
                try await baseClient.encryption().recover(recoveryKey: recoveryKey)
                MXLog.info("NSE: Backup recovery key registered successfully")
            } catch {
                MXLog.warning("NSE: Failed to register backup recovery key (will attempt decryption without it): \(error)")
            }
        } else {
            MXLog.info("NSE: No backup recovery key found in keychain, skipping recovery")
        }

        notificationClient = try await baseClient
            .notificationClient(processSetup: .multipleProcesses)
    }
    
    func notificationItemProxy(roomID: String, eventID: String) async -> NotificationItemProxyProtocol? {
        var proxy: NotificationItemProxyProtocol? = await fetchNotificationItem(roomID: roomID, eventID: eventID)
        if let proxy, !proxy.isEncrypted { return proxy }

        for delay in 1...3 {
            MXLog.info("NSE: Notification is encrypted, retrying in \(delay)s - roomID: \(roomID)")
            try? await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
            
            proxy = await fetchNotificationItem(roomID: roomID, eventID: eventID)
            if let proxy, !proxy.isEncrypted { return proxy }
        }

        return proxy
    }

    private func fetchNotificationItem(roomID: String, eventID: String) async -> NotificationItemProxyProtocol? {
        do {
            let status = try await notificationClient.getNotification(roomId: roomID, eventId: eventID)
            switch status {
            case .event(let notification):
                return NotificationItemProxy(notificationItem: notification,
                                             eventID: eventID,
                                             receiverID: userID,
                                             roomID: roomID)
            case .eventFilteredOut:
                MXLog.info("NSE: Notification event filtered out - roomID: \(roomID) eventID: \(eventID)")
                return nil
            case .eventNotFound:
                MXLog.info("NSE: Notification event not found - roomID: \(roomID) eventID: \(eventID)")
                return nil
            }
        } catch {
            MXLog.error("NSE: Could not get notification's content, error: \(error)")
            return nil
        }
    }
}

private class ClientDelegateWrapper: ClientDelegate {
    // MARK: - ClientDelegate

    func didReceiveAuthError(isSoftLogout: Bool) {
        MXLog.error("Received authentication error, the NSE can't handle this.")
    }
}

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
    private(set) lazy var mediaProvider: MediaProviderProtocol = MediaProvider(mediaLoader: MediaLoader(client: baseClient),
                                                                               imageCache: .onlyOnDisk,
                                                                               backgroundTaskService: nil)

    init(credentials: KeychainCredentials,
         clientSessionDelegate: ClientSessionDelegate,
         recoveryKey: String?) async throws {
        userID = credentials.userID
        baseClient = try await ClientBuilder()
            .sessionPaths(dataPath: URL.sessionsBaseDirectory.path,
                          cachePath: URL.cacheBaseDirectory.path)
            .username(username: credentials.userID)
            .userAgent(userAgent: UserAgentBuilder.makeASCIIUserAgent())
            .backupDownloadStrategy(backupDownloadStrategy: .afterDecryptionFailure)
            .enableCrossProcessRefreshLock(processId: InfoPlistReader.main.bundleIdentifier,
                                           sessionDelegate: clientSessionDelegate)
            .build()
        
        _ = baseClient.setDelegate(delegate: ClientDelegateWrapper())
        try await baseClient.restoreSession(session: credentials.restorationToken.session)
        
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
        do {
            let notification = try await self.notificationClient.getNotification(roomId: roomID, eventId: eventID)
            guard let notification else {
                return nil
            }
            return NotificationItemProxy(notificationItem: notification,
                                         eventID: eventID,
                                         receiverID: self.userID,
                                         roomID: roomID)
        } catch {
            MXLog.error("NSE: Could not get notification's content creating an empty notification instead, error: \(error)")
            return EmptyNotificationItemProxy(eventID: eventID, roomID: roomID, receiverID: self.userID)
        }
    }
}

private class ClientDelegateWrapper: ClientDelegate {
    // MARK: - ClientDelegate

    func didReceiveAuthError(isSoftLogout: Bool) {
        MXLog.error("Received authentication error, the NSE can't handle this.")
    }
    
    func didRefreshTokens() {
        MXLog.info("Delegating session updates to the ClientSessionDelegate.")
    }
}

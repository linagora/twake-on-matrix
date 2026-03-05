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

import CryptoKit
import Foundation

struct Session: Codable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let userId: String
    let deviceId: String
    let homeserverUrl: String
    let oidcData: String?
    let slidingSyncProxy: String?
}

struct RestorationToken: Codable, Equatable {
    let session: Session
    let pusherNotificationClientIdentifier: String?

    init(session: Session) {
        self.session = session
        if let data = session.userId.data(using: .utf8) {
            let digest = SHA256.hash(data: data)
            pusherNotificationClientIdentifier = digest.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            pusherNotificationClientIdentifier = nil
        }
    }
}

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
import KeychainAccess

enum KeychainControllerService: String {
    case sessions
    case tests

    var identifier: String {
        InfoPlistReader.main.baseBundleIdentifier + "." + rawValue
    }
}

class KeychainController: KeychainControllerProtocol {
    private let keychain: Keychain

    init(service: KeychainControllerService, accessGroup: String) {
        keychain = Keychain(service: service.identifier, accessGroup: accessGroup)
    }

    func restorationTokens() -> [KeychainCredentials] {
        keychain.allKeys().compactMap { username in
            guard let tokenData = try? keychain.getData(username),
                  let token = try? JSONDecoder().decode(RestorationToken.self, from: tokenData)
            else {
                return nil
            }
            return KeychainCredentials(userID: username, restorationToken: token)
        }
    }
}

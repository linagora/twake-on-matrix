import Foundation

struct KeychainSharingData: Codable {
    let homeserverUrl: String
    let token: String
    let userId: String
    let deviceId: String?
    let deviceName: String?
    let prevBatch: String?
    let olmAccount: String?
}

extension KeychainSharingData {
    init(data: Data) throws {
        self = try JSONDecoder().decode(KeychainSharingData.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
}

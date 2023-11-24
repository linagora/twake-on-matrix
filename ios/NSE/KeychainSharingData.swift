import Foundation

struct HashDetail: Codable {
    let homeserverUrl: String
    let token: String
    let userId: String
    let deviceId: String?
    let deviceName: String?
    let prevBatch: String?
    let olmAccount: String?
}

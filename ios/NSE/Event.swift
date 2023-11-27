import Foundation

// MARK: - Event
struct Event: Codable {
    let content: Content?
    let originServerTs: Int?
    let roomID, sender, type: String?
    let unsigned: Unsigned?
    let eventID, userID: String?
    let age: Int?

    enum CodingKeys: String, CodingKey {
        case content
        case originServerTs = "origin_server_ts"
        case roomID = "room_id"
        case sender, type, unsigned
        case eventID = "event_id"
        case userID = "user_id"
        case age
    }
}

// MARK: - Content
struct Content: Codable {
    let body, msgtype: String?
}

// MARK: - Unsigned
struct Unsigned: Codable {
    let age: Int?
}

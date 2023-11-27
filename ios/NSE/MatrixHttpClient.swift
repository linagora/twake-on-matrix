import Foundation
import Alamofire

class MatrixHttpClient {
    let homeserverUrl: String
    let token: String
    
    lazy var headers: HTTPHeaders = {
        let headers: HTTPHeaders = [.authorization(bearerToken: token)]
        return headers
    }()
    
    init(homeserverUrl: String, token: String) {
        self.homeserverUrl = homeserverUrl
        self.token = token
    }
    
    func getEvent(eventId: String, roomId: String, completion: @escaping (Event?) -> ()) {
        let url = "\(homeserverUrl)/_matrix/client/v3/rooms/\(roomId)/event/\(eventId)"
        AF.request(url, headers: headers)
            .responseDecodable(of: Event.self) { response in
                switch response.result {
                case .success(let event):
                    completion(event)
                case .failure(_):
                    completion(nil)
                }
            }
    }
}

//
//  AuthAPI.swift
//  netdata
//
//  Created by Arjun on 25/12/2023.
//

import Foundation
import Alamofire

struct AuthTokenResult: Codable {
    var token: String
}

struct AuthAPI {
#if DEBUG
    static let API_BASE_URL = "https://netdata-ios-dev.web.app/auth"
#else
    static let API_BASE_URL = "https://netdata.techulus.com/auth"
#endif
    
    static func createToken(uid: String) async throws -> AuthTokenResult {
        let parameters: [String: String] = [
            "userId": uid
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                API_BASE_URL + "/create-token",
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default
            )
            .responseDecodable(of: AuthTokenResult.self) { response in
                switch(response.result) {
                case let .success(data):
                    continuation.resume(returning: data)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

//
//  Agent.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import Foundation
import Combine

enum APIError: Error {
    case userIsOffline
    case authenticationFailed
    case somethingWentWrong
}

struct Agent {
    struct Response<T> {
        let value: T
        let response: URLResponse
    }
    
    func run<T: Decodable>(_ request: URLRequest, _ decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<Response<T>, Error> {
        return URLSession.shared
            .dataTaskPublisher(for: request)
            .tryMap { result -> Response<T> in
                guard let httpResponse = result.response as? HTTPURLResponse,
                      httpResponse.statusCode > 0 else {
                    throw URLError(.unknown)
                }
                
                // Handle basic authentication error
                if httpResponse.statusCode == 401 {
                    throw URLError(.userAuthenticationRequired)
                }
                
                let value = try decoder.decode(T.self, from: result.data)
                return Response(value: value, response: result.response)
            }
            .mapError { error -> APIError in
                debugPrint(error)
                
                switch error {
                case URLError.notConnectedToInternet:
                    return .userIsOffline
                case URLError.userAuthenticationRequired:
                    return .authenticationFailed
                default:
                    return .somethingWentWrong
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

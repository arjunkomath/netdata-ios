//
//  Network.swift
//  fiftybest
//
//  Created by thomas on 7/1/20.
//  Copyright © 2020 thomas. All rights reserved.
//

import Foundation
import Combine

enum NetDataEndpoint: String {
    case info = "/api/v1/info"
    case data = "/api/v1/data?chart="
}

enum NetDataAPI {
    static let agent = Agent()
}

extension NetDataAPI {
    static func getInfo(baseUrl: String) -> AnyPublisher<NDServer, Error> {
        let base = URL(string: baseUrl)!
        
        return run(URLRequest(url: base.appendingPathComponent(NetDataEndpoint.info.rawValue)))
    }
    
    static func getChartData(baseUrl: String, chart: String) -> AnyPublisher<NDChartData, Error> {
        let base = URL(string: baseUrl)!
        
        return run(URLRequest(url: base.appendingPathComponent(NetDataEndpoint.data.rawValue + chart)))
    }
    
    static func run<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
            return agent.run(request)
                .map(\.value)
                .eraseToAnyPublisher()
        }
}

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
    case alarms = "/api/v1/alarms"
}

enum NetDataAPI {
    static let agent = Agent()
}

extension NetDataAPI {
    static func getInfo(baseUrl: String) -> AnyPublisher<ServerInfo, Error> {
        let base = URL(string: baseUrl)!
        
        return run(URLRequest(url: base.appendingPathComponent(NetDataEndpoint.info.rawValue)))
    }
    
    static func getChartData(baseUrl: String, chart: String) -> AnyPublisher<ServerData, Error> {
        let base = URL(string: baseUrl)!
        
        return run(URLRequest(url: base.appendingPathComponent(NetDataEndpoint.data.rawValue + chart)))
    }
    
    static func getAlarms(baseUrl: String) -> AnyPublisher<ServerAlarms, Error> {
        let base = URL(string: baseUrl)!
        
        return run(URLRequest(url: base.appendingPathComponent(NetDataEndpoint.alarms.rawValue)))
    }
    
    static func run<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }
}

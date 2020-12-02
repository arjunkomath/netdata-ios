//
//  Network.swift
//
//  Created by thomas on 7/1/20.
//  Copyright © 2020 thomas. All rights reserved.
//

import Foundation
import Combine

enum NetDataEndpoint: String {
    case info = "/api/v1/info"
    case charts = "/api/v1/charts"
    case data = "/api/v1/data?chart="
    case alarms = "/api/v1/alarms"
}

enum NetDataAPI {
    static let agent = Agent()
}

extension NetDataAPI {
    static func getInfo(baseUrl: String, basicAuthBase64: String = "") -> AnyPublisher<ServerInfo, Error> {
        let requestUrl = URL(string: baseUrl)!.appendingPathComponent(NetDataEndpoint.info.rawValue)
        
        return run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    static func getCharts(baseUrl: String, basicAuthBase64: String = "") -> AnyPublisher<ServerCharts, Error> {
        let requestUrl = URL(string: baseUrl)!.appendingPathComponent(NetDataEndpoint.charts.rawValue)
        
        return run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    static func getChartData(baseUrl: String, chart: String, basicAuthBase64: String = "") -> AnyPublisher<ServerData, Error> {
        let requestUrl = URL(string: baseUrl)!.appendingPathComponent(NetDataEndpoint.data.rawValue + chart)
        
        return run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    static func getAlarms(baseUrl: String, basicAuthBase64: String = "") -> AnyPublisher<ServerAlarms, Error> {
        let requestUrl = URL(string: baseUrl)!.appendingPathComponent(NetDataEndpoint.alarms.rawValue)
        
        return run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    static func run<T: Decodable>(requestUrl: URL, basicAuthBase64: String) -> AnyPublisher<T, Error> {
        var request = URLRequest(url: requestUrl)
        
        if !basicAuthBase64.isEmpty {
            request.setValue("Basic \(basicAuthBase64)", forHTTPHeaderField: "Authorization")
        }
        
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }
}

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

enum APIError: Error {
    case userIsOffline
    case authenticationFailed
    case somethingWentWrong
}

struct NetdataClient {
    var session = URLSession.shared

    func getInfo(baseUrl: String, basicAuthBase64: String = "") async throws -> ServerInfo {
        let requestUrl = URL(string: baseUrl)!.appendingPathComponent(NetDataEndpoint.info.rawValue)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getAlarms(baseUrl: String, basicAuthBase64: String = "") async throws -> ServerAlarms {
        let requestUrl = URL(string: baseUrl)!.appendingPathComponent(NetDataEndpoint.alarms.rawValue)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getCharts(baseUrl: String, basicAuthBase64: String = "") async throws -> ServerCharts {
        let requestUrl = URL(string: baseUrl)!.appendingPathComponent(NetDataEndpoint.charts.rawValue)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getChartData(baseUrl: String, basicAuthBase64: String = "", chart: String) async throws -> ServerData {
        let requestUrl = URL(string: baseUrl)!.appendingPathComponent(NetDataEndpoint.data.rawValue + chart)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    private func run<T: Decodable>(requestUrl: URL, basicAuthBase64: String) async throws -> T {
        var request = URLRequest(url: requestUrl)
        
        if !basicAuthBase64.isEmpty {
            request.setValue("Basic \(basicAuthBase64)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        let response = try decoder.decode(T.self, from: data)
        return response
    }
}

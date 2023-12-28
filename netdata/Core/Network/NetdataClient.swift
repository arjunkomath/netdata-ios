//
//  Network.swift
//
//  Created by thomas on 7/1/20.
//  Copyright © 2020 thomas. All rights reserved.
//

import Foundation
import Alamofire

enum NetDataEndpoint: String {
    case info = "/api/v1/info"
    case charts = "/api/v1/charts"
    case data = "/api/v1/data"
    case alarms = "/api/v1/alarms"
}

enum APIError: Error {
    case userIsOffline
    case authenticationFailed
    case somethingWentWrong
    case invalidRequest
}

public class NetdataClient {
    public static let shared = NetdataClient()
    
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
        // after=-10&points=10
        var request = URLComponents(string: baseUrl + NetDataEndpoint.data.rawValue)!
        request.queryItems = [
            URLQueryItem(name: "after", value: "-1"),
            URLQueryItem(name: "points", value: "1"),
            URLQueryItem(name: "chart", value: chart)
        ];
        
        if let url = request.url {
            return try await run(requestUrl: url, basicAuthBase64: basicAuthBase64)
        }
        
        throw APIError.invalidRequest
    }
    
    func getChartDataWithHistory(baseUrl: String, basicAuthBase64: String = "", chart: String) async throws -> ServerData {
        var request = URLComponents(string: baseUrl + NetDataEndpoint.data.rawValue)!
        
        request.queryItems = [
            URLQueryItem(name: "after", value: "-15"),
            URLQueryItem(name: "points", value: "15"),
            URLQueryItem(name: "gtime", value: "60"),
            URLQueryItem(name: "chart", value: chart)
        ];
        
        if let url = request.url {
            return try await run(requestUrl: url, basicAuthBase64: basicAuthBase64)
        }
        
        throw APIError.invalidRequest
    }
    
    private func run<T: Decodable>(requestUrl: URL, basicAuthBase64: String) async throws -> T {
        var headers: HTTPHeaders = [
            "Cache-Control": "no-cache"
        ]
        
        if !basicAuthBase64.isEmpty {
            headers["Authorization"] = "Basic \(basicAuthBase64)"
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                requestUrl.absoluteString,
                method: .get,
                encoding: JSONEncoding.default,
                headers: headers
            )
            .responseDecodable(of: T.self) { response in
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

//
//  Network.swift
//
//  Created by thomas on 7/1/20.
//  Copyright © 2020 thomas. All rights reserved.
//

import Foundation
import Alamofire

enum NetDataEndpoint: String {
    case info = "api/v1/info"
    case charts = "api/v1/charts"
    case data = "api/v1/data"
    case alarms = "api/v1/alarms"
}

enum APIError: Error {
    case userIsOffline
    case authenticationFailed
    case somethingWentWrong
    case invalidRequest
}

public class NetdataClient {
    public static let shared = NetdataClient()
    
    func getInfo(baseUrl: String, basicAuthBase64: String = "") async throws -> ServerInfo {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .info)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getAlarms(baseUrl: String, basicAuthBase64: String = "") async throws -> ServerAlarms {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .alarms)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getCharts(baseUrl: String, basicAuthBase64: String = "") async throws -> ServerCharts {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .charts)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getChartData(baseUrl: String, basicAuthBase64: String = "", chart: String) async throws -> ServerData {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .data, queryItems: [
            URLQueryItem(name: "after", value: "-1"),
            URLQueryItem(name: "points", value: "1"),
            URLQueryItem(name: "chart", value: chart)
        ])
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getChartDataWithHistory(baseUrl: String, basicAuthBase64: String = "", chart: String) async throws -> ServerData {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .data, queryItems: [
            URLQueryItem(name: "after", value: "-900"),
            URLQueryItem(name: "points", value: "15"),
            URLQueryItem(name: "chart", value: chart)
        ])
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }

    private func makeRequestURL(baseUrl: String, endpoint: NetDataEndpoint, queryItems: [URLQueryItem] = []) throws -> URL {
        guard let baseURL = URL(string: baseUrl),
              let scheme = baseURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              baseURL.host != nil,
              baseURL.fragment == nil,
              var components = URLComponents(
                url: baseURL.appendingPathComponent(endpoint.rawValue),
                resolvingAgainstBaseURL: false
              ) else {
            throw APIError.invalidRequest
        }

        let mergedQueryItems = (components.queryItems ?? []) + queryItems
        components.queryItems = mergedQueryItems.isEmpty ? nil : mergedQueryItems

        guard let requestURL = components.url else {
            throw APIError.invalidRequest
        }

        return requestURL
    }
    
    private func run<T: Decodable>(requestUrl: URL, basicAuthBase64: String) async throws -> T {
        var headers: HTTPHeaders = [
            "Cache-Control": "no-cache"
        ]
        
        if !basicAuthBase64.isEmpty {
            headers["Authorization"] = "Basic \(basicAuthBase64)"
        }
        
        do {
            return try await AF.request(
                requestUrl,
                method: .get,
                headers: headers
            )
            .validate(statusCode: 200..<300)
            .serializingDecodable(T.self)
            .value
        } catch {
            guard !Task.isCancelled else { throw CancellationError() }

            debugPrint("[NetdataClient] Request failed:", error)

            let afError = error as? AFError
            let urlError = (afError?.underlyingError ?? error) as? URLError

            if afError?.responseCode == 401 || urlError?.code == .userAuthenticationRequired {
                throw APIError.authenticationFailed
            }
            if urlError?.code == .notConnectedToInternet {
                throw APIError.userIsOffline
            }
            throw APIError.somethingWentWrong
        }
    }
}

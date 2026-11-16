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
    case contexts = "api/v3/contexts"
    case nodes = "api/v3/nodes"
}

enum APIError: Error {
    case userIsOffline
    case authenticationFailed
    case somethingWentWrong
    case invalidRequest
    /// The Agent answered 404: on a Parent this usually means the selected node has no data stored, or is unknown.
    case notFound
}

extension APIError {
    func listMessage(subject: String) -> String {
        switch self {
        case .authenticationFailed:
            return "The server rejected the saved credentials. Edit the server to update them."
        case .userIsOffline:
            return "You appear to be offline."
        case .notFound:
            return "This node's \(subject) aren't available. It may be unknown to this Parent or no longer streaming."
        default:
            return "Unable to load \(subject). Check the server connection."
        }
    }
}

public class NetdataClient {
    public static let shared = NetdataClient()
    
    // `node` is a machine GUID. When set, the request goes through the Parent's `/host/<guid>/` route
    // so it returns that Child's data; nil talks to the Agent behind `baseUrl` itself, as before.

    func getInfo(baseUrl: String, basicAuthBase64: String = "", node: String? = nil) async throws -> ServerInfo {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, node: node, endpoint: .info)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getAlarms(baseUrl: String, basicAuthBase64: String = "", node: String? = nil) async throws -> ServerAlarms {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, node: node, endpoint: .alarms)
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    /// Prefers v3 contexts, which is roughly a tenth of the size of `/api/v1/charts`, and falls back
    /// to v1 for agents that predate v3.
    func getCharts(baseUrl: String, basicAuthBase64: String = "", node: String? = nil) async throws -> ServerCharts {
        do {
            return try await getChartsV3(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, node: node)
        } catch APIError.somethingWentWrong, APIError.notFound {
            let requestUrl = try makeRequestURL(baseUrl: baseUrl, node: node, endpoint: .charts)
            return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
        }
    }

    private func getChartsV3(baseUrl: String, basicAuthBase64: String, node: String?) async throws -> ServerCharts {
        let queryItems = [
            URLQueryItem(name: "options", value: "titles,instances,minify"),
            // Without a window v3 also lists archived instances (e.g. apps that have exited), which v1 omits.
            URLQueryItem(name: "after", value: "-600")
        ]

        // v3 ignores the `/host/<guid>/` route, so a Child is selected with `scope_nodes` instead.
        if let node, !node.isEmpty {
            let scopedUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .contexts, queryItems: queryItems + [
                URLQueryItem(name: "scope_nodes", value: node)
            ])
            let scoped: ServerContexts = try await run(requestUrl: scopedUrl, basicAuthBase64: basicAuthBase64)
            return scoped.serverCharts
        }

        let requestUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .contexts, queryItems: queryItems)
        let contexts: ServerContexts = try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)

        // On a parent, v3 spans every streaming child, but v1 data queries only reach the parent's own
        // charts, so narrow to the agent we're talking to.
        guard (contexts.nodes?.count ?? 0) > 1, let machineGuid = contexts.agents?.first?.mg else {
            return contexts.serverCharts
        }
        let scopedUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .contexts, queryItems: queryItems + [
            URLQueryItem(name: "scope_nodes", value: machineGuid)
        ])
        let scoped: ServerContexts = try await run(requestUrl: scopedUrl, basicAuthBase64: basicAuthBase64)
        return scoped.serverCharts
    }
    
    func getChartData(baseUrl: String, basicAuthBase64: String = "", node: String? = nil, chart: String) async throws -> ServerData {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, node: node, endpoint: .data, queryItems: [
            URLQueryItem(name: "after", value: "-1"),
            URLQueryItem(name: "points", value: "1"),
            URLQueryItem(name: "chart", value: chart)
        ])
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }
    
    func getChartDataWithHistory(baseUrl: String, basicAuthBase64: String = "", node: String? = nil, chart: String, range: HistoryRange) async throws -> ServerData {
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, node: node, endpoint: .data, queryItems: [
            URLQueryItem(name: "after", value: "-\(range.seconds)"),
            URLQueryItem(name: "points", value: "\(range.points)"),
            URLQueryItem(name: "chart", value: chart)
        ])
        
        return try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)
    }

    /// Lists the nodes whose metrics this Agent stores. Agents older than v2 answer 404, which callers treat as
    /// "standalone Agent".
    func getNodes(baseUrl: String, basicAuthBase64: String = "") async throws -> [NetdataNode] {
        // `options=mcp` adds each node's `relationship`, which is the documented way to tell the Parent from its Children.
        let requestUrl = try makeRequestURL(baseUrl: baseUrl, endpoint: .nodes, queryItems: [
            URLQueryItem(name: "options", value: "mcp")
        ])
        let response: NetdataNodes = try await run(requestUrl: requestUrl, basicAuthBase64: basicAuthBase64)

        return response.nodes ?? []
    }

    private func makeRequestURL(baseUrl: String, node: String? = nil, endpoint: NetDataEndpoint, queryItems: [URLQueryItem] = []) throws -> URL {
        guard let baseURL = URL(string: baseUrl),
              let scheme = baseURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              baseURL.host != nil,
              baseURL.fragment == nil else {
            throw APIError.invalidRequest
        }

        var agentURL = baseURL
        if let node, !node.isEmpty {
            agentURL = agentURL.appendingPathComponent("host").appendingPathComponent(node)
        }

        guard var components = URLComponents(
            url: agentURL.appendingPathComponent(endpoint.rawValue),
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
            // Lets a cancelled refresh (e.g. after switching nodes) drop its request instead of finishing it.
            .serializingDecodable(T.self, automaticallyCancelling: true)
            .value
        } catch {
            guard !Task.isCancelled else { throw CancellationError() }

            debugPrint("[NetdataClient] Request failed:", error)

            let afError = error as? AFError
            let urlError = (afError?.underlyingError ?? error) as? URLError

            if afError?.responseCode == 401 || urlError?.code == .userAuthenticationRequired {
                throw APIError.authenticationFailed
            }
            if afError?.responseCode == 404 {
                throw APIError.notFound
            }
            if urlError?.code == .notConnectedToInternet {
                throw APIError.userIsOffline
            }
            throw APIError.somethingWentWrong
        }
    }
}

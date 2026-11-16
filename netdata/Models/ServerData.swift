//
//  NDServerData.swift
//  netdata
//
//  Created by Arjun Komath on 19/7/20.
//

import Foundation

public struct ServerData: Decodable {
    static let empty = ServerData(labels: [], data: [])

    var labels: [String]
    var data: [[Double?]]
}

enum HistoryRange: String, CaseIterable, Identifiable {
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case oneHour = "1h"
    case sixHours = "6h"
    case oneDay = "24h"

    static let storageKey = "historyRange"
    static let defaultRange: HistoryRange = .fiveMinutes

    var id: String { rawValue }

    var shortTitle: String { rawValue }

    var title: String {
        switch self {
        case .fiveMinutes: return "Last 5 minutes"
        case .fifteenMinutes: return "Last 15 minutes"
        case .oneHour: return "Last hour"
        case .sixHours: return "Last 6 hours"
        case .oneDay: return "Last 24 hours"
        }
    }

    var seconds: Int {
        switch self {
        case .fiveMinutes: return 5 * 60
        case .fifteenMinutes: return 15 * 60
        case .oneHour: return 60 * 60
        case .sixHours: return 6 * 60 * 60
        case .oneDay: return 24 * 60 * 60
        }
    }

    /// Keeps every range at roughly 100 points, enough to show short spikes without making
    /// longer ranges heavier to fetch or draw.
    var points: Int {
        switch self {
        case .fiveMinutes: return 100     // 3s each
        case .fifteenMinutes: return 90   // 10s
        case .oneHour: return 120         // 30s
        case .sixHours: return 120        // 3m
        case .oneDay: return 144          // 10m
        }
    }

    /// Refetching faster than a point's width only redraws the same averages.
    var refreshInterval: Duration {
        switch self {
        case .fiveMinutes: return .seconds(5)
        case .fifteenMinutes: return .seconds(15)
        case .oneHour: return .seconds(30)
        case .sixHours: return .seconds(120)
        case .oneDay: return .seconds(300)
        }
    }
}

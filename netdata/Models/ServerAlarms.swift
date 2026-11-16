//
//  ServerAlarms.swift
//  netdata
//
//  Created by Arjun Komath on 28/7/20.
//

import Foundation

public struct ServerAlarm: Codable {
    var id: Int?
    var status: String?
    /// The alert's config name (e.g. "lowest_entropy"). Shared by every chart the alert runs on, so it
    /// isn't unique within a server.
    var name: String?
    var chart: String?
    var info: String?
    /// A readable one-liner sent by newer Agents.
    var summary: String?
    var units: String?
    /// The value that raised the alarm, already formatted with its units (e.g. "100%").
    var value_string: String?
    var last_status_change: Double?
}

extension ServerAlarm {
    var isCritical: Bool { status == "CRITICAL" }
    var isWarning: Bool { status == "WARNING" }

    var title: String {
        if let summary, !summary.isEmpty { return summary }
        return name ?? "Unknown alarm"
    }

    /// When the alarm entered its current status.
    var statusSince: Date? {
        last_status_change.map { Date(timeIntervalSince1970: $0) }
    }
}

public struct ServerAlarms: Codable {
    var status: Bool?
    var alarms: [String: ServerAlarm]?

    public var criticalAlarmsCount: Int {
        guard let alarms = alarms else { return 0 }
        return alarms.values.filter { $0.status == "CRITICAL" }.count
    }
}

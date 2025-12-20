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
    var name: String?
    var info: String?
    var last_status_change: Double?
}

public struct ServerAlarms: Codable {
    var status: Bool?
    var alarms: [String: ServerAlarm]?

    public var criticalAlarmsCount: Int {
        guard let alarms = alarms else { return 0 }
        return alarms.values.filter { $0.status == "CRITICAL" }.count
    }
}

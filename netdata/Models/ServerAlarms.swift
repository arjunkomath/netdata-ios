//
//  ServerAlarms.swift
//  netdata
//
//  Created by Arjun Komath on 28/7/20.
//

import Foundation

public struct ServerAlarm: Encodable, Decodable {
    var id: Int;
    var status: String;
    var name: String;
    var info: String;
    var last_status_change: Double;
}

public struct ServerAlarms: Encodable, Decodable {
    var status: Bool;
    var alarms: [String: ServerAlarm];
    
    public var criticalAlarmsCount: Int {
        get {
            return self.alarms.keys.sorted()
                .reduce(0, { acc, key in acc + (self.alarms[key]?.status == "CRITICAL" ? 1 : 0) })
        }
    }
}

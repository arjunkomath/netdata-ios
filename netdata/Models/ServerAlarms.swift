//
//  ServerAlarms.swift
//  netdata
//
//  Created by Arjun Komath on 28/7/20.
//

import Foundation

public struct ServerAlarm: Encodable, Decodable {
    var name: String;
    var status: String;
}

public struct ServerAlarms: Encodable, Decodable {
    var status: Bool;
    var alarms: [String: [ServerAlarm]];
}

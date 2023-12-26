//
//  UserData.swift
//  netdata
//
//  Created by Arjun on 25/12/2023.
//

import Foundation

struct UserData: Codable {
    var api_key: String
    var enable_alert_notifications: Bool
    var device_tokens: [String]
}

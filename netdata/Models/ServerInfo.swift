//
//  NDServerInfo.swift
//  netdata
//
//  Created by Arjun Komath on 18/7/20.
//

import Foundation

public struct ServerInfo: Encodable, Decodable {
    var uid: String;
    var os_name: String;
    var os_version: String;
    var kernel_name: String;
    var architecture: String;
    var cores_total: String;
    var ram_total: String;
}

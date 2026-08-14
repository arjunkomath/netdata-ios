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

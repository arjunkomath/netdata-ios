//
//  ServerCharts.swift
//  netdata
//
//  Created by Arjun Komath on 1/8/20.
//

import Foundation

public struct ServerChart: Encodable, Decodable, Identifiable {
    public var id: String;
    var name: String;
    var type: String;
    var family: String;
    var context: String;
    var title: String;
    var units: String;
}

public struct ServerCharts: Encodable, Decodable {
    var version: String;
    var release_channel: String;
    var charts: [String: ServerChart];
    
    public var activeCharts: [ServerChart] {
        return charts.keys.sorted()
            .filter {
                charts[$0] != nil
            }
            .map {
                charts[$0]!
            }
    }
}

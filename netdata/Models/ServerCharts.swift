//
//  ServerCharts.swift
//  netdata
//
//  Created by Arjun Komath on 1/8/20.
//

import Foundation

public struct ServerChart: Encodable, Decodable, Identifiable, Hashable {
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

extension ServerChart {
    /// Netdata titles usually end with the chart id in parentheses, e.g.
    /// "Disk Space Usage (disk_space._)"; drop it when it just repeats the id.
    var displayTitle: String {
        let title = title.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return name }

        let redundantSuffix = [id, name, context]
            .map { " (\($0))" }
            .first { title.hasSuffix($0) }

        return redundantSuffix.map { String(title.dropLast($0.count)) } ?? title
    }

    var displayUnits: String {
        units == "seconds" ? "hours" : units
    }
}

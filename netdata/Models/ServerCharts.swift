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
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return name }
        if trimmed.hasSuffix(")"), let open = trimmed.range(of: " (", options: .backwards) {
            let inner = trimmed[open.upperBound..<trimmed.index(before: trimmed.endIndex)]
            if [id, name, context].contains(String(inner)) {
                return String(trimmed[..<open.lowerBound])
            }
        }
        return trimmed
    }

    var displayUnits: String {
        units == "seconds" ? "hours" : units
    }
}

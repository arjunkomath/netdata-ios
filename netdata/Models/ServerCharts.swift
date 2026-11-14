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
    static let empty = ServerCharts(charts: [:])

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

/// `/api/v3/contexts?options=titles,instances` response.
struct ServerContexts: Decodable {
    struct Node: Decodable {
        var mg: String?
    }

    struct Agent: Decodable {
        var mg: String?
    }

    struct Context: Decodable {
        var title: String?
        var family: String?
        var units: String?
        var instances: [String]?
    }

    var nodes: [Node]?
    var agents: [Agent]?
    var contexts: [String: Context]

    /// Flattens contexts into per-instance charts, matching the shape of `/api/v1/charts`.
    var serverCharts: ServerCharts {
        var charts: [String: ServerChart] = [:]
        for (context, info) in contexts {
            for instance in info.instances ?? [] {
                let parts = instance.split(separator: ".", maxSplits: 1)
                let type = parts.first.map(String.init) ?? instance
                let suffix = parts.count > 1 ? String(parts[1]) : instance
                let family = info.family ?? ""

                charts[instance] = ServerChart(
                    id: instance,
                    name: instance,
                    type: type,
                    // v3 reports family per context; "[x]" marks where instances disagree, and the
                    // instance suffix is what v1 reported as the family in those cases (e.g. "sda").
                    family: family.contains("[x]") ? suffix : family,
                    context: context,
                    title: info.title ?? context,
                    units: info.units ?? ""
                )
            }
        }
        return ServerCharts(charts: charts)
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

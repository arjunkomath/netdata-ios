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

    /// Groups charts by the first part of their context ("disk" for "disk.io"). The type would split
    /// one kind of chart per device or container ("disk_sda", "cgroup_nginx").
    var category: String {
        let prefix = context.split(separator: ".").first.map(String.init) ?? ""
        return ChartCategory.canonical(prefix.isEmpty ? type : prefix)
    }
}

enum ChartCategory {
    /// Host-wide categories first, in the order people usually look at them; unknown collectors
    /// sort alphabetically after these, with Netdata's own monitoring last.
    private static let leading = ["system", "cpu", "mem", "disk", "net", "ip", "ipv4", "ipv6",
                                  "app", "user", "usergroup", "systemd", "services", "cgroup", "k8s"]
    private static let trailing = ["netdata"]

    /// Older agents name the per-process contexts in the plural ("apps.cpu"), newer ones in the
    /// singular ("app.cpu_utilization").
    private static let aliases = ["apps": "app", "users": "user", "groups": "usergroup"]

    static func canonical(_ category: String) -> String {
        aliases[category] ?? category
    }

    private static let titles = [
        "system": "System", "cpu": "CPU", "mem": "Memory", "disk": "Disks", "net": "Network",
        "ip": "IP", "ipv4": "IPv4", "ipv6": "IPv6", "app": "Applications", "user": "Users",
        "usergroup": "User Groups",
        "systemd": "systemd", "services": "Services", "cgroup": "Containers & VMs",
        "k8s": "Kubernetes", "netdata": "Netdata", "nfs": "NFS", "nfsd": "NFS Server",
        "zfs": "ZFS", "btrfs": "Btrfs", "mdstat": "RAID", "nvme": "NVMe", "sctp": "SCTP",
        "netfilter": "Netfilter", "smartctl": "S.M.A.R.T.", "sensors": "Sensors",
    ]

    static func title(for category: String) -> String {
        titles[category] ?? category
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    static func areInIncreasingOrder(_ lhs: String, _ rhs: String) -> Bool {
        func rank(_ category: String) -> Int {
            if let index = leading.firstIndex(of: category) { return index }
            return trailing.contains(category) ? Int.max : leading.count
        }

        let (lhsRank, rhsRank) = (rank(lhs), rank(rhs))
        if lhsRank != rhsRank { return lhsRank < rhsRank }
        return title(for: lhs).localizedStandardCompare(title(for: rhs)) == .orderedAscending
    }
}

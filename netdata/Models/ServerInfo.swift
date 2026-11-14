//
//  NDServerInfo.swift
//  netdata
//
//  Created by Arjun Komath on 18/7/20.
//

import Foundation

public struct ServerInfo: Codable {
    var uid: String?
    var os_name: String?
    var os_version: String?
    var kernel_name: String?
    var architecture: String?
    var cores_total: String?
    var ram_total: String?
}

/// Response of `/api/v3/nodes`. A standalone Agent lists only itself; a Parent also lists every Child it stores.
struct NetdataNodes: Decodable {
    let nodes: [NetdataNode]?
}

struct NetdataNode: Decodable, Identifiable, Equatable {
    struct Health: Decodable {
        struct Alerts: Decodable {
            let critical: Int?
            let warning: Int?
        }

        let status: String?
        let alerts: Alerts?
    }

    struct Hardware: Decodable {
        let architecture: String?
        let cpus: String?
        let memory: String?
    }

    struct OperatingSystem: Decodable {
        struct Kernel: Decodable {
            let nm: String?
            let v: String?
        }

        let nm: String?
        let v: String?
        let kernel: Kernel?
    }

    /// Machine GUID, which is what `/host/<guid>/api/v1/...` routes on.
    let mg: String
    let nm: String
    /// Position in this Agent's node list; only sent without `options=mcp`.
    let ni: Int?
    let v: String?
    /// "reachable" while the node streams to this Agent, "stale" once it has disconnected.
    let state: String?
    /// "localhost" for the Agent answering the request, "child" for a streamed node, "virtual" for a virtual host.
    let relationship: String?
    let connected: Bool?
    let health: Health?
    let hw: Hardware?
    let os: OperatingSystem?

    // `options=mcp` spells the identity fields out (`machine_guid`, `hostname`) and adds `relationship` and
    // `connected`; agents that don't know the option keep the short keys, so both are accepted.
    private enum CodingKeys: String, CodingKey {
        case mg, machine_guid, nm, hostname, ni, v, state, relationship, connected, health, hw, os
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mg = try container.decodeIfPresent(String.self, forKey: .machine_guid)
            ?? container.decode(String.self, forKey: .mg)
        nm = try container.decodeIfPresent(String.self, forKey: .hostname)
            ?? container.decodeIfPresent(String.self, forKey: .nm)
            ?? mg
        ni = try? container.decodeIfPresent(Int.self, forKey: .ni)
        v = try? container.decodeIfPresent(String.self, forKey: .v)
        state = try? container.decodeIfPresent(String.self, forKey: .state)
        relationship = try? container.decodeIfPresent(String.self, forKey: .relationship)
        connected = try? container.decodeIfPresent(Bool.self, forKey: .connected)
        health = try? container.decodeIfPresent(Health.self, forKey: .health)
        hw = try? container.decodeIfPresent(Hardware.self, forKey: .hw)
        os = try? container.decodeIfPresent(OperatingSystem.self, forKey: .os)
    }

    var id: String { mg }

    var isReachable: Bool { connected ?? (state == "reachable") }

    var isLocalhost: Bool { relationship == "localhost" }

    var criticalAlerts: Int { health?.alerts?.critical ?? 0 }
    var warningAlerts: Int { health?.alerts?.warning ?? 0 }

    /// The subset of `/api/v1/info` the detail screen uses, so a Child's cards don't need another request.
    var serverInfo: ServerInfo {
        ServerInfo(uid: mg,
                   os_name: os?.nm,
                   os_version: os?.v,
                   kernel_name: os?.kernel?.nm,
                   architecture: hw?.architecture,
                   cores_total: hw?.cpus,
                   ram_total: hw?.memory)
    }

    static func == (lhs: NetdataNode, rhs: NetdataNode) -> Bool {
        lhs.mg == rhs.mg && lhs.nm == rhs.nm && lhs.isReachable == rhs.isReachable
            && lhs.criticalAlerts == rhs.criticalAlerts && lhs.warningAlerts == rhs.warningAlerts
    }
}

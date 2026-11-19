//
//  ChartListRow.swift
//  netdata
//
//  Created by Arjun Komath on 1/8/20.
//

import SwiftUI

struct ChartListRow: View {
    var chart: ServerChart
    var isPinned = false
    var togglePin: () -> Void = {}

    var body: some View {
        NavigationLink(value: chart) {
            VStack(alignment: .leading, spacing: 4) {
                Text(chart.displayTitle)
                    .lineLimit(2)

                // Instances of one chart share a title, so the id is what tells "disk.sda" from "disk.sdb".
                // Units sit here rather than beside the title, where long ones ("context switches/s")
                // squeezed it onto two lines.
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.orange)
                    }

                    Text(chart.id)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: 8)

                    Text(chart.displayUnits)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
        }
        .swipeActions(edge: .leading) {
            pinButton
                .tint(.orange)
        }
        .contextMenu {
            pinButton
        }
        .accessibilityAction(named: isPinned ? "Unpin" : "Pin", togglePin)
    }

    private var accessibilityLabel: String {
        [chart.displayTitle, chart.displayUnits, chart.id, isPinned ? "Pinned" : nil]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: ", ")
    }

    private var pinButton: some View {
        Button(action: togglePin) {
            Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
        }
    }
}

extension ServerChart {
    static let placeholder = ServerChart(id: "system.placeholder",
                                         name: "system.placeholder",
                                         type: "system",
                                         family: "",
                                         context: "system.placeholder",
                                         title: "Placeholder chart title",
                                         units: "units")
}

#Preview {
    NavigationStack {
        List {
            ChartListRow(chart: ServerChart(id: "ipv4.sockstat_frag_mem",
                                            name: "ipv4.sockstat_frag_mem",
                                            type: "ipv4",
                                            family: "fragments",
                                            context: "ipv4.sockstat_frag_mem",
                                            title: "IPv4 FRAG Sockets Memory (ipv4.sockstat_frag_mem)",
                                            units: "GiB"),
                         isPinned: true)
        }
    }
}

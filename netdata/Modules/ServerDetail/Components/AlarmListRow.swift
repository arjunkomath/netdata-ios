//
//  AlarmListRow.swift
//  netdata
//
//  Created by Arjun Komath on 29/7/20.
//

import SwiftUI

struct AlarmListRow: View {
    var alarm: ServerAlarm

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(tint)
                .frame(width: 10, height: 10)
                .padding(.top, 6)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(alarm.title)
                        .font(.headline)
                        .lineLimit(3)
                    Spacer(minLength: 0)
                    if let value = alarm.value_string, !value.isEmpty {
                        Text(value)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(tint)
                    }
                }

                if let info = alarm.info, !info.isEmpty {
                    Text(info)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let since = alarm.statusSince {
                        Text("\(statusLabel) for \(since, style: .relative)")
                    }
                    if let chart = alarm.chart {
                        Text(chart)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        if alarm.isCritical { return .red }
        if alarm.isWarning { return .orange }
        return .secondary
    }

    private var statusLabel: String {
        (alarm.status ?? "Unknown").capitalized
    }
}

extension ServerAlarm {
    /// Stand-in content for the redacted loading rows. No status, so the dot stays grey: redaction
    /// doesn't recolour shapes, and an orange dot would hint at a warning that may not exist.
    static let placeholder = ServerAlarm(status: nil,
                                         name: "placeholder_alarm",
                                         chart: "system.placeholder",
                                         info: "Placeholder description of what this alarm watches",
                                         summary: "Placeholder alarm summary",
                                         value_string: "00%",
                                         last_status_change: Date().timeIntervalSince1970)
}

struct AlarmListRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AlarmListRow(alarm: ServerAlarm(id: 1,
                                            status: "WARNING",
                                            name: "lowest_entropy",
                                            chart: "system.entropy",
                                            info: "minimum entries in the random numbers pool in the last 10 minutes",
                                            value_string: "98 entries",
                                            last_status_change: 1595892502))

            AlarmListRow(alarm: ServerAlarm(id: 1,
                                            status: "CRITICAL",
                                            name: "lowest_entropy",
                                            chart: "system.entropy",
                                            info: "minimum entries in the random numbers pool in the last 10 minutes",
                                            value_string: "12 entries",
                                            last_status_change: 1595892502))
        }
    }
}

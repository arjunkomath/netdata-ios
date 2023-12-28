//
//  AlarmCircularView.swift
//  AlarmWidgetExtension
//
//  Created by Arjun on 28/12/2023.
//

import SwiftUI

struct AlarmCircularView: View {
    var entry: Provider.Entry
    
    var body: some View {
        Gauge(
            value: max(Double(entry.criticalCount), 0),
            in: 0...max(Double(entry.count), 0)
        ) {
            Image(systemName: "externaldrive.fill.badge.xmark")
        } currentValueLabel: {
            Text("\(entry.criticalCount)")
        }
        .gaugeStyle(.accessoryCircular)
    }
}

#Preview {
    AlarmCircularView(entry: AlarmsEntry(serverCount: 1, count: 1, criticalCount: 0, alarms: ["CDN77": Color.red, "London": Color.green, "Test": Color.orange], date: Date()))
}

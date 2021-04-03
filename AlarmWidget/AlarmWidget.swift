//
//  AlarmWidget.swift
//  AlarmWidget
//
//  Created by Arjun Komath on 31/1/21.
//

import WidgetKit
import Combine
import SwiftUI

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> AlarmsEntry {
        AlarmsEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AlarmsEntry) -> ()) {
        let entry = AlarmsEntry.placeholder
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AlarmsEntry>) -> ()) {
        if context.isPreview {
            let timeline = Timeline(entries: [AlarmsEntry.placeholder], policy: .atEnd)
            completion(timeline)
        } else {
            let currentDate = Date()
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
            
            let fetchDate = Date()
            let serverService = ServerService.shared
            serverService.refresh()
            
            // show placeholder when there are no favourite servers
            if serverService.favouriteServers.count == 0 {
                let timeline = Timeline(entries: [AlarmsEntry.placeholder], policy: .atEnd)
                completion(timeline)
            } else {
                Publishers.MergeMany(serverService.favouriteServers.map({ server in NetDataAPI.getAlarms(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64) }))
                    .collect()
                    .sink(receiveCompletion: { (serverCompletion) in
                        if case .failure(let error) = serverCompletion {
                            print("Got error: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { serverAlarms in
                        let totalAlarmsCount = serverAlarms.reduce(0, { acc, serverAlarm in acc + serverAlarm.alarms.count })
                        let criticalAlarmsCount = serverAlarms.reduce(0, { acc, serverAlarm in acc + serverAlarm.getCriticalAlarmsCount() })
                        
                        var alarms : [String: Color] = [:]
                        serverService.favouriteServers.indices.forEach({ index in
                            alarms[serverService.favouriteServers[index].name] = serverAlarms[index].getCriticalAlarmsCount() > 0 ? Color.red : serverAlarms[index].alarms.count > 0 ? Color.orange : Color.green;
                        })
                        
                        let entry = AlarmsEntry(count: totalAlarmsCount, criticalCount: criticalAlarmsCount, alarms: alarms, date: fetchDate)
                        
                        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                        completion(timeline)
                    })
                    .store(in: &ServerService.cancellable)
            }
        }
    }
}

struct AlarmsEntry: TimelineEntry {
    let count: Int
    let criticalCount: Int
    let alarms: [String: Color]
    let date: Date
    
    var relevance: TimelineEntryRelevance? {
        return TimelineEntryRelevance(score: Float(count > 10 ? 100 : count * 10)) // 0 - not important | 100 - very important
    }
}

extension AlarmsEntry {
    static var placeholder: AlarmsEntry {
        AlarmsEntry(count: -1, criticalCount: 0, alarms: [:], date: Date())
    }
}

struct AlarmWidgetEntryView : View {
    @Environment(\.widgetFamily) private var widgetFamily
    
    var entry: Provider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidget(entry: entry)
        case .systemMedium:
            MediumWidget(entry: entry)
        case .systemLarge:
            Text("unknown")
        @unknown default: Text("unknown")
        }
    }
}

@main
struct AlarmWidget: Widget {
    let kind: String = "AlarmWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AlarmWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Alarms")
        .description("Shows the count of active alarms in your favourite servers")
    }
}

struct AlarmWidget_Previews: PreviewProvider {
    static var previews: some View {
        AlarmWidgetEntryView(entry: AlarmsEntry(count: 0, criticalCount: 0, alarms: [:], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

        AlarmWidgetEntryView(entry: AlarmsEntry(count: 1, criticalCount: 0, alarms: ["CDN77": Color.red, "London": Color.green, "Test": Color.orange], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

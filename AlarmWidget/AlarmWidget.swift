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
            
            // I have no clue if this is the right way to do it ¯\_(ツ)_/¯
            async {
                let (favouriteServers, _) = await ServerService.shared.fetchServers()
                
                // show placeholder when there are no favourite servers
                if favouriteServers.count == 0 {
                    let timeline = Timeline(entries: [AlarmsEntry(serverCount: 0, count: 0, criticalCount: 0, alarms: [:], date: fetchDate)], policy: .atEnd)
                    completion(timeline)
                } else {
                    async {
                        var totalAlarmsCount = 0
                        var criticalAlarmsCount = 0
                        
                        for server in favouriteServers {
                            debugPrint(server)
                            do {
                                let serverAlarm = try await NetdataClient.shared.getAlarms(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
                                
                                totalAlarmsCount += serverAlarm.alarms.count
                                criticalAlarmsCount += serverAlarm.getCriticalAlarmsCount()
                                
                                var alarms : [String: Color] = [:]
                                
                                alarms[server.name] = serverAlarm.getCriticalAlarmsCount() > 0 ? Color.red : serverAlarm.alarms.count > 0 ? Color.orange : Color.green;
                                
                                let entry = AlarmsEntry(serverCount: favouriteServers.count, count: totalAlarmsCount, criticalCount: criticalAlarmsCount, alarms: alarms, date: fetchDate)
                                
                                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                                completion(timeline)
                            } catch {
                                debugPrint("Fetch Alarms failed", error)
                                let timeline = Timeline(entries: [AlarmsEntry(serverCount: 0, count: 0, criticalCount: 0, alarms: [:], date: fetchDate)], policy: .atEnd)
                                completion(timeline)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AlarmsEntry: TimelineEntry {
    let serverCount: Int
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
        AlarmsEntry(serverCount: 0, count: -1, criticalCount: 0, alarms: [:], date: Date())
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
            Text("Unsupported")
        case .systemExtraLarge:
            Text("Unsupported")
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
        AlarmWidgetEntryView(entry: AlarmsEntry(serverCount: 0, count: 0, criticalCount: 0, alarms: [:], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        AlarmWidgetEntryView(entry: AlarmsEntry(serverCount: 1, count: 1, criticalCount: 0, alarms: ["CDN77": Color.red, "London": Color.green, "Test": Color.orange], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

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
        let entry = AlarmsEntry(count: 0, date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var cancellable = Set<AnyCancellable>()
        
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
                var totalAlarmsCount = 0
                
                serverService.favouriteServers.forEach({ server in
                    NetDataAPI
                        .getAlarms(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                debugPrint("getAlarms", server.name, error)
                            }
                        },
                        receiveValue: { serverAlarm in
                            totalAlarmsCount = totalAlarmsCount + serverAlarm.alarms.count
                        })
                        .store(in: &cancellable)
                })
                        
                let entry = AlarmsEntry(count: serverService.defaultServers.count, date: fetchDate)
                let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                completion(timeline)
            }
        }
    }
}

struct AlarmsEntry: TimelineEntry {
    let count: Int
    let date: Date
    
    var relevance: TimelineEntryRelevance? {
        return TimelineEntryRelevance(score: Float(count > 10 ? 100 : count * 10)) // 0 - not important | 100 - very important
    }
}

extension AlarmsEntry {
    static var placeholder: AlarmsEntry {
        AlarmsEntry(count: -1, date: Date())
    }
}

struct AlarmWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if entry.count == 0 {
            VStack(alignment: .leading) {
                Image(systemName: "hand.thumbsup.fill")
                    .resizable()
                    .frame(width: 48.0, height: 48.0)
                    .foregroundColor(.green)
                    .padding(.bottom, 8)
                
                Text("No Active Alarms")
                    .foregroundColor(.green)
                    .font(.body)
                    .bold()
                Text(entry.date, style: .time)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        } else {
            VStack(alignment: .leading) {
                Image(systemName: "hand.thumbsdown.fill")
                    .resizable()
                    .frame(width: 48.0, height: 48.0)
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
                
                Text("\(entry.count) Active Alarm(s)")
                    .foregroundColor(.red)
                    .font(.body)
                    .bold()
                Text(entry.date, style: .time)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .redacted(reason: entry.count == -1 ? .placeholder : .init())
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
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Alarms")
        .description("Shows the count of active alarms")
    }
}

struct AlarmWidget_Previews: PreviewProvider {
    static var previews: some View {
        AlarmWidgetEntryView(entry: AlarmsEntry(count: 0, date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        AlarmWidgetEntryView(entry: AlarmsEntry(count: 0, date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .redacted(reason: .placeholder)
        
        AlarmWidgetEntryView(entry: AlarmsEntry(count: 2, date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

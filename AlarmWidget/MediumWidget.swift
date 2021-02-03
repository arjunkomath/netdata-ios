//
//  MediumWidget.swift
//  AlarmWidgetExtension
//
//  Created by Arjun Komath on 1/2/21.
//

import WidgetKit
import SwiftUI

struct MediumWidget: View {
    var entry: Provider.Entry
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                if entry.alarms.isEmpty {
                    ForEach(1...8, id: \.self) { key in
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12, alignment: .leading)
                                .padding(.trailing, 4)
                            
                            Text("Dummy name")
                                .font(.headline)
                                .bold()
                                .foregroundColor(Color.green)
                        }
                        .padding(.leading)
                        .redacted(reason: .placeholder)
                    }
                } else {
                    ForEach(entry.alarms.keys.sorted()[0 ..< (entry.alarms.count > 8 ? 8 : entry.alarms.count)], id: \.self) { key in
                        HStack {
                            Circle()
                                .fill(entry.alarms[key] ?? Color.gray)
                                .frame(width: 16, height: 16, alignment: .leading)
                                .padding(.trailing, 4)
                            
                            Text(key)
                                .font(.title3)
                                .bold()
                                .foregroundColor(entry.alarms[key] ?? Color.gray)
                        }
                        .padding(.leading)
                    }
                }
            }
            
            Text(entry.date, style: .time)
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.leading)
        }
        .redacted(reason: entry.count == -1 ? .placeholder : .init())
    }
}

struct MediumWidget_Previews: PreviewProvider {
    static var previews: some View {
        MediumWidget(entry: AlarmsEntry(count: 2, criticalCount: 1, alarms: ["CDN77": Color.red, "London": Color.green, "Test": Color.orange], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        MediumWidget(entry: AlarmsEntry(count: 2, criticalCount: 1, alarms: [:], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .redacted(reason: .placeholder)
    }
}

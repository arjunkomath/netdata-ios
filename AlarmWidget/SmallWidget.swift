//
//  SmallWidget.swift
//  AlarmWidgetExtension
//
//  Created by Arjun Komath on 1/2/21.
//

import WidgetKit
import SwiftUI

struct SmallWidget: View {
    var entry: Provider.Entry
    
    var body: some View {
        if entry.serverCount == 0 {
            VStack(alignment: .leading) {
                Text("Please favourite servers to view alarms")
                    .foregroundColor(.gray)
                    .font(.callout)
                    .bold()
            }
        } else {
            if entry.count == 0 {
                VStack(alignment: .leading) {
                    Image(systemName: "hand.thumbsup.fill")
                        .resizable()
                        .frame(width: 36.0, height: 36.0)
                        .foregroundColor(.green)
                        .padding(.bottom, 8)
                    
                    Text("No active alarms")
                        .foregroundColor(.green)
                        .font(.body)
                        .bold()
                    Text(entry.date, style: .time)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading) {
                    Image(systemName: "externaldrive.fill.badge.xmark")
                        .resizable()
                        .frame(width: 52.0, height: 36.0)
                        .foregroundColor(.orange)
                        .padding(.bottom, 8)
                    
                    Text("\(entry.count) active alarm\(entry.count > 1 ? "s" : "")")
                        .foregroundColor(.orange)
                        .font(.body)
                        .bold()
                    if entry.criticalCount > 0 {
                        Text("\(entry.criticalCount) critical alarm\(entry.criticalCount > 1 ? "s" : "")")
                            .foregroundColor(.red)
                            .bold()
                            .font(.footnote)
                    }
                    Text(entry.date, style: .time)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .redacted(reason: entry.count == -1 ? .placeholder : .init())
            }
        }
    }
}

struct SmallWidget_Previews: PreviewProvider {
    static var previews: some View {
        SmallWidget(entry: AlarmsEntry(serverCount: 1, count: 0, criticalCount: 0, alarms: [:], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        SmallWidget(entry: AlarmsEntry(serverCount: 1, count: 1, criticalCount: 0, alarms: [:], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        SmallWidget(entry: AlarmsEntry(serverCount: 1, count: 2, criticalCount: 1, alarms: [:], date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

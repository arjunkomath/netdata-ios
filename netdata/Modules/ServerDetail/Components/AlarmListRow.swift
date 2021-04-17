//
//  AlarmListRow.swift
//  netdata
//
//  Created by Arjun Komath on 29/7/20.
//

import SwiftUI

struct AlarmListRow: View {
    var alarm: ServerAlarm;
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(alarm.name)
                    .bold()
                Text(alarm.status)
                    .font(.caption)
                    .bold()
                    .foregroundColor(self.isCritical() ? Color.red : Color.orange)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .foregroundColor((self.isCritical() ? Color.red : Color.orange).opacity(0.2)))
            }
            
            Text(alarm.info)
                .font(.subheadline)
            
            Text("\(Date(timeIntervalSince1970: alarm.last_status_change), style: .relative) ago")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(8)
    }
    
    func isCritical() -> Bool {
        // use enum instead if I can find all possible values
        return alarm.status == "CRITICAL"
    }
}

struct AlarmListRow_Previews: PreviewProvider {
    static var previews: some View {
        AlarmListRow(alarm: ServerAlarm(id: 1,
                                        status: "WARNING",
                                        name: "lowest_entropy",
                                        info: "minimum entries in the random numbers pool in the last 10 minutes",
                                        last_status_change: 1595892502))
        
        AlarmListRow(alarm: ServerAlarm(id: 1,
                                        status: "CRITICAL",
                                        name: "lowest_entropy",
                                        info: "minimum entries in the random numbers pool in the last 10 minutes",
                                        last_status_change: 1595892502))
    }
}

//
//  AlarmsListView.swift
//  netdata
//
//  Created by Arjun Komath on 29/7/20.
//

import SwiftUI

struct AlarmsListView: View {
    var serverAlarms: ServerAlarms;
    
    var body: some View {
        NavigationView {
            Group {
                if serverAlarms.alarms.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.thumbsup.fill")
                            .imageScale(.large)
                            .foregroundColor(.green)
                        
                        Text("No alarms raised! Everything looks good.")
                            .font(.headline)
                    }
                }
                
                List {
                    ForEach(serverAlarms.alarms.keys.sorted(), id: \.self) { key in
                        if serverAlarms.alarms[key] != nil {
                            AlarmListRow(alarm: serverAlarms.alarms[key]!)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Active Alarms"), displayMode: .inline)
        }
    }
}

struct AlarmsListView_Previews: PreviewProvider {
    static var previews: some View {
        AlarmsListView(serverAlarms: ServerAlarms(status: true, alarms: [
            "system.entropy.lowest_entropy": ServerAlarm(id: 1,
                                                          status: "WARNING",
                                                          name: "lowest_entropy",
                                                          info: "minimum entries in the random numbers pool in the last 10 minutes",
                                                          last_status_change: 1595892502)
        ]))
        
        AlarmsListView(serverAlarms: ServerAlarms(status: true, alarms: [:]))
    }
}

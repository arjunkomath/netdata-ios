//
//  AlarmsListView.swift
//  netdata
//
//  Created by Arjun Komath on 29/7/20.
//

import SwiftUI

struct AlarmsListView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var serverAlarms: ServerAlarms
    
    var body: some View {
        NavigationView {
            VStack {
                if serverAlarms.alarms.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.thumbsup.fill")
                            .imageScale(.large)
                            .foregroundColor(.green)
                            .padding()
                        
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
            .navigationTitle(Text("Active Alarms")).navigationBarTitleDisplayMode(.inline)
            /*.toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    dismissButton
                }
            }*/
            .navigationBarItems(leading: dismissButton)
        }
    }
    
    private var dismissButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .imageScale(.small)
        }
        .buttonStyle(BorderedBarButtonStyle())
        .accentColor(Color.red)
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

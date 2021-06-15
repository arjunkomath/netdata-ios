//
//  AlarmsListView.swift
//  netdata
//
//  Created by Arjun Komath on 29/7/20.
//

import SwiftUI

struct AlarmsListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var userSettings = UserSettings()
    
    var serverUrl: String
    var basicAuthBase64: String
    
    @State private var loading = false
    @State private var serverAlarms = ServerAlarms(status: false, alarms: [:])
    
    var body: some View {
        List {
            if loading {
                VStack(alignment: .center, spacing: 16) {
                    ProgressView()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
            }
            
            if self.getActiveAlarms().isEmpty && serverAlarms.status == true {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "hand.thumbsup.fill")
                        .imageScale(.large)
                        .foregroundColor(.green)
                    
                    Text("No active alarms.")
                        .font(.headline)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
            }
            
            ForEach(self.getActiveAlarms(), id: \.self) { key in
                AlarmListRow(alarm: serverAlarms.alarms[key]!)
                    .contextMenu {
                        Button(action: {
                            withAnimation {
                                userSettings.ignoredAlarms.append(serverAlarms.alarms[key]!.name)
                            }
                        }, label: {
                            Label("Hide alarm", systemImage: "eye.slash.fill")
                        })
                    }
            }
            
            if self.hiddenAlarmsCount() > 0 {
                Section {
                    Text("\(self.hiddenAlarmsCount()) hidden alert(s)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle(Text("Alarms"))
        .refreshable {
            await self.fetchAlarms()
        }
        .onAppear {
            async {
                await self.fetchAlarms()
            }
        }
    }
    
    private func fetchAlarms() async {
        loading = true
        do {
            serverAlarms = try await NetdataClient.shared.getAlarms(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64)
            loading = false
        } catch {
            loading = false
            debugPrint("getAlarms", error)
        }
    }
    
    private func getActiveAlarms() -> [String] {
        return serverAlarms.alarms.keys.sorted().filter { key in
            return serverAlarms.alarms[key] != nil &&
            !userSettings.ignoredAlarms.contains(serverAlarms.alarms[key]!.name)
        }
    }
    
    private func hiddenAlarmsCount() -> Int {
        return serverAlarms.alarms.keys.count - self.getActiveAlarms().count
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
        AlarmsListView(serverUrl: "", basicAuthBase64: "")
        
        AlarmsListView(serverUrl: "", basicAuthBase64: "")
    }
}

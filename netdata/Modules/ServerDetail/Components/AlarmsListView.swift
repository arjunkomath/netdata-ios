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
    
    @StateObject var viewModel = ServerDetailViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if self.getActiveAlarms().isEmpty && viewModel.serverAlarms.status == true {
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
                    ForEach(self.getActiveAlarms(), id: \.self) { key in
                        AlarmListRow(alarm: viewModel.serverAlarms.alarms[key]!)
                            .contextMenu {
                                Button(action: {
                                    withAnimation {
                                        userSettings.ignoredAlarms.append(viewModel.serverAlarms.alarms[key]!.name)
                                    }
                                }, label: {
                                    Label("Hide alarm", systemImage: "eye.slash.fill")
                                })
                            }
                    }
                }
                
                if self.hiddenAlarmsCount() > 0 {
                    Text("\(self.hiddenAlarmsCount()) hidden alert(s)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle(Text("Active Alarms")).navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: dismissButton)
            .onAppear {
                viewModel.fetchAlarms(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64)
            }
            .onDisappear {
                viewModel.destroyAlarmsData()
            }
        }
    }
    
    private func getActiveAlarms() -> [String] {
        return viewModel.serverAlarms.alarms.keys.sorted().filter { key in
            return viewModel.serverAlarms.alarms[key] != nil &&
                !userSettings.ignoredAlarms.contains(viewModel.serverAlarms.alarms[key]!.name)
        }
    }
    
    private func hiddenAlarmsCount() -> Int {
        return viewModel.serverAlarms.alarms.keys.count - self.getActiveAlarms().count
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

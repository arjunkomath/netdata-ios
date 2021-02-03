//
//  AlarmsListView.swift
//  netdata
//
//  Created by Arjun Komath on 29/7/20.
//

import SwiftUI

struct AlarmsListView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var serverUrl: String
    var basicAuthBase64: String
    
    @StateObject var viewModel = ServerDetailViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.serverAlarms.alarms.isEmpty && viewModel.serverAlarms.status == true {
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
                    ForEach(viewModel.serverAlarms.alarms.keys.sorted(), id: \.self) { key in
                        if viewModel.serverAlarms.alarms[key] != nil {
                            AlarmListRow(alarm: viewModel.serverAlarms.alarms[key]!)
                        }
                    }
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

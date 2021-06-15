//
//  ServerListRow.swift
//  netdata
//
//  Created by Arjun Komath on 27/7/20.
//

import SwiftUI

struct ServerListRow: View {
    @EnvironmentObject private var serverService: ServerService
    @StateObject var viewModel = ServerListViewModel()
    @ObservedObject var userSettings = UserSettings()
    
    var server: NDServer
    
    @State private var showEditServerSheet = false
    @State private var serverAlarms = ServerAlarms(status: false, alarms: [:])
    
    var body: some View {
        NavigationLink(destination: ServerDetailView(server: server)) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(server.name)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    
                    Circle()
                        .fill(self.getAlarmStatusColor())
                        .frame(width: 12, height: 12, alignment: .leading)
                    
                    if !server.basicAuthBase64.isEmpty {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(server.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if server.serverInfo != nil {
                    VStack(alignment: .leading) {
                        Text("\(server.serverInfo!.os_name) \(server.serverInfo!.os_version)")
                        
                        Text("\(server.serverInfo!.kernel_name) \(server.serverInfo!.architecture)")
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                }
            }
            .padding(4)
        }
        .task {
            if let alarms = await viewModel.fetchAlarms(server: server) {
                self.serverAlarms = alarms
            }
        }
        .sheet(isPresented: $showEditServerSheet, content: {
            EditServerForm(editingServer: server)
        })
        .contextMenu {
            editServerButton
            
            self.getFavouriteButtons()
            
            Link(destination: URL(string: server.url)!, label: {
                Label("Open in browser", systemImage: "safari")
            })
            
            Button(role: .destructive, action: {
                ServerService.shared.delete(server: server)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            self.getFavouriteButtons()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            editServerButton
        }
    }
    
    private var editServerButton: some View {
        Button(action: {
            self.showEditServerSheet = true
        }) {
            Text("Edit")
            Image(systemName: "pencil")
        }
        .tint(.orange)
    }
    
    @ViewBuilder
    private func getFavouriteButtons() -> some View {
        if server.isFavourite == 1 {
            Button(action: {
                async { await updateServer(favourite: false) }
            }) {
                Text("Unfavourite")
                Image(systemName: "star.slash")
            }
            .tint(.red)
        } else {
            Button(action: {
                async { await updateServer(favourite: true) }
            }) {
                Text("Favourite")
                Image(systemName: "star.fill")
            }
            .tint(.accentColor)
        }
    }
    
    func updateServer(favourite: Bool) async {
        var updatedServer = NDServer(name: server.name,
                                     description: server.description,
                                     url: server.url,
                                     serverInfo: server.serverInfo,
                                     basicAuthBase64: server.basicAuthBase64,
                                     isFavourite: favourite ? 1 : 0)
        
        if let record = server.record {
            updatedServer.record = record
            
            ServerService.shared.edit(server: updatedServer)
            FeedbackGenerator.shared.triggerNotification(type: .success)
            
            await serverService.refresh()
        }
    }
    
    func getAlarmStatusColor() -> Color {
        if serverAlarms.alarms.isEmpty {
            return Color.green
        }
        
        if self.hasCriticalAlarm() {
            return Color.red
        }
        
        return Color.orange
    }
    
    func hasCriticalAlarm() -> Bool {
        for (_, alarm) in serverAlarms.alarms {
            // use enum instead if I can find all possible values
            if alarm.status == "CRITICAL" {
                return true
            }
        }
        
        return false
    }
}

struct ServerListRow_Previews: PreviewProvider {
    static var previews: some View {
        ServerListRow(server: NDServer(name: "Techulus",
                                       description: "gc us server",
                                       url: "techulus.com",
                                       serverInfo: nil,
                                       basicAuthBase64: nil,
                                       isFavourite: 0))
        
        ServerListRow(server: NDServer(name: "Techulus",
                                       description: "gc us server",
                                       url: "techulus.com",
                                       serverInfo: nil,
                                       basicAuthBase64: "base64==",
                                       isFavourite: 0))
    }
}

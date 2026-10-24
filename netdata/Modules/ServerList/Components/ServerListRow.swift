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
    
    @State private var fetchingAlarm = true
    @State private var serverAlarms = ServerAlarms(status: nil, alarms: nil)
    
    var body: some View {
        NavigationLink(value: server.id) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    if self.isOffline() {
                        Image(systemName: "display.trianglebadge.exclamationmark")
                            .foregroundColor(.red)
                    }
                    
                    Text(server.name)
                        .lineLimit(2)
                        .font(.headline)
                        .foregroundColor(self.isOffline() ? .red : .primary)
                    
                    Spacer()
                    
                    if !server.basicAuthBase64.isEmpty {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.accentColor)
                    }
                    
                    RedactedView(loading: fetchingAlarm) {
                        Circle()
                            .fill(self.getAlarmStatusColor())
                            .frame(width: 12, height: 12, alignment: .leading)
                    }
                }
                
                Text(server.description)
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
#if targetEnvironment(macCatalyst)
        .buttonStyle(.borderless)
#endif
        .task(id: [server.url, server.basicAuthBase64, serverService.refreshID.uuidString]) {
            guard !Task.isCancelled else { return }
            fetchingAlarm = true
            serverAlarms = ServerAlarms(status: nil, alarms: nil)

            let alarms = await viewModel.fetchAlarms(server: server)
            guard !Task.isCancelled else { return }

            withAnimation {
                if let alarms = alarms {
                    self.serverAlarms = alarms
                }
                self.fetchingAlarm = false
            }
        }
        .sheet(isPresented: $showEditServerSheet, content: {
            EditServerForm(editingServer: server)
        })
        .contextMenu {
            editServerButton
            
            self.getFavouriteButtons()
            
            if let serverURL = URL(string: server.url) {
                Link(destination: serverURL, label: {
                    Label("Open in browser", systemImage: "safari")
                })
            }
            
            Button(role: .destructive, action: {
                ServerService.shared.requestDelete(server: server)
            }) {
                Label("Delete", systemImage: "trash")
            }
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
                Task { await updateServer(favourite: false) }
            }) {
                Text("Unfavourite")
                Image(systemName: "star.slash")
            }
            .tint(.red)
        } else {
            Button(action: {
                Task { await updateServer(favourite: true) }
            }) {
                Text("Favourite")
                Image(systemName: "star.fill")
            }
            .tint(.accentColor)
        }
    }
    
    func updateServer(favourite: Bool) async {
        var updatedServer = NDServer(id: server.id,
                                     name: server.name,
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
    
    func isOffline() -> Bool {
        return !fetchingAlarm && !(serverAlarms.status ?? false)
    }
    
    func getAlarmStatusColor() -> Color {
        guard let status = serverAlarms.status, status else {
            return Color.gray
        }

        guard let alarms = serverAlarms.alarms, !alarms.isEmpty else {
            return Color.green
        }

        if self.hasCriticalAlarm() {
            return Color.red
        }

        return Color.orange
    }
    
    func hasCriticalAlarm() -> Bool {
        guard let alarms = serverAlarms.alarms else { return false }
        return alarms.values.contains { $0.status == "CRITICAL" }
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
            .environmentObject(ServerService.shared)
        
        ServerListRow(server: NDServer(name: "Techulus",
                                       description: "gc us server",
                                       url: "techulus.com",
                                       serverInfo: nil,
                                       basicAuthBase64: "base64==",
                                       isFavourite: 0))
            .environmentObject(ServerService.shared)
    }
}

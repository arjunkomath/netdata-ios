//
//  ServerListRow.swift
//  netdata
//
//  Created by Arjun Komath on 27/7/20.
//

import SwiftUI

struct ServerListRow: View {
    @EnvironmentObject private var serverService: ServerService
    @ObservedObject var userSettings = UserSettings()
    @StateObject var viewModel = ServerListViewModel()
    
    var server: NDServer
    
    @State private var showEditServerSheet = false
    @State private var serverAlarms = ServerAlarms(status: false, alarms: [:])
    
    var body: some View {
        NavigationLink(destination: ServerDetailView(server: server)) {
            HStack {
                if serverAlarms.alarms.count == 0 {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10, alignment: .leading)
                        .padding(.trailing, 4)
                } else {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10, alignment: .leading)
                        .padding(.trailing, 4)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        if userSettings.favouriteServerId == server.id {
                            Image(systemName: "star.fill")
                                .foregroundColor(.accentColor)
                        }
                        
                        Text(server.name)
                            .font(.headline)
                    }
                    
                    Text(server.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if server.serverInfo != nil {
                        HStack {
                            Text("\(server.serverInfo!.os_name) \(server.serverInfo!.os_version), \(server.serverInfo!.kernel_name) \(server.serverInfo!.architecture)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchAlarms(server: server) { alarms in
                self.serverAlarms = alarms
            }
        }
        .sheet(isPresented: $showEditServerSheet, content: {
            EditServerForm(editingServer: server)
        })
        .contextMenu {
            Button(action: {
                self.showEditServerSheet = true
            }) {
                Text("Edit")
                Image(systemName: "pencil")
            }
            
            if userSettings.favouriteServerId == server.id {
                Button(action: {
                    self.userSettings.favouriteServerId = ""
                    self.userSettings.favouriteServerUrl = ""
                    
                    serverService.refresh()
                }) {
                    Text("Unfavourite")
                    Image(systemName: "star")
                }
            } else {
                Button(action: {
                    self.userSettings.favouriteServerId = ""
                    self.userSettings.favouriteServerUrl = ""
                    
                    self.userSettings.favouriteServerId = server.id
                    self.userSettings.favouriteServerUrl = server.url
                    
                    serverService.refresh()
                }) {
                    Text("Favourite")
                    Image(systemName: "star.fill")
                }
            }
        }
    }
}

struct ServerListRow_Previews: PreviewProvider {
    static var previews: some View {
        ServerListRow(server: NDServer(name: "Techulus",
                                       description: "gc us server",
                                       url: "techulus.com",
                                       serverInfo: nil))
    }
}

//
//  ServerListView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import WidgetKit

struct ServerListView: View {
    @EnvironmentObject private var serverService: ServerService
    
    @ObservedObject var userSettings = UserSettings()
    @State private var showAddServerSheet = false
    @State private var showEditServerSheet = false
    
    var body: some View {
        NavigationView {
            List {
                if self.serverService.mostRecentError != nil {
                    ErrorMessage(message: self.serverService.mostRecentError!.localizedDescription)
                }
                
                if !self.serverService.isCloudEnabled && !serverService.isSynching {
                    ErrorMessage(message: "iCloud not enabled, you need an iCloud account to add servers")
                }
                
                if serverService.isSynching && serverService.servers.isEmpty {
                    ForEach((1...4), id: \.self) { _ in
                        Group {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("name")
                                    .font(.headline)
                                Text("description")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .redacted(reason: .placeholder)
                        }
                        .padding(5)
                    }
                } else {
                    ForEach(serverService.servers) { server in
                        Group {
                            NavigationLink(destination: ServerDetailView(server: server)) {
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
                                    
                                    HStack {
                                        Text("\(server.serverInfo.os_name) \(server.serverInfo.os_version)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("\(server.serverInfo.kernel_name) \(server.serverInfo.architecture)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
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
                                    }) {
                                        Text("Favourite")
                                        Image(systemName: "star.fill")
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: self.deleteServer)
                }
            }
            .sheet(isPresented: $showAddServerSheet, content: {
                AddServerForm()
            })
            .navigationBarItems(trailing:
                                    HStack(spacing: 16) {
                                        refreshButton
                                        if self.serverService.isCloudEnabled {
                                            addButton
                                        }
                                    }
            )
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Servers")
            .onAppear(perform: serverService.refresh)
            
            VStack {
                Image(systemName: "tray")
                    .imageScale(.large)
                    .frame(width: 48, height: 48)
                Text("Select a server")
            }
        }
    }
    
    func addServer() {
        if !self.serverService.isCloudEnabled {
            return
        }
        
        self.showAddServerSheet.toggle()
    }
    
    func deleteServer(at offsets: IndexSet) {
        self.serverService.delete(server: serverService.servers[offsets.first!])
    }
    
    private var addButton: some View {
        Button(action: {
            self.addServer()
        }) {
            Image(systemName: "plus")
                .imageScale(.medium)
        }
        .buttonStyle(BorderedBarButtonStyle())
        .foregroundColor(.green)
        .accentColor(Color.green.opacity(0.2))
    }
    
    private var refreshButton: some View {
        Button(action: {
            self.serverService.refresh()
            
            WidgetCenter.shared.reloadAllTimelines()
        }) {
            if serverService.isSynching {
                ProgressView()
            } else {
                Image(systemName: "arrow.counterclockwise")
                    .imageScale(.small)
            }
        }
        .buttonStyle(BorderedBarButtonStyle())
        .foregroundColor(.blue)
        .accentColor(Color.blue.opacity(0.2))
    }
}

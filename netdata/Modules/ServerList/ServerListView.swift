//
//  ServerListView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

struct ServerListView: View {
    @EnvironmentObject var serverService: ServerService
    
    @ObservedObject var userSettings = UserSettings()
    
    @State private var showAddServer = false
    @State private var showWelcome = false
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                if !self.serverService.isCloudEnabled && !serverService.isSynching {
                    ErrorMessage(message: "iCloud not enabled, you need an iCloud account to view / add servers")
                }
                
                if let error = self.serverService.mostRecentError {
                    ErrorMessage(message: error.localizedDescription)
                }
                
                if serverService.isSynching && serverService.defaultServers.isEmpty && serverService.favouriteServers.isEmpty {
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
                        .padding(8)
                    }
                } else {
                    if !serverService.favouriteServers.isEmpty {
                        Section("Favourites") {
                            ForEach(serverService.favouriteServers) { server in
                                ServerListRow(server: server)
                            }
                            .onDelete(perform: self.deleteFavouriteServer)
                        }
                        .headerProminence(.increased)
                    }
                    
                    Section("Servers") {
                        ForEach(serverService.defaultServers) { server in
                            ServerListRow(server: server)
                        }
                        .onDelete(perform: self.deleteServer)
                    }
                    .headerProminence(.increased)
                }
            }
            .listStyle(.insetGrouped)
        }
        .task {
            await serverService.refresh()
            
            // show welcome screen
            if !userSettings.HasLaunchedOnce {
                userSettings.HasLaunchedOnce = true
                showWelcome = true
            }
        }
        .ifNotMacCatalyst { view in
            view.refreshable {
                await serverService.refresh()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    showSettings = true
                }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                if self.serverService.isCloudEnabled {
                    Button(action: {
                        showAddServer = true
                    }) {
                        HStack {
                            Image(systemName: "externaldrive.badge.plus")
                            Text("Add")
                        }
                    }
                    .sheet(isPresented: $showAddServer) {
                        AddServerForm()
                    }
                }
                
                Spacer()
                
                SupportOptions()
            }
        }
        .navigationTitle("My Servers")
        .sheet(isPresented: $showWelcome) {
            WelcomeScreen()
        }
    }
    
    func deleteServer(at offsets: IndexSet) {
        self.serverService.delete(server: serverService.defaultServers[offsets.first!])
    }
    
    func deleteFavouriteServer(at offsets: IndexSet) {
        self.serverService.delete(server: serverService.favouriteServers[offsets.first!])
    }
}

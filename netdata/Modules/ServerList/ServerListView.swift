//
//  ServerListView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

struct ServerListView: View {
    @EnvironmentObject private var serverService: ServerService
    @ObservedObject var userSettings = UserSettings()
    
    @State private var showAddServerSheet = false
    @State private var showSettingsSheet = false
    @State private var showWelcomeSheet = false
    
    var body: some View {
        NavigationView {
            List {
                if self.serverService.mostRecentError != nil {
                    ErrorMessage(message: self.serverService.mostRecentError!.localizedDescription)
                }
                
                if !self.serverService.isCloudEnabled && !serverService.isSynching {
                    ErrorMessage(message: "iCloud not enabled, you need an iCloud account to add servers")
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
                        .padding(5)
                    }
                } else {
                    if !serverService.favouriteServers.isEmpty {
                        Section(header: Text("Favourites").sectionHeaderStyle()) {
                            ForEach(serverService.favouriteServers) { server in
                                ServerListRow(server: server)
                            }
                            .onDelete(perform: self.deleteFavouriteServer)
                        }
                    }
                    
                    Section(header: Text("Servers").sectionHeaderStyle()) {
                        ForEach(serverService.defaultServers) { server in
                            ServerListRow(server: server)
                        }
                        .onDelete(perform: self.deleteServer)
                    }
                }
            }
            .sheet(isPresented: $showWelcomeSheet, content: {
                WelcomeScreen()
            })
            .navigationBarItems(
                leading: settingsButton,
                trailing:
                    HStack(spacing: 16) {
                        refreshButton
                        
                        if self.serverService.isCloudEnabled && self.serverService.mostRecentError == nil {
                            addButton
                                .sheet(isPresented: $showAddServerSheet, content: {
                                    AddServerForm()
                                })
                        }
                    }
            )
            .listStyle(GroupedListStyle())
            .navigationTitle("My Servers")
            .onAppear(perform: {
                serverService.refresh()
                
                // hide scroll indicators
                UITableView.appearance().showsVerticalScrollIndicator = false
                
                // show welcome screen
                if !userSettings.HasLaunchedOnce {
                    self.showWelcomeSheet = true
                    userSettings.HasLaunchedOnce = true
                }
            })
            
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
        self.serverService.delete(server: serverService.defaultServers[offsets.first!])
    }
    
    func deleteFavouriteServer(at offsets: IndexSet) {
        self.serverService.delete(server: serverService.favouriteServers[offsets.first!])
    }
    
    private var addButton: some View {
        Button(action: {
            self.addServer()
        }) {
            Image(systemName: "plus")
                .imageScale(.medium)
        }
        .buttonStyle(BorderedBarButtonStyle())
    }
    
    private var refreshButton: some View {
        Button(action: {
            self.serverService.refresh()
        }) {
            if serverService.isSynching {
                ProgressView()
            } else {
                Image(systemName: "arrow.clockwise")
                    .imageScale(.small)
            }
        }
        .buttonStyle(BorderedBarButtonStyle())
    }
    
    private var settingsButton: some View {
        Button(action: {
            self.showSettingsSheet = true
        }) {
            Image(systemName: "gear")
                .imageScale(.small)
        }
        .buttonStyle(BorderedBarButtonStyle())
        .sheet(isPresented: $showSettingsSheet, content: {
            SettingsView()
                .environmentObject(serverService)
        })
    }
}

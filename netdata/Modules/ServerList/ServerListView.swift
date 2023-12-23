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
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading) {
                    RedactedView(loading: serverService.isSynching) {
                        if !self.serverService.isCloudEnabled && !serverService.isSynching {
                            ErrorMessage(message: "iCloud not enabled, you need an iCloud account to view / add servers")
                        }
                        
                        if let error = self.serverService.mostRecentError {
                            ErrorMessage(message: error.localizedDescription)
                        }
                        
                        if serverService.favouriteServers.isEmpty == false {
                            Label("Favourites", systemImage: "star.fill")
                                .font(.headline)
                            LazyVGrid(columns: gridLayout(for: geometry.size.width), alignment: .leading, spacing: 8) {
                                ForEach(serverService.favouriteServers, id: \.id) { server in
                                    ServerListRow(server: server)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                        
                        if serverService.defaultServers.isEmpty == false {
                            Label("All Servers", systemImage: "folder.fill")
                                .font(.headline)
                            LazyVGrid(columns: gridLayout(for: geometry.size.width), alignment: .leading, spacing: 8) {
                                ForEach(serverService.defaultServers, id: \.id) { server in
                                    ServerListRow(server: server)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .task {
            await serverService.refresh()
            
            // show welcome screen
            if !userSettings.HasLaunchedOnce {
                userSettings.HasLaunchedOnce = true
                showWelcome = true
            }
        }
        .refreshable {
            await serverService.refresh()
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
    
    private func gridLayout(for width: CGFloat) -> [GridItem] {
        let numberOfColumns = min(Int(width / 180), 6)
        return Array(repeating: .init(.flexible()), count: max(numberOfColumns, 1)) // Ensuring at least one column
    }
}

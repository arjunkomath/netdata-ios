//
//  ServerListView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import UIKit

struct ServerListView: View {
    @EnvironmentObject var serverService: ServerService
    @Environment(\.openURL) private var openURL
    
    @ObservedObject var userSettings = UserSettings()
    
    @State private var showAddServer = false
    @State private var showWelcome = false
    @State private var showSettings = false
    @State private var selectedServerID: String?

    private var selectedServer: NDServer? {
        (serverService.favouriteServers + serverService.defaultServers)
            .first { $0.id == selectedServerID }
    }
    
    var body: some View {
        NavigationSplitView {
            // Let the system align the columns with the fold's reserved region.
            serverList
        } detail: {
            if let server = selectedServer {
                ServerDetailNavigationView(server: server)
                    .id([server.id, server.url, server.basicAuthBase64])
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.largeTitle)
                    Text("Select a server")
                        .font(.title2)
                    Text("Choose a server to view its charts and alarms.")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            await serverService.refresh()
            
            // show welcome screen
            if !userSettings.HasLaunchedOnce {
                userSettings.HasLaunchedOnce = true
                showWelcome = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAddServer) {
            AddServerForm()
        }
        .sheet(isPresented: $showWelcome) {
            WelcomeScreen()
        }
        .confirmationDialog(
            "Delete Server",
            isPresented: $serverService.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await serverService.confirmDelete()
                    if selectedServer == nil {
                        selectedServerID = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                serverService.cancelDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(serverService.serverToDelete?.name ?? "this server")'? This action cannot be undone.")
        }
    }

    private var serverList: some View {
        List(selection: $selectedServerID) {
            if serverService.isSynching && serverService.favouriteServers.isEmpty && serverService.defaultServers.isEmpty {
                ProgressView("Loading servers…")
            }

            if !serverService.isCloudEnabled && !serverService.isSynching {
                ErrorMessage(message: "iCloud not enabled, you need an iCloud account to view / add servers")
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    Button("Open Settings") {
                        openURL(settingsURL)
                    }
                }
            }

            if let error = serverService.mostRecentError {
                ErrorMessage(message: error.localizedDescription)
            }

            if !serverService.favouriteServers.isEmpty {
                Section {
                    ForEach(serverService.favouriteServers) { server in
                        ServerListRow(server: server)
                    }
                } header: {
                    Label("Favourites", systemImage: "star.fill")
                }
            }

            if !serverService.defaultServers.isEmpty {
                Section {
                    ForEach(serverService.defaultServers) { server in
                        ServerListRow(server: server)
                    }
                } header: {
                    Label("All Servers", systemImage: "folder.fill")
                }
            }
        }
        .listStyle(.sidebar)
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
            }
            
            if self.serverService.isCloudEnabled {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        showAddServer = true
                    }) {
                        Label("Add Server", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("My Servers")
    }

    func deleteServer(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        serverService.requestDelete(server: serverService.defaultServers[index])
    }

    func deleteFavouriteServer(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        serverService.requestDelete(server: serverService.favouriteServers[index])
    }
}

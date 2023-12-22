//
//  ServerListView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

final class ServerListActiveSheet: ObservableObject {
    enum Kind {
        case add
        case settings
        case welcome
        case none
    }
    
    @Published var kind: Kind = .none {
        didSet { showSheet = kind != .none }
    }
    
    @Published var showSheet: Bool = false
}

struct ServerListView: View {
    @EnvironmentObject var serverService: ServerService
    
    @ObservedObject var userSettings = UserSettings()
    @ObservedObject var activeSheet = ServerListActiveSheet()
    
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
            .sheet(isPresented: self.$activeSheet.showSheet, content: { self.sheet })
        }
        .task {
            await serverService.refresh()
            
            // show welcome screen
            if !userSettings.HasLaunchedOnce {
                userSettings.HasLaunchedOnce = true
                self.activeSheet.kind = .welcome
            }
        }
        .ifNotMacCatalyst { view in
            view.refreshable {
                await serverService.refresh()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    self.activeSheet.kind = .settings
                }) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    self.addServer()
                }) {
                    HStack {
                        Image(systemName: "externaldrive.badge.plus")
                        Text("Add")
                    }
                }
                
                Spacer()
                
                SupportOptions()
            }
        }
        .navigationTitle("My Servers")
    }
    
    func addServer() {
        if !self.serverService.isCloudEnabled {
            return
        }
        
        self.activeSheet.kind = .add
    }
    
    func deleteServer(at offsets: IndexSet) {
        self.serverService.delete(server: serverService.defaultServers[offsets.first!])
    }
    
    func deleteFavouriteServer(at offsets: IndexSet) {
        self.serverService.delete(server: serverService.favouriteServers[offsets.first!])
    }
    
    @ViewBuilder
    private var sheet: some View {
        switch activeSheet.kind {
        case .none: EmptyView()
        case .add: AddServerForm()
        case .settings: SettingsView().environmentObject(serverService)
        case .welcome: WelcomeScreen()
        }
    }
}

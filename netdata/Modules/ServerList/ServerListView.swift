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
    @EnvironmentObject private var serverService: ServerService
    @ObservedObject var userSettings = UserSettings()
    @ObservedObject var activeSheet = ServerListActiveSheet()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    if self.serverService.mostRecentError != nil {
                        if !self.serverService.isCloudEnabled && !serverService.isSynching {
                            ErrorMessage(message: "iCloud not enabled, you need an iCloud account to add servers")
                        }
                        else {
                            ErrorMessage(message: self.serverService.mostRecentError!.localizedDescription)
                        }
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
                
                BottomBar {
                    Menu {
                        Link("Report an issue", destination: URL(string: "https://github.com/arjunkomath/netdata-ios/issues")!)
                        Link("Q&A", destination: URL(string: "https://github.com/arjunkomath/netdata-ios/discussions/categories/q-a")!)
                    } label: {
                        Label("Support", systemImage: "lifepreserver.fill")
                            .padding(.leading)
                            .labelStyle(.iconOnly)
                    }
                    
                    Spacer()
                    
                    addButton
                        .padding(.trailing)
                }
            }
            .refreshable {
                await serverService.refresh()
            }
            .sheet(isPresented: self.$activeSheet.showSheet, content: { self.sheet })
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    settingsButton
                }
            }
            .navigationTitle("My Servers")
            .task {
                await serverService.refresh()
                
                // hide scroll indicators
                UITableView.appearance().showsVerticalScrollIndicator = false
                
                // show welcome screen
                if !userSettings.HasLaunchedOnce {
                    userSettings.HasLaunchedOnce = true
                    self.activeSheet.kind = .welcome
                }
            }
            
            VStack {
                if serverService.defaultServers.isEmpty && serverService.favouriteServers.isEmpty {
                    Image(systemName: "tray")
                        .imageScale(.large)
                        .frame(width: 48, height: 48)
                    
                    Button(action: {
                        self.addServer()
                    }) {
                        Text("Add Netdata server")
                    }
                    .buttonStyle(BorderedBarButtonStyle())
                } else {
                    Image(systemName: "tray")
                        .imageScale(.large)
                        .frame(width: 48, height: 48)
                    Text("Select a server")
                }
            }
        }
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
    
    private var addButton: some View {
        Button(action: {
            self.addServer()
        }) {
            Label("Add", systemImage: "externaldrive.badge.plus")
                .labelStyle(.titleAndIcon)
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            self.activeSheet.kind = .settings
        }) {
            Label("Settings", systemImage: "gear")
        }
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

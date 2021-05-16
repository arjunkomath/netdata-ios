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
                .listStyle(InsetGroupedListStyle())
                
                BottomBar {
                    refreshButton
                        .padding(.leading)
                    
                    if self.serverService.isCloudEnabled && self.serverService.mostRecentError == nil {
                        Spacer()
                        
                        addButton
                            .padding(.trailing)
                    }
                }
            }
            .sheet(isPresented: self.$activeSheet.showSheet, content: { self.sheet })
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    settingsButton
                }
            }
            .navigationTitle("My Servers")
            .onAppear(perform: {
                serverService.refresh()
                
                // hide scroll indicators
                UITableView.appearance().showsVerticalScrollIndicator = false
                
                // show welcome screen
                if !userSettings.HasLaunchedOnce {
                    userSettings.HasLaunchedOnce = true
                    self.activeSheet.kind = .welcome
                }
            })
            
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
            Image(systemName: "externaldrive.badge.plus")
            Text("Add")
        }
    }
    
    private var refreshButton: some View {
        Button(action: {
            self.serverService.refresh()
        }) {
            if serverService.isSynching {
                ProgressView().frame(width: 20, height: 16, alignment: .trailing)
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            self.activeSheet.kind = .settings
        }) {
            Image(systemName: "gear")
        }
    }
    
    private var sheet: some View {
        switch activeSheet.kind {
        case .none: return AnyView(EmptyView())
        case .add: return AnyView(AddServerForm())
        case .settings: return AnyView(SettingsView()
                                        .environmentObject(serverService))
        case .welcome: return AnyView(WelcomeScreen())
        }
    }
}

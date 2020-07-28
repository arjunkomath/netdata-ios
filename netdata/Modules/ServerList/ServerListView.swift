//
//  ServerListView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

struct ServerListView: View {
    @EnvironmentObject private var serverService: ServerService
    
    @State private var showAddServerSheet = false
    
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
                        ServerListRow(server: server)
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
                                        
                                        if self.serverService.isCloudEnabled && self.serverService.mostRecentError == nil {
                                            addButton
                                        }
                                    }
            )
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Servers")
            .onAppear(perform: {
                serverService.refresh()
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

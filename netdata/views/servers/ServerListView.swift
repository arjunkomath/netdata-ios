//
//  ServerListView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

struct ServerListView: View {
    @EnvironmentObject private var service: ServerService
    
    @State private var showAddServerSheet = false
    
    var body: some View {
        NavigationView {
            List {
                if !self.service.canAddServer {
                    Text("iCloud not enabled, you need an iCloud account to add servers")
                        .foregroundColor(.red)
                }
                
                if service.isSynching && service.servers.isEmpty {
                    RowLoadingView()
                } else {
                    ForEach(service.servers) { server in
                        Group {
                            NavigationLink(destination: ServerDetailView(server: server)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(server.name)
                                        .font(.system(.title3, design: .rounded))
                                    Text(server.description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text(server.url)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(10)
                            }
                            .contextMenu {
                                Button(action: {
                                    // change country setting
                                }) {
                                    Text("Edit")
                                    Image(systemName: "pencil")
                                }
                                
                                Button(action: {
                                    // change country setting
                                }) {
                                    Text("Delete")
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    .onDelete(perform: self.deleteServer)
                }
            }
            .sheet(isPresented: $showAddServerSheet, content: { AddServerForm().environmentObject(service) } )
            .navigationBarItems(trailing:
                                    HStack(spacing: 16) {
                                        refreshButton
                                        if self.service.canAddServer {
                                            addButton
                                        }
                                    }
            )
            .listStyle(GroupedListStyle())
            .navigationTitle("Servers")
            .onAppear(perform: service.refresh)
        }        
    }
    
    func addServer() {
        if !self.service.canAddServer {
            return
        }
        
        self.showAddServerSheet.toggle()
    }
    
    func deleteServer(at offsets: IndexSet) {
        self.service.delete(server: service.servers[offsets.first!])
    }
    
    private var addButton: some View {
        Button(action: {
            self.addServer()
        }) {
            Text("Add Server")
        }
    }
    
    private var refreshButton: some View {
        Button(action: {
            self.service.refresh()
        }) {
            if service.isSynching {
                ProgressView()
            } else {
                Image(systemName: "arrow.counterclockwise").imageScale(.large)
            }
        }
    }
}

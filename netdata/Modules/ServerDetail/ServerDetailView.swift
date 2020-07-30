//
//  ServerDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI
import Combine

struct ServerDetailView: View {
    var server: NDServer;
    
    @StateObject var viewModel = ServerDetailViewModel()
    
    @State private var showAlarmsSheet = false
    
    var body: some View {
        List {
            Section(header: makeSectionHeader(text: "CPU")) {
                HStack {
                    VStack {
                        Meter(progress: viewModel.cpuUsageGauge)
                            .redacted(reason: self.viewModel.cpuUsage.labels.count < 1 ? .placeholder : .init())
                        
                        if (server.serverInfo != nil && viewModel.cpuUsage.labels.count > 0) {
                            Spacer()
                            
                            AbsoluteUsageData(stringValue: server.serverInfo?.cores_total,
                                              title: "cores",
                                              showArrows: false)
                        }
                    }
                    
                    DataGrid(labels: viewModel.cpuUsage.labels,
                             data: viewModel.cpuUsage.data,
                             dataType: .percentage,
                             showArrows: false)
                }
            }
            
            Section(header: makeSectionHeader(text: "Load")) {
                DataGrid(labels: viewModel.load.labels,
                         data: viewModel.load.data,
                         dataType: .absolute,
                         showArrows: false)
            }
            
            Section(header: makeSectionHeader(text: "Memory (MB)")) {
                HStack {
                    Meter(progress: viewModel.ramUsageGauge)
                        .redacted(reason: viewModel.ramUsage.labels.count < 1 ? .placeholder : .init())
                    
                    DataGrid(labels: viewModel.ramUsage.labels,
                             data: viewModel.ramUsage.data,
                             dataType: .absolute,
                             showArrows: false)
                }
            }
            
            Section(header: makeSectionHeader(text: "Disk Space (GB)")) {
                HStack {
                    Meter(progress: viewModel.diskSpaceUsageGauge)
                        .redacted(reason: viewModel.diskSpaceUsage.labels.count < 1 ? .placeholder : .init())
                    
                    DataGrid(labels: viewModel.diskSpaceUsage.labels,
                             data: viewModel.diskSpaceUsage.data,
                             dataType: .absolute,
                             showArrows: false)
                }
            }
            
            Section(header: makeSectionHeader(text: "Disk I/O")) {
                DataGrid(labels: viewModel.diskIO.labels,
                         data: viewModel.diskIO.data,
                         dataType: .absolute,
                         showArrows: true)
            }
            
            Section(header: makeSectionHeader(text: "Network")) {
                DataGrid(labels: viewModel.network.labels,
                         data: viewModel.network.data,
                         dataType: .absolute,
                         showArrows: true)
            }
        }
        .readableGuidePadding()
        .onAppear {
            self.viewModel.fetch(baseUrl: server.url)
            
            // hide scroll indicators
            UITableView.appearance().showsVerticalScrollIndicator = false
        }
        .onDisappear {
            self.viewModel.destroy()
        }
        .sheet(isPresented: $showAlarmsSheet, content: {
            AlarmsListView(serverAlarms: viewModel.serverAlarms)
        })
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(Text(server.name))
        .navigationBarItems(trailing:
                                Button(action: {
                                    self.showAlarmsSheet = true
                                }) {
                                    Image(systemName: "bell")
                                        .imageScale(.medium)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(BorderedBarButtonStyle())
        )
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
    func makeSectionHeader(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .bold()
            .foregroundColor(.gray)
    }
}

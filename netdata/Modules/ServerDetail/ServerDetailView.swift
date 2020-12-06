//
//  ServerDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI
import Combine

enum ActiveSheet {
    case alarms, charts, loading
}

struct ServerDetailView: View {
    var server: NDServer;
    var serverAlarms: ServerAlarms;
    
    @StateObject var viewModel = ServerDetailViewModel()
    
    @State private var showSheet = false
    @State private var activeSheet: ActiveSheet = .loading
    
    var body: some View {
        List {
            Section(header: makeSectionHeader(text: "CPU (%)")) {
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
                    
                    self.getiPadSpacer()
                    
                    DataGrid(labels: viewModel.cpuUsage.labels,
                             data: viewModel.cpuUsage.data,
                             dataType: .percentage,
                             showArrows: false)
                }
            }
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Load")) {
                DataGrid(labels: viewModel.load.labels,
                         data: viewModel.load.data,
                         dataType: .absolute,
                         showArrows: false)
            }
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Memory (MiB)")) {
                HStack {
                    Meter(progress: viewModel.ramUsageGauge)
                        .redacted(reason: self.viewModel.ramUsage.labels.count < 1 ? .placeholder : .init())
                    
                    self.getiPadSpacer()
                    
                    DataGrid(labels: viewModel.ramUsage.labels,
                             data: viewModel.ramUsage.data,
                             dataType: .absolute,
                             showArrows: false)
                }
            }
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Disk Space (GiB)")) {
                HStack {
                    Meter(progress: viewModel.diskSpaceUsageGauge)
                        .redacted(reason: viewModel.diskSpaceUsage.labels.count < 1 ? .placeholder : .init())
                    
                    self.getiPadSpacer()
                    
                    DataGrid(labels: viewModel.diskSpaceUsage.labels,
                             data: viewModel.diskSpaceUsage.data,
                             dataType: .absolute,
                             showArrows: false)
                }
            }
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Disk I/O (KiB/s)")) {
                DataGrid(labels: viewModel.diskIO.labels,
                         data: viewModel.diskIO.data,
                         dataType: .absolute,
                         showArrows: true)
            }
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Network (kilobits/s)")) {
                DataGrid(labels: viewModel.network.labels,
                         data: viewModel.network.data,
                         dataType: .absolute,
                         showArrows: true)
            }
            .readableGuidePadding()
        }
        .onAppear {
            self.viewModel.fetch(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            // hide scroll indicators
            UITableView.appearance().showsVerticalScrollIndicator = false
        }
        .onDisappear {
            self.viewModel.destroy()
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(Text(server.name))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    self.activeSheet = .charts
                    self.viewModel.destroy()
                    self.showSheet.toggle()
                }) {
                    Image(systemName: "chart.pie")
                }
                .disabled(self.viewModel.serverChartsToolbarButton)
                
                Button(action: {
                    self.activeSheet = .alarms
                    self.viewModel.destroy()
                    self.showSheet.toggle()
                }) {
                    Image(systemName: "alarm")
                }
            }
        }
        .sheet(isPresented: $showSheet, onDismiss: {
            self.viewModel.destroyModel()
            self.viewModel.fetch(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            self.activeSheet = .loading
        }, content: {
            if self.activeSheet == .loading {
                ProgressView()
            } else if self.activeSheet == .charts {
                ChartsListView(serverCharts: viewModel.serverCharts, serverUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            } else if self.activeSheet == .alarms {
                AlarmsListView(serverAlarms: self.serverAlarms)
            }
        })
    }
    
    func makeSectionHeader(text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
    }
    
    func getiPadSpacer() -> AnyView? {
        #if targetEnvironment(macCatalyst)
        return AnyView(Spacer(minLength: 36))
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? AnyView(Spacer(minLength: 36)) : nil
        #endif
    }
}


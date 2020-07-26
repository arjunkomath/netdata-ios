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
        
    @StateObject var viewModel = ServerListViewModel()
    
    var body: some View {
        List {
            Section(header: Text("CPU Usage")) {
                VStack {
                    Spacer()
                    HStack {
                        Meter(progress: $viewModel.cpuUsageGauge, title: .constant("Total"))
                            .frame(width: 110)
                            .redacted(reason: self.viewModel.cpuUsage.labels.count < 1 ? .placeholder : .init())

                        DataGrid(labels: $viewModel.cpuUsage.labels,
                                 data: $viewModel.cpuUsage.data,
                                 dataType: .constant(.percentage),
                                 showArrows: .constant(false))
                    }
                    Spacer()
                }
            }

            Section(header: Text("Load")) {
                VStack {
                    Spacer()
                    HStack {
                        DataGrid(labels: $viewModel.load.labels,
                                 data: $viewModel.load.data,
                                 dataType: .constant(.absolute),
                                 showArrows: .constant(false))
                    }
                    Spacer()
                }
            }

            Section(header: Text("Memory Usage")) {
                VStack {
                    Spacer()
                    HStack {
                        Meter(progress: $viewModel.ramUsageGauge, title: .constant("Total"))
                            .frame(width: 110)
                            .redacted(reason: viewModel.ramUsage.labels.count < 1 ? .placeholder : .init())

                        DataGrid(labels: $viewModel.ramUsage.labels,
                                 data: $viewModel.ramUsage.data,
                                 dataType: .constant(.absolute),
                                 showArrows: .constant(false))
                    }
                    Spacer()
                }
            }

            Section(header: Text("Disk I/O")) {
                VStack {
                    Spacer()
                    HStack {
                        DataGrid(labels: $viewModel.diskIO.labels,
                                 data: $viewModel.diskIO.data,
                                 dataType: .constant(.absolute),
                                 showArrows: .constant(true))
                    }
                    Spacer()
                }
            }

            Section(header: Text("Network")) {
                VStack {
                    Spacer()
                    HStack {
                        DataGrid(labels: $viewModel.network.labels,
                                 data: $viewModel.network.data,
                                 dataType: .constant(.absolute),
                                 showArrows: .constant(true))
                    }
                    Spacer()
                }
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
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(server.name)
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}


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
    
    @State private var showSheet = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        List {
            Section(header: makeSectionHeader(text: "CPU (%)")) {
                HStack {
                    VStack {
                        Meter(progress: viewModel.getGaugeData(data: viewModel.cpuUsage.data))
                            .redacted(reason: viewModel.cpuUsage.labels.count < 1 ? .placeholder : .init())
                        
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
            
            Section(header: makeSectionHeader(text: "Disk")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Space (GiB)")
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("I/O (KiB/s)")
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    
                    DataGrid(labels: viewModel.diskIO.labels,
                             data: viewModel.diskIO.data,
                             dataType: .absolute,
                             showArrows: true)
                }
            }
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Network")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("system.net (kilobits/s)")
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    
                    DataGrid(labels: viewModel.network.labels,
                             data: viewModel.network.data,
                             dataType: .absolute,
                             showArrows: true)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("system.ip (megabits/s)")
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    
                    DataGrid(labels: viewModel.networkIPv4.labels,
                             data: viewModel.networkIPv4.data,
                             dataType: .absolute,
                             showArrows: true)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("system.ipv6 (kilobits/s)")
                        .font(.subheadline)
                        .padding(.vertical, 4)
                    
                    DataGrid(labels: viewModel.networkIPv6.labels,
                             data: viewModel.networkIPv6.data,
                             dataType: .absolute,
                             showArrows: true)
                }
            }
            .readableGuidePadding()
            
            if viewModel.bookmarkedChartData.count > 0 {
                Section(header: makeSectionHeader(text: "Pinned charts")) {
                    ForEach(Array(viewModel.bookmarkedChartData.enumerated()), id: \.offset) { i, chart in
                        HStack {
                            if self.getDataType(chart: viewModel.bookmarks[i]) == .percentage {
                                Meter(progress: viewModel.getGaugeData(data: chart.data))
                                    .redacted(reason: chart.labels.count < 1 ? .placeholder : .init())
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.bookmarks[i].id)
                                    .font(.subheadline)
                                    .padding(.vertical, 4)
                                
                                DataGrid(labels: chart.labels,
                                         data: chart.data,
                                         dataType: self.getDataType(chart: viewModel.bookmarks[i]),
                                         showArrows: false)
                            }
                        }
                    }
                }
                .readableGuidePadding()
            }
        }
        .listStyle(InsetGroupedListStyle())
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    NavigationLink(destination: ChartsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64)) {
                        Label("Charts", systemImage: "chart.pie")
                            .labelStyle(.titleAndIcon)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: AlarmsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64)) {
                        Label("Alarms", systemImage: "alarm")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
        .onAppear {
            viewModel.baseUrl = server.url
            viewModel.basicAuthBase64 = server.basicAuthBase64
            
            async {
                await self.viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            }
            
            // hide scroll indicators
            UITableView.appearance().showsVerticalScrollIndicator = false
        }
        .onReceive(timer) { _ in
            async {
                await viewModel.fetchCpu()
                await viewModel.fetchLoad()
                await viewModel.fetchRam()
                await viewModel.fetchDiskIo()
                await viewModel.fetchNetwork()
                await viewModel.fetchDiskSpace()
                
                for (index, bookmark) in viewModel.bookmarks.enumerated() {
                    do {
                        viewModel.bookmarkedChartData[index] = try await viewModel.netdataClient.getChartData(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64, chart: bookmark.id)
                    } catch {
                        debugPrint("Failed to fetch chart data")
                    }
                }
            }
        }
        .onDisappear {
            self.timer.upstream.connect().cancel()
        }
        .navigationBarTitle(server.name)
    }
    
    func getDataType(chart: ServerChart) -> GridDataType {
        if chart.units == "percentage" {
            return .percentage
        }
        else if chart.units == "seconds" {
            return .secondsToHours
        }
        
        return .absolute
    }
    
    func makeSectionHeader(text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
    }
    
    @ViewBuilder
    func getiPadSpacer() -> some View {
#if targetEnvironment(macCatalyst)
        Spacer(minLength: 36)
#else
        UIDevice.current.userInterfaceIdiom == .pad ? Spacer(minLength: 36) : nil
#endif
    }
}


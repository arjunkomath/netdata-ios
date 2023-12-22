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
    
    @ObservedObject var userSettings = UserSettings()
    @StateObject var viewModel = ServerDetailViewModel()
    
    @State var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                if viewModel.dataMode == .fifteenMins {
                    Section {
                        Link("Report an issue", destination: URL(string: "https://github.com/arjunkomath/netdata-ios/issues")!)
                    }
                    .readableGuidePadding()
                }
                
                Section("CPU (%)") {
                    switch (viewModel.dataMode) {
                    case .now:
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
                        
                    case .fifteenMins:
                        ChartView(datas: [viewModel.cpuUsageData])
                            .frame(height: 240)
                            .padding()
                            .listRowInsets(.init())
                    }
                }
                .headerProminence(.increased)
                .readableGuidePadding()
                
                Section("Load") {
                    switch (viewModel.dataMode) {
                    case .now:
                        DataGrid(labels: viewModel.load.labels,
                                 data: viewModel.load.data,
                                 dataType: .absolute,
                                 showArrows: false)
                        
                    case .fifteenMins:
                        ChartView(datas: [viewModel.load1ChartData, viewModel.load5ChartData, viewModel.load15ChartData], max: 1)
                            .frame(height: 250)
                            .padding()
                            .listRowInsets(.init())
                    }
                }
                .headerProminence(.increased)
                .readableGuidePadding()
                
                Section("Memory (MiB)") {
                    switch (viewModel.dataMode) {
                    case .now:
                        HStack {
                            Meter(progress: viewModel.ramUsageGauge)
                                .redacted(reason: self.viewModel.ramUsage.labels.count < 1 ? .placeholder : .init())
                            
                            self.getiPadSpacer()
                            
                            DataGrid(labels: viewModel.ramUsage.labels,
                                     data: viewModel.ramUsage.data,
                                     dataType: .absolute,
                                     showArrows: false)
                        }
                        
                    case .fifteenMins:
                        ChartView(datas: [viewModel.ramChartData], max: viewModel.ramMax)
                            .frame(height: 240)
                            .padding()
                            .listRowInsets(.init())
                    }
                }
                .headerProminence(.increased)
                .readableGuidePadding()
                
                Section("Disk") {
                    switch (viewModel.dataMode) {
                    case .now:
                        Group {
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
                    case .fifteenMins:
                        ChartView(datas: [viewModel.diskChartData], max: viewModel.diskMax)
                            .frame(height: 240)
                            .padding()
                            .listRowInsets(.init())
                    }
                }
                .headerProminence(.increased)
                .readableGuidePadding()
                
                if viewModel.dataMode == .now {
                    Section("Network") {
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
                    .headerProminence(.increased)
                    .readableGuidePadding()
                }
                
                if viewModel.bookmarkedChartData.count > 0 && viewModel.dataMode == .now {
                    Section("Pinned charts") {
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
                    .headerProminence(.increased)
                    .readableGuidePadding()
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .task {
            viewModel.baseUrl = server.url
            viewModel.basicAuthBase64 = server.basicAuthBase64
            
            await self.viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            
            // Start timer
            self.timer = Timer.publish(every: 1, on: .main, in: .common)
            _ = self.timer.connect()
        }
        .onReceive(timer) { _ in
            Task {
                await viewModel.fetchCpu()
                await viewModel.fetchLoad()
                await viewModel.fetchRam()
                await viewModel.fetchDiskIo()
                await viewModel.fetchNetwork()
                await viewModel.fetchDiskSpace()
                
                for (index, bookmark) in viewModel.bookmarks.enumerated() {
                    do {
                        viewModel.bookmarkedChartData[index] = try await NetdataClient.shared.getChartData(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64, chart: bookmark.id)
                    } catch {
                        debugPrint("[\(bookmark.id)] Failed to fetch chart data")
                    }
                }
            }
        }
        .onDisappear {
            self.timer.connect().cancel()
        }
        .navigationBarTitle(server.name)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                PulsatingView(live: viewModel.isLive)
            }
            
            ToolbarItem(placement: .principal) {
                if userSettings.enableCharts {
                    Picker("Data mode", selection: $viewModel.dataMode) {
                        Text("Now").tag(DataMode.now)
                        Text("15 Mins").tag(DataMode.fifteenMins)
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                NavigationLink(destination: ChartsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64)) {
                    HStack {
                        Image(systemName: "chart.pie")
                        Text("Charts")
                    }
                }
                .padding(.leading)
                
                Spacer()
                
                NavigationLink(destination: AlarmsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64)) {
                    HStack {
                        Image(systemName: "alarm")
                        Text("Alarms")
                    }
                }
                .padding(.trailing)
            }
        }
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
    
    @ViewBuilder
    func getiPadSpacer() -> some View {
#if targetEnvironment(macCatalyst)
        Spacer(minLength: 36)
#else
        UIDevice.current.userInterfaceIdiom == .pad ? Spacer(minLength: 36) : nil
#endif
    }
}


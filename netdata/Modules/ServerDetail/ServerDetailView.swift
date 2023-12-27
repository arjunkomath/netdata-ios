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
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: gridLayout(for: geometry.size.width), alignment: .leading, spacing: 12) {
                    RedactedView(loading: viewModel.cpuUsage.labels.count < 1) {
                        ServerDetailItem(label: "CPU Usage (%)") {
                            switch (viewModel.dataMode) {
                            case .now:
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
                                DataGrid(labels: viewModel.cpuUsage.labels,
                                         data: viewModel.cpuUsage.data,
                                         dataType: .percentage,
                                         showArrows: false)
                                
                            case .fifteenMins:
                                ChartView(data: viewModel.cpuUsage)
                                    .frame(height: 280)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        RedactedView(loading: viewModel.ramUsage.labels.count < 1) {
                            ServerDetailItem(label: "Memory (MiB)") {
                                switch (viewModel.dataMode) {
                                case .now:
                                    Meter(progress: viewModel.ramUsageGauge)
                                        .redacted(reason: self.viewModel.ramUsage.labels.count < 1 ? .placeholder : .init())
                                    DataGrid(labels: viewModel.ramUsage.labels,
                                             data: viewModel.ramUsage.data,
                                             dataType: .absolute,
                                             showArrows: false)
                                    
                                case .fifteenMins:
                                    ChartView(data: viewModel.ramUsage)
                                        .frame(height: 105)
                                }
                            }
                        }
                        
                        RedactedView(loading: viewModel.diskSpaceUsage.labels.count < 1) {
                            ServerDetailItem(label: "Space (GiB)") {
                                Meter(progress: viewModel.diskSpaceUsageGauge)
                                    .redacted(reason: viewModel.diskSpaceUsage.labels.count < 1 ? .placeholder : .init())
                                
                                DataGrid(labels: viewModel.diskSpaceUsage.labels,
                                         data: viewModel.diskSpaceUsage.data,
                                         dataType: .absolute,
                                         showArrows: false)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        RedactedView(loading: viewModel.load.labels.count < 1) {
                            ServerDetailItem(label: "Load") {
                                switch (viewModel.dataMode) {
                                case .now:
                                    DataGrid(labels: viewModel.load.labels,
                                             data: viewModel.load.data,
                                             dataType: .absolute,
                                             showArrows: false)
                                    
                                case .fifteenMins:
                                    ChartView(data: viewModel.load)
                                        .frame(height: 105)
                                }
                            }
                        }
                        
                        RedactedView(loading: viewModel.diskIO.labels.count < 1) {
                            ServerDetailItem(label: "I/O (KiB/s)") {
                                DataGrid(labels: viewModel.diskIO.labels,
                                         data: viewModel.diskIO.data,
                                         dataType: .absolute,
                                         showArrows: true)
                            }
                        }
                    }
                    
                    RedactedView(loading: viewModel.network.labels.count < 1) {
                        ServerDetailItem(label: "system.net (kilobits/s)") {
                            DataGrid(labels: viewModel.network.labels,
                                     data: viewModel.network.data,
                                     dataType: .absolute,
                                     showArrows: true)
                        }
                    }
                    
                    RedactedView(loading: viewModel.networkIPv4.labels.count < 1) {
                        ServerDetailItem(label: "system.ip (megabits/s)") {
                            DataGrid(labels: viewModel.networkIPv4.labels,
                                     data: viewModel.networkIPv4.data,
                                     dataType: .absolute,
                                     showArrows: true)
                        }
                    }
                    
                    RedactedView(loading: viewModel.networkIPv6.labels.count < 1) {
                        ServerDetailItem(label: "system.ipv6 (kilobits/s)") {
                            DataGrid(labels: viewModel.networkIPv6.labels,
                                     data: viewModel.networkIPv6.data,
                                     dataType: .absolute,
                                     showArrows: true)
                        }
                    }
                }
                .padding(16)
                
                if viewModel.bookmarkedChartData.count > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Pinned Charts", systemImage: "pin.circle.fill")
                        
                        LazyVGrid(columns: gridLayout(for: geometry.size.width), alignment: .leading, spacing: 12) {
                            ForEach(Array(viewModel.bookmarkedChartData.enumerated()), id: \.offset) { i, chart in
                                RedactedView(loading: chart.data.count == 0) {
                                    ServerDetailItem(label: viewModel.bookmarks[i].id) {
                                        if self.getDataType(chart: viewModel.bookmarks[i]) == .percentage {
                                            Meter(progress: viewModel.getGaugeData(data: chart.data))
                                                .redacted(reason: chart.labels.count < 1 ? .placeholder : .init())
                                        }
                                        
                                        DataGrid(labels: chart.labels,
                                                 data: chart.data,
                                                 dataType: self.getDataType(chart: viewModel.bookmarks[i]),
                                                 showArrows: false)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
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
            ToolbarItemGroup(placement: .navigation) {
                PulsatingView(live: viewModel.isLive)
                
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
                
                Spacer()
                
                NavigationLink(destination: AlarmsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64)) {
                    HStack {
                        Image(systemName: "alarm")
                        Text("Alarms")
                    }
                }
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
    
    private func gridLayout(for width: CGFloat) -> [GridItem] {
        let numberOfColumns = min(Int(width / 360), 3)
        return Array(repeating: .init(.flexible(), alignment: .topLeading), count: max(numberOfColumns, 1)) // Ensuring at least one column
    }
}


//
//  ServerDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI

struct ServerDetailView: View {
    var server: NDServer;
    
    @ObservedObject var userSettings = UserSettings()
    @StateObject var viewModel = ServerDetailViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Picker("Time range", selection: $viewModel.dataMode) {
                    Text("Current").tag(DataMode.now)
                    Text("Last 15 min").tag(DataMode.fifteenMins)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if viewModel.refreshFailed {
                    ErrorMessage(message: "Unable to refresh server data. Check the server connection.")
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

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
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if viewModel.load.labels.count > 0 {
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

                        if viewModel.diskIO.labels.count > 0 {
                            ServerDetailItem(label: "I/O (KiB/s)") {
                                switch viewModel.dataMode {
                                case .now:
                                    DataGrid(labels: viewModel.diskIO.labels,
                                             data: viewModel.diskIO.data,
                                             dataType: .absolute,
                                             showArrows: true)
                                case .fifteenMins:
                                    ChartView(data: viewModel.diskIO)
                                        .frame(height: 105)
                                }
                            }
                        }
                    }
                    
                    if viewModel.network.labels.count > 0 {
                        ServerDetailItem(label: "system.net (kilobits/s)") {
                            switch viewModel.dataMode {
                            case .now:
                                DataGrid(labels: viewModel.network.labels,
                                         data: viewModel.network.data,
                                         dataType: .absolute,
                                         showArrows: true)
                            case .fifteenMins:
                                ChartView(data: viewModel.network)
                                    .frame(height: 105)
                            }
                        }
                    }
                    
                    if viewModel.networkIPv4.labels.count > 0 {
                        ServerDetailItem(label: "system.ip (kilobits/s)") {
                            switch viewModel.dataMode {
                            case .now:
                                DataGrid(labels: viewModel.networkIPv4.labels,
                                         data: viewModel.networkIPv4.data,
                                         dataType: .absolute,
                                         showArrows: true)
                            case .fifteenMins:
                                ChartView(data: viewModel.networkIPv4)
                                    .frame(height: 105)
                            }
                        }
                    }

                    if viewModel.networkIPv6.labels.count > 0 {
                        ServerDetailItem(label: "system.ipv6 (kilobits/s)") {
                            switch viewModel.dataMode {
                            case .now:
                                DataGrid(labels: viewModel.networkIPv6.labels,
                                         data: viewModel.networkIPv6.data,
                                         dataType: .absolute,
                                         showArrows: true)
                            case .fifteenMins:
                                ChartView(data: viewModel.networkIPv6)
                                    .frame(height: 105)
                            }
                        }
                    }
                }
                .padding(16)
                
                if viewModel.bookmarkedChartData.count > 0 && viewModel.bookmarks.count > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Pinned Charts", systemImage: "pin.circle.fill")

                        LazyVGrid(columns: gridLayout(for: geometry.size.width), alignment: .leading, spacing: 12) {
                            ForEach(Array(viewModel.bookmarkedChartData.enumerated()), id: \.offset) { i, chart in
                                if i < viewModel.bookmarks.count {
                                    let bookmark = viewModel.bookmarks[i]
                                    RedactedView(loading: chart.data.count == 0) {
                                        ServerDetailItem(label: "\(bookmark.id) (\(bookmark.units == "seconds" ? "hours" : bookmark.units))") {
                                            switch viewModel.dataMode {
                                            case .now:
                                                if self.getDataType(chart: bookmark) == .percentage {
                                                    Meter(progress: viewModel.getGaugeData(data: chart.data))
                                                        .redacted(reason: chart.labels.count < 1 ? .placeholder : .init())
                                                }

                                                DataGrid(labels: chart.labels,
                                                         data: chart.data,
                                                         dataType: self.getDataType(chart: bookmark),
                                                         showArrows: false)
                                            case .fifteenMins:
                                                ChartView(
                                                    data: chart,
                                                    valueScale: bookmark.units == "seconds" ? 1.0 / 3600 : 1
                                                )
                                                    .frame(height: 105)
                                            }
                                        }
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
            await self.viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
        }
        .task(id: viewModel.dataMode) {
            let dataMode = viewModel.dataMode
            let refreshInterval: Duration = dataMode == .now ? .seconds(1) : .seconds(15)
            viewModel.baseUrl = server.url
            viewModel.basicAuthBase64 = server.basicAuthBase64
            viewModel.clearChartData()

            while !Task.isCancelled {
                await viewModel.refresh(dataMode: dataMode)

                do {
                    try await Task.sleep(for: refreshInterval)
                } catch {
                    return
                }
            }
        }
        .navigationBarTitle(server.name)
        .toolbar {
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
                        Image(systemName: "exclamationmark.triangle.fill")
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

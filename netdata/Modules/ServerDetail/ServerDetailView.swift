//
//  ServerDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI

struct ServerDetailNavigationView: View {
    let server: NDServer
    @State private var chartPath: [ServerChart] = []
    @State private var chartSearchText = ""

    var body: some View {
        TabView {
            NavigationStack {
                ServerDetailView(server: server, dataMode: .now)
            }
            .tabItem {
                Label("Live", systemImage: "waveform.path.ecg")
            }

            NavigationStack {
                ServerDetailView(server: server, dataMode: .fifteenMins)
            }
            .tabItem {
                Label("Last 15 mins", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack(path: $chartPath) {
                ChartsListView(serverUrl: server.url,
                               basicAuthBase64: server.basicAuthBase64,
                               searchText: $chartSearchText)
                    .navigationDestination(for: ServerChart.self) { chart in
                        CustomChartDetailView(serverChart: chart,
                                              serverUrl: server.url,
                                              basicAuthBase64: server.basicAuthBase64)
                    }
            }
            .tabItem {
                Label("Charts", systemImage: "chart.pie")
            }

            NavigationStack {
                AlarmsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            }
            .tabItem {
                Label("Alarms", systemImage: "exclamationmark.triangle.fill")
            }
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ServerDetailView: View {
    var server: NDServer;
    let dataMode: DataMode
    
    @StateObject private var userSettings = UserSettings()
    @StateObject private var viewModel = ServerDetailViewModel()
    @State private var presentedChart: ServerChart?
    @State private var showsPinnedEditor = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var minimumCardWidth: CGFloat = 320
    @ScaledMetric(relativeTo: .body) private var minimumChartHeight: CGFloat = 160
    @ScaledMetric(relativeTo: .body) private var minimumSummaryTileWidth: CGFloat = 76

    private let spacing: CGFloat = 12
    private let padding: CGFloat = 16
    
    var body: some View {
        GeometryReader { geometry in
            let chartHeight = max(minimumChartHeight, min(geometry.size.height * 0.35, 240))
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    if viewModel.refreshFailed {
                        ErrorMessage(message: "Unable to refresh server data. Check the server connection.")
                    }

                    switch dataMode {
                    case .now:
                        liveContent(width: geometry.size.width)
                    case .fifteenMins:
                        historyContent(width: geometry.size.width, chartHeight: chartHeight)
                    }

                    if viewModel.bookmarkedChartData.count > 0 && viewModel.bookmarks.count > 0 {
                        pinnedCharts(width: geometry.size.width, chartHeight: chartHeight)
                    }
                }
                .padding(padding)
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationDestination(isPresented: Binding(
            get: { presentedChart != nil },
            set: { if !$0 { presentedChart = nil } }
        )) {
            if let chart = presentedChart {
                CustomChartDetailView(serverChart: chart, serverUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            }
        }
        .sheet(isPresented: $showsPinnedEditor) {
            PinnedChartsEditor(userSettings: userSettings,
                               knownCharts: Dictionary(viewModel.bookmarks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }))
        }
        .task {
            await self.viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
        }
        .onChange(of: userSettings.bookmarks) { _ in
            Task { await viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64) }
        }
        .task {
            let refreshInterval: Duration = dataMode == .now ? .seconds(1) : .seconds(15)
            viewModel.baseUrl = server.url
            viewModel.basicAuthBase64 = server.basicAuthBase64

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
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Live

    @ViewBuilder
    private func liveContent(width: CGFloat) -> some View {
        summaryTiles(width: width)

        LazyVGrid(columns: gridLayout(for: width), alignment: .leading, spacing: spacing) {
            CPUUsageCard(data: viewModel.cpuUsage, cores: server.serverInfo?.cores_total)
                .redacted(reason: viewModel.cpuUsage.isLoaded ? [] : .placeholder)

            MemoryUsageCard(data: viewModel.ramUsage)
                .redacted(reason: viewModel.ramUsage.isLoaded ? [] : .placeholder)

            if viewModel.load.isLoaded || viewModel.diskIO.isLoaded {
                cardPair {
                    if viewModel.load.isLoaded {
                        LoadAverageCard(data: viewModel.load)
                    }
                } trailing: {
                    if viewModel.diskIO.isLoaded {
                        ThroughputCard(title: "Disk I/O", data: viewModel.diskIO, format: MetricFormat.kibPerSecond)
                    }
                }
            }

            if viewModel.network.isLoaded {
                ThroughputCard(title: "Network", data: viewModel.network, format: MetricFormat.kilobitsPerSecond)
            }

            if viewModel.networkIPv4.isLoaded || viewModel.networkIPv6.isLoaded {
                cardPair {
                    if viewModel.networkIPv4.isLoaded {
                        ThroughputCard(title: "IPv4", data: viewModel.networkIPv4, format: MetricFormat.kilobitsPerSecond)
                    }
                } trailing: {
                    if viewModel.networkIPv6.isLoaded {
                        ThroughputCard(title: "IPv6", data: viewModel.networkIPv6, format: MetricFormat.kilobitsPerSecond)
                    }
                }
            }
        }
    }

    private func summaryTiles(width: CGFloat) -> some View {
        let cpu = viewModel.cpuUsage.latestDimensions.reduce(0) { $0 + $1.value }
        let memoryDimensions = viewModel.ramUsage.latestDimensions
        let memoryTotal = memoryDimensions.reduce(0) { $0 + max($1.value, 0) }
        let memory = memoryTotal > 0 ? (viewModel.ramUsage.latestValue("used") ?? 0) / memoryTotal * 100 : 0
        let load = viewModel.load.latestDimensions.first?.value ?? 0
        let network = viewModel.network.latestDimensions.reduce(0) { $0 + abs($1.value) }

        return LazyVGrid(columns: summaryColumns(for: width), spacing: 8) {
            MetricSummaryTile(title: "CPU", value: MetricFormat.percent(cpu), tint: MetricFormat.usageColor(cpu))
                .redacted(reason: viewModel.cpuUsage.isLoaded ? [] : .placeholder)
            MetricSummaryTile(title: "Memory", value: MetricFormat.percent(memory), tint: MetricFormat.usageColor(memory))
                .redacted(reason: viewModel.ramUsage.isLoaded ? [] : .placeholder)
            MetricSummaryTile(title: "Load", value: String(format: "%.2f", load))
                .redacted(reason: viewModel.load.isLoaded ? [] : .placeholder)
            MetricSummaryTile(title: "Network", value: MetricFormat.kilobitsPerSecond(network))
                .redacted(reason: viewModel.network.isLoaded ? [] : .placeholder)
        }
    }

    // Shows two small cards side by side, or one at full width when the other has no data.
    private func cardPair<Leading: View, Trailing: View>(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: spacing) {
                    leading()
                    trailing()
                }
            } else {
                HStack(alignment: .top, spacing: spacing) {
                    leading()
                    trailing()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - History

    private func historyContent(width: CGFloat, chartHeight: CGFloat) -> some View {
        LazyVGrid(columns: gridLayout(for: width), alignment: .leading, spacing: spacing) {
            historyCard("CPU (%)", data: viewModel.cpuUsage, chartHeight: chartHeight, alwaysShow: true)
            historyCard("Memory (MiB)", data: viewModel.ramUsage, chartHeight: chartHeight, alwaysShow: true)
            historyCard("Load", data: viewModel.load, chartHeight: chartHeight)
            historyCard("Disk I/O (KiB/s)", data: viewModel.diskIO, chartHeight: chartHeight)
            historyCard("Network (kilobits/s)", data: viewModel.network, chartHeight: chartHeight)
            historyCard("IPv4 (kilobits/s)", data: viewModel.networkIPv4, chartHeight: chartHeight)
            historyCard("IPv6 (kilobits/s)", data: viewModel.networkIPv6, chartHeight: chartHeight)
        }
    }

    @ViewBuilder
    private func historyCard(_ title: String, data: ServerData, chartHeight: CGFloat, alwaysShow: Bool = false) -> some View {
        if alwaysShow || data.isLoaded {
            RedactedView(loading: !data.isLoaded) {
                ServerDetailItem(label: title) {
                    ChartView(data: data)
                        .frame(height: chartHeight)
                }
            }
        }
    }

    // MARK: - Pinned charts

    private func pinnedCharts(width: CGFloat, chartHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Pinned", systemImage: "pin")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Edit") { showsPinnedEditor = true }
                    .font(.subheadline)
            }
            .padding(.top, 8)

            LazyVGrid(columns: gridLayout(for: width), alignment: .leading, spacing: spacing) {
                ForEach(Array(viewModel.bookmarks.enumerated()), id: \.element.id) { index, chart in
                    let data = viewModel.bookmarkedChartData.indices.contains(index) ? viewModel.bookmarkedChartData[index] : .empty
                    PinnedChartCard(chart: chart,
                                    data: data,
                                    historyChartHeight: dataMode == .fifteenMins ? chartHeight : nil)
                        .redacted(reason: data.isLoaded ? [] : .placeholder)
                        // A tap gesture rather than a Button so the card's own "Show more" button stays tappable.
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .onTapGesture { presentedChart = chart }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { presentedChart = chart }
                        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .contextMenu {
                            Button {
                                presentedChart = chart
                            } label: {
                                Label("Open Chart", systemImage: "chart.xyaxis.line")
                            }
                            Button(role: .destructive) {
                                viewModel.removeBookmark(id: chart.id)
                                userSettings.bookmarks.removeAll { $0 == chart.id }
                            } label: {
                                Label("Unpin", systemImage: "pin.slash")
                            }
                        }
                }
            }
        }
    }

    private func gridLayout(for width: CGFloat) -> [GridItem] {
        let availableWidth = max(0, width - padding * 2)
        let numberOfColumns = dynamicTypeSize.isAccessibilitySize ? 1 :
            max(1, min(Int((availableWidth + spacing) / (minimumCardWidth + spacing)), 3))
        return Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: .topLeading), count: numberOfColumns)
    }

    private func summaryColumns(for width: CGFloat) -> [GridItem] {
        let availableWidth = max(0, width - padding * 2)
        let fitsFour = availableWidth >= minimumSummaryTileWidth * 4 + 8 * 3
        let count = dynamicTypeSize.isAccessibilitySize || !fitsFour ? 2 : 4
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }
}

private struct PinnedChartsEditor: View {
    @ObservedObject var userSettings: UserSettings
    /// Pinned charts that exist on the current server, keyed by chart id.
    let knownCharts: [String: ServerChart]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(userSettings.bookmarks, id: \.self) { id in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(knownCharts[id]?.displayTitle ?? id)
                            Text(knownCharts[id] == nil ? "Not available on this server" : id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onMove { userSettings.bookmarks.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { userSettings.bookmarks.remove(atOffsets: $0) }
                } footer: {
                    Text("Pinned charts sync across your devices and appear on every server that has them. Pin more from the Charts tab.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .overlay {
                if userSettings.bookmarks.isEmpty {
                    Text("No pinned charts")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Pinned Charts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

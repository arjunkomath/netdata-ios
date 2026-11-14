//
//  ServerDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI

struct ServerDetailNavigationView: View {
    let server: NDServer
    @State private var chartSearchText = ""
    @State private var path: [ServerChart] = []
    @State private var selectedTab = DetailTab.live
    @State private var showsNodePicker = false
    @ObservedObject var nodeSelection: NodeSelection

    private enum DetailTab: Hashable {
        case live, history, charts, alarms
    }

    /// The selected Child's GUID, or nil while viewing the Agent behind the server URL.
    private var node: String? { nodeSelection.selectedGuid }

    var body: some View {
        // One stack around the tabs, owned by the split view's detail column. A NavigationStack per
        // tab doesn't work there: those bars never show and their links can't push.
        NavigationStack(path: $path) {
            tabs
                .navigationDestination(for: ServerChart.self) { chart in
                    CustomChartDetailView(serverChart: chart,
                                          serverUrl: server.url,
                                          basicAuthBase64: server.basicAuthBase64,
                                          node: node)
                }
                .navigationTitle(nodeSelection.selectedNode?.nm ?? server.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Always supplying the principal item keeps the title visible; a title alone on the
                    // tab container doesn't show in the split view's collapsed detail.
                    ToolbarItem(placement: .principal) {
                        if nodeSelection.isParent {
                            NodePickerButton(serverName: server.name, selection: nodeSelection) {
                                showsNodePicker = true
                            }
                        } else {
                            Text(server.name)
                                .font(.headline)
                                .lineLimit(1)
                        }
                    }
                }
        }
        .sheet(isPresented: $showsNodePicker) {
            NodePickerSheet(selection: nodeSelection)
        }
        .task {
            await nodeSelection.load()
        }
        .onChange(of: nodeSelection.selectedGuid) { _ in
            // Charts opened on the previous node don't exist on the new one.
            path = []
        }
    }

    private var tabs: some View {
        // Each tab is keyed on the node so switching tears it down, which cancels its refresh loop
        // before the new node's first request.
        TabView(selection: $selectedTab) {
            ServerDetailView(server: server,
                             node: node,
                             nodeInfo: nodeSelection.selectedNode,
                             dataMode: .now,
                             openChart: openChart,
                             chooseNode: { showsNodePicker = true })
                .id(node)
                .tabItem {
                    Label("Live", systemImage: "waveform.path.ecg")
                }
                .tag(DetailTab.live)

            ServerDetailView(server: server,
                             node: node,
                             nodeInfo: nodeSelection.selectedNode,
                             dataMode: .fifteenMins,
                             openChart: openChart,
                             chooseNode: { showsNodePicker = true })
                .id(node)
                .tabItem {
                    Label("Last 15 mins", systemImage: "clock.arrow.circlepath")
                }
                .tag(DetailTab.history)

            ChartsListView(serverUrl: server.url,
                           basicAuthBase64: server.basicAuthBase64,
                           node: node,
                           searchText: $chartSearchText)
                .id(node)
                .tabItem {
                    Label("Charts", systemImage: "chart.pie")
                }
                .tag(DetailTab.charts)

            AlarmsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64, node: node)
                .id(node)
                .tabItem {
                    Label("Alarms", systemImage: "exclamationmark.triangle.fill")
                }
                .tag(DetailTab.alarms)
        }
    }

    private func openChart(_ chart: ServerChart) {
        path.append(chart)
    }
}

struct ServerDetailView: View {
    var server: NDServer;
    var node: String? = nil
    /// The selected Child as listed by the Parent; nil for the Agent behind the server URL.
    var nodeInfo: NetdataNode? = nil
    let dataMode: DataMode
    let openChart: (ServerChart) -> Void
    var chooseNode: () -> Void = {}
    
    @StateObject private var userSettings = UserSettings()
    @StateObject private var viewModel = ServerDetailViewModel()
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
                    if let nodeInfo, isStale {
                        StaleNodeBanner(nodeName: nodeInfo.nm, chooseNode: chooseNode)
                    }

                    if viewModel.refreshFailed && !(isStale && viewModel.lastError == .notFound) {
                        ErrorMessage(message: refreshErrorMessage)
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
        .sheet(isPresented: $showsPinnedEditor) {
            PinnedChartsEditor(userSettings: userSettings,
                               knownCharts: Dictionary(viewModel.bookmarks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }))
        }
        .task {
            await self.viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64, node: node)
        }
        .onChange(of: userSettings.bookmarks) { _ in
            Task { await viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64, node: node) }
        }
        .task {
            let refreshInterval: Duration = dataMode == .now ? .seconds(1) : .seconds(15)
            viewModel.baseUrl = server.url
            viewModel.basicAuthBase64 = server.basicAuthBase64
            viewModel.node = node

            while !Task.isCancelled {
                await viewModel.refresh(dataMode: dataMode)

                do {
                    try await Task.sleep(for: refreshInterval)
                } catch {
                    return
                }
            }
        }
    }

    private var isStale: Bool {
        nodeInfo.map { !$0.isReachable } ?? false
    }

    private var refreshErrorMessage: String {
        switch viewModel.lastError {
        case .authenticationFailed:
            return "The server rejected the saved credentials. Edit the server to update them."
        case .userIsOffline:
            return "You appear to be offline."
        case .notFound where nodeInfo != nil:
            return "\(nodeInfo?.nm ?? "This node") has no recent metrics on this Parent. It may be offline or no longer streaming."
        default:
            return "Unable to refresh server data. Check the server connection."
        }
    }

    // MARK: - Live

    @ViewBuilder
    private func liveContent(width: CGFloat) -> some View {
        summaryTiles(width: width)

        LazyVGrid(columns: gridLayout(for: width), alignment: .leading, spacing: spacing) {
            CPUUsageCard(data: viewModel.cpuUsage, cores: (nodeInfo?.serverInfo ?? server.serverInfo)?.cores_total)
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
                        ThroughputCard(title: "Disk I/O", data: viewModel.diskIO, format: MetricFormat.kibPerSecond, isCompact: true)
                    }
                }
            }

            if viewModel.network.isLoaded {
                ThroughputCard(title: "Network", data: viewModel.network, format: MetricFormat.kilobitsPerSecond)
            }

            if viewModel.networkIPv4.isLoaded || viewModel.networkIPv6.isLoaded {
                cardPair {
                    if viewModel.networkIPv4.isLoaded {
                        ThroughputCard(title: "IPv4", data: viewModel.networkIPv4, format: MetricFormat.kilobitsPerSecond, isCompact: true)
                    }
                } trailing: {
                    if viewModel.networkIPv6.isLoaded {
                        ThroughputCard(title: "IPv6", data: viewModel.networkIPv6, format: MetricFormat.kilobitsPerSecond, isCompact: true)
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
                        .onTapGesture { openChart(chart) }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { openChart(chart) }
                        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .contextMenu {
                            Button {
                                openChart(chart)
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

//
//  CustomChartDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 2/8/20.
//

import SwiftUI
import AlertToast

struct CustomChartDetailView: View {
    var serverChart: ServerChart
    var serverUrl: String
    var basicAuthBase64: String
    var node: String? = nil
    
    @State private var chartData = ServerData.empty
    @State private var historyData = ServerData.empty
    @State private var refreshFailed = false
    
    @State private var showAddedToast = false
    @State private var showRemovedToast = false
    
    @ObservedObject var userSettings = UserSettings()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if refreshFailed {
                    ErrorMessage(message: "Unable to refresh chart data. Check the server connection.")
                }

                PinnedChartCard(chart: serverChart,
                                data: chartData,
                                title: "Now",
                                showsDisclosure: false,
                                collapsesDimensions: false)
                    .redacted(reason: chartData.isLoaded ? [] : .placeholder)

                PinnedChartCard(chart: serverChart,
                                data: historyData,
                                historyChartHeight: 220,
                                title: "Last 15 minutes",
                                showsDisclosure: false,
                                showsChartID: false)
                    .redacted(reason: historyData.isLoaded ? [] : .placeholder)
            }
            .padding(16)
            .readableGuidePadding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitle(serverChart.displayTitle, displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                let isPinned = userSettings.bookmarks.contains(serverChart.id)
                Button {
                    userSettings.togglePin(serverChart.id)
                    if isPinned { showRemovedToast.toggle() } else { showAddedToast.toggle() }
                } label: {
                    Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.fill" : "pin")
                }
            }
        }
        .task(id: [serverUrl, basicAuthBase64, node ?? "", serverChart.id]) {
            while !Task.isCancelled {
                do {
                    let data = try await NetdataClient.shared.getChartData(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, node: node, chart: serverChart.name)
                    guard !Task.isCancelled else { return }
                    chartData = data
                    refreshFailed = false
                } catch {
                    guard !Task.isCancelled else { return }
                    debugPrint("Failed to fetchCustomChartData", serverChart.name)
                    refreshFailed = true
                }

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
        .task(id: [serverUrl, basicAuthBase64, node ?? "", serverChart.id]) {
            while !Task.isCancelled {
                if let data = try? await NetdataClient.shared.getChartDataWithHistory(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, node: node, chart: serverChart.name) {
                    guard !Task.isCancelled else { return }
                    historyData = data
                }

                do {
                    try await Task.sleep(for: .seconds(15))
                } catch {
                    return
                }
            }
        }
        .toast(isPresenting: $showAddedToast) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: "Chart pinned")
        }
        .toast(isPresenting: $showRemovedToast) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: "Chart unpinned")
        }
    }
}


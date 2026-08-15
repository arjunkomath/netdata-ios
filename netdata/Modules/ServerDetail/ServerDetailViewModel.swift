//
//  ServerDetailViewModel.swift
//  netdata
//
//  Created by Arjun Komath on 27/7/20.
//

import Foundation
import Combine
import SwiftUI

enum DataMode {
    case now
    case fifteenMins
}

@MainActor class ServerDetailViewModel: ObservableObject {
    
    // MARK:- Real time data
    @Published var cpuUsage: ServerData = .empty
    @Published var cpuUsageData: [Double] = []
    @Published var load: ServerData = .empty
    @Published var ramUsage: ServerData = .empty
    @Published var ramUsageGauge : CGFloat = 0
    
    // MARK:- Disk
    @Published var diskIO: ServerData = .empty
    
    // MARK:- Network
    @Published var network: ServerData = .empty
    @Published var networkIPv4: ServerData = .empty
    @Published var networkIPv6: ServerData = .empty
    
    // MARK:- Bookmarks
    @Published var bookmarks: [ServerChart] = []
    @Published var bookmarkedChartData: [ServerData] = []
    
    // MARK:- Data mode
    @Published var dataMode: DataMode = .now
    @Published var refreshFailed = false
    
    var baseUrl = ""
    var basicAuthBase64 = ""

    func fetchChart(_ chart: String, dataMode: DataMode) async throws -> ServerData {
        switch dataMode {
        case .now:
            return try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: chart)
        case .fifteenMins:
            return try await NetdataClient.shared.getChartDataWithHistory(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: chart)
        }
    }

    func clearChartData() {
        cpuUsage = .empty
        cpuUsageData = []
        load = .empty
        ramUsage = .empty
        ramUsageGauge = 0
        diskIO = .empty
        network = .empty
        networkIPv4 = .empty
        networkIPv6 = .empty
        bookmarkedChartData = Array(repeating: .empty, count: bookmarks.count)
        refreshFailed = false
    }

    func refresh(dataMode: DataMode) async {
        let anyCoreSucceeded = await withTaskGroup(of: Bool.self, returning: Bool.self) { group in
            group.addTask { await self.fetchCpu(dataMode: dataMode) }
            group.addTask { await self.fetchLoad(dataMode: dataMode) }
            group.addTask { await self.fetchRam(dataMode: dataMode) }
            group.addTask { await self.fetchDiskIo(dataMode: dataMode) }
            group.addTask { await self.fetchNetwork(dataMode: dataMode) }

            var succeeded = false
            for await result in group {
                succeeded = result || succeeded
            }
            return succeeded
        }

        guard !Task.isCancelled else { return }

        let bookmarks = self.bookmarks
        var chartDataByIndex = [Int: ServerData]()
        await withTaskGroup(of: (Int, ServerData?).self) { group in
            for (index, bookmark) in bookmarks.enumerated() {
                group.addTask {
                    do {
                        let chartData = try await self.fetchChart(bookmark.id, dataMode: dataMode)
                        return (index, chartData)
                    } catch {
                        debugPrint("[\(bookmark.id)] Failed to fetch chart data")
                        return (index, nil)
                    }
                }
            }

            for await (index, chartData) in group {
                chartDataByIndex[index] = chartData
            }
        }

        guard !Task.isCancelled else { return }
        guard bookmarks.map(\.id) == self.bookmarks.map(\.id) else { return }

        self.bookmarkedChartData = bookmarks.indices.map {
            chartDataByIndex[$0] ?? .empty
        }
        self.refreshFailed = !anyCoreSucceeded
    }
    
    func fetchCpu(dataMode: DataMode) async -> Bool {
        do {
            let data = try await fetchChart("system.cpu", dataMode: dataMode)
            guard !Task.isCancelled else { return false }
            
            self.cpuUsage = data
            self.cpuUsageData = Array(self.cpuUsage.data).reversed().map({ d in d.count > 1 ? Array(d[1..<d.count]).reduce(0, { acc, val in acc + (val ?? 0) }) : 0 })
            return true
        } catch {
            guard !Task.isCancelled else { return false }
            debugPrint("[fetchCpu] Failed to fetch chart data: \(error)")
            self.cpuUsage = .empty
            self.cpuUsageData = []
            return false
        }
    }
    
    func fetchLoad(dataMode: DataMode) async -> Bool {
        do {
            let data = try await fetchChart("system.load", dataMode: dataMode)
            guard !Task.isCancelled else { return false }

            self.load = data
            return true
        } catch {
            guard !Task.isCancelled else { return false }
            debugPrint("[fetchLoad] Failed to fetch chart data: \(error)")
            self.load = .empty
            return false
        }
    }
    
    func fetchRam(dataMode: DataMode) async -> Bool {
        do {
            let data = try await fetchChart("system.ram", dataMode: dataMode)
            guard !Task.isCancelled else { return false }

            self.ramUsage = data
            self.ramUsageGauge = 0
            
            if let dataPoint = self.ramUsage.data.first {
                let free = dataPoint.indices.contains(1) ? (dataPoint[1] ?? 0) : 0
                let used = dataPoint.indices.contains(2) ? (dataPoint[2] ?? 0) : 0
                let cached = dataPoint.indices.contains(3) ? (dataPoint[3] ?? 0) : 0
                let total = free + used + cached
                if total > 0 {
                    self.ramUsageGauge = CGFloat(used / total)
                }
            }
            return true
        } catch {
            guard !Task.isCancelled else { return false }
            debugPrint("[fetchRam] Failed to fetch chart data")
            self.ramUsage = .empty
            self.ramUsageGauge = 0
            return false
        }
    }
    
    func fetchDiskIo(dataMode: DataMode) async -> Bool {
        do {
            let data = try await fetchChart("system.io", dataMode: dataMode)
            guard !Task.isCancelled else { return false }

            self.diskIO = data
            return true
        } catch {
            guard !Task.isCancelled else { return false }
            debugPrint("[fetchDiskIo] Failed to fetch chart data")
            self.diskIO = .empty
            return false
        }
    }
    
    func fetchNetwork(dataMode: DataMode) async -> Bool {
        async let network = try? fetchChart("system.net", dataMode: dataMode)
        async let networkIPv4 = try? fetchChart("system.ip", dataMode: dataMode)
        async let networkIPv6 = try? fetchChart("system.ipv6", dataMode: dataMode)

        let results = await (network, networkIPv4, networkIPv6)
        guard !Task.isCancelled else { return false }

        var succeeded = false
        if let network = results.0 {
            self.network = network
            succeeded = true
        } else {
            debugPrint("[fetchNetwork] Failed to fetch system.net")
            self.network = .empty
        }
        if let networkIPv4 = results.1 {
            self.networkIPv4 = networkIPv4
            succeeded = true
        } else {
            debugPrint("[fetchNetwork] Failed to fetch system.ip")
            self.networkIPv4 = .empty
        }
        if let networkIPv6 = results.2 {
            self.networkIPv6 = networkIPv6
            succeeded = true
        } else {
            debugPrint("[fetchNetwork] Failed to fetch system.ipv6")
            self.networkIPv6 = .empty
        }
        return succeeded
    }
    
    func updateBookmarks(baseUrl: String, basicAuthBase64: String) async {
        // Always fetch latest bookmarks, avoid adding user settings
        let bookmarks = NSUbiquitousKeyValueStore.default.array(forKey: "bookmarks") as? [String] ?? []
        
        // Fetch charts for bookmarks
        if bookmarks.count > 0 {
            do {
                let charts = try await NetdataClient.shared.getCharts(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64)
                
                self.bookmarks = bookmarks
                    .compactMap { chart in
                        charts.charts[chart]
                    }
                
                self.bookmarkedChartData = Array(repeating: .empty, count: self.bookmarks.count)
            } catch {
                guard !Task.isCancelled else { return }
                debugPrint("fetchCharts", error)
            }
        } else {
            self.bookmarks = []
            self.bookmarkedChartData = []
        }
    }
    
    func getGaugeData(data: [[Double?]]) -> CGFloat {
        guard let first = data.first, first.count > 1 else { return 0 }
        return CGFloat(Array(first[1..<first.count]).reduce(0, { acc, val in acc + (val ?? 0) }) / 100)
    }
    
    func validateServer(serverUrl: String) async -> Bool {
        do {
            let _ = try await NetdataClient.shared.getInfo(baseUrl: serverUrl)
            return true
        } catch {
            debugPrint(error)
            return false
        }
    }
}

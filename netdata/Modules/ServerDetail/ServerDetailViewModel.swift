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
    @Published var cpuUsage: ServerData = ServerData(labels: [], data: [])
    @Published var cpuUsageData: [Double] = []
    @Published var load: ServerData = ServerData(labels: [], data: [])
    @Published var ramUsage: ServerData = ServerData(labels: [], data: [])
    @Published var ramUsageGauge : CGFloat = 0
    
    // MARK:- Disk
    @Published var diskIO: ServerData = ServerData(labels: [], data: [])
    
    // MARK:- Network
    @Published var network: ServerData = ServerData(labels: [], data: [])
    @Published var networkIPv4: ServerData = ServerData(labels: [], data: [])
    @Published var networkIPv6: ServerData = ServerData(labels: [], data: [])
    
    // MARK:- Bookmarks
    @Published var bookmarks: [ServerChart] = []
    @Published var bookmarkedChartData: [ServerData] = []
    
    // MARK:- Data mode
    @Published var isLive: Bool = false
    @Published var dataMode: DataMode = .now
    
    var baseUrl = ""
    var basicAuthBase64 = ""
    
    func fetchCpu() async {
        do {
            let data = self.dataMode == .now ?
            try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.cpu") :
            try await NetdataClient.shared.getChartDataWithHistory(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.cpu")
            
            self.cpuUsage = data
            self.cpuUsageData = Array(self.cpuUsage.data).reversed().map({ d in d.count > 1 ? Array(d[1..<d.count]).reduce(0, { acc, val in acc + (val ?? 0) }) : 0 })
            
            self.isLive = true
        } catch {
            debugPrint("[fetchCpu] Failed to fetch chart data: \(error)")
            self.isLive = false
        }
    }
    
    func fetchLoad() async {
        do {
            self.load = self.dataMode == .now ?
            try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.load") :
            try await NetdataClient.shared.getChartDataWithHistory(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.load")
        } catch {
            debugPrint("[fetchLoad] Failed to fetch chart data: \(error)")
        }
    }
    
    func fetchRam() async {
        do {
            let data = self.dataMode == .now ?
            try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.ram") :
            try await NetdataClient.shared.getChartDataWithHistory(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.ram")
            self.ramUsage = data
            
            if let dataPoint = self.ramUsage.data.first {
                let free = dataPoint.indices.contains(1) ? (dataPoint[1] ?? 0) : 0
                let used = dataPoint.indices.contains(2) ? (dataPoint[2] ?? 0) : 0
                let cached = dataPoint.indices.contains(3) ? (dataPoint[3] ?? 0) : 0
                let total = free + used + cached
                if total > 0 {
                    self.ramUsageGauge = CGFloat(used / total)
                }
            }
        } catch {
            debugPrint("[fetchRam] Failed to fetch chart data")
        }
    }
    
    func fetchDiskIo() async {
        do {
            self.diskIO = self.dataMode == .now ?
            try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.io") :
            try await NetdataClient.shared.getChartDataWithHistory(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.io")
        } catch {
            debugPrint("[fetchDiskIo] Failed to fetch chart data")
        }
    }
    
    func fetchNetwork() async {
        do {
            self.network = try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.net")
            self.networkIPv4 = try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.ip")
            self.networkIPv6 = try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.ipv6")
        } catch {
            debugPrint("[fetchNetwork] Failed to fetch chart data")
        }
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
                
                self.bookmarkedChartData = Array(repeating: ServerData(labels: [], data: []), count: self.bookmarks.count)
            } catch {
                debugPrint("fetchCharts", error)
            }
        } else {
            self.bookmarks = []
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


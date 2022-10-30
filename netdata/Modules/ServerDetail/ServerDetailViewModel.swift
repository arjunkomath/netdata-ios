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
    @Published var diskSpaceUsage: ServerData = ServerData(labels: [], data: [])
    @Published var diskSpaceUsageGauge : CGFloat = 0
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
    
    // MARK:- Charts
    @Published var ramChartData: [Double] = []
    @Published var ramMax: Double = 0
    
    @Published var load1ChartData: [Double] = []
    @Published var load5ChartData: [Double] = []
    @Published var load15ChartData: [Double] = []
    
    @Published var diskChartData: [Double] = []
    @Published var diskMax: Double = 0
    
    var baseUrl = ""
    var basicAuthBase64 = ""
    
    func fetchCpu() async {
        do {
            let data = self.dataMode == .now ?
            try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.cpu") :
            try await NetdataClient.shared.getChartDataWithHistory(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.cpu")
            
            self.cpuUsage = data
            self.cpuUsageData = Array(self.cpuUsage.data).reversed().map({ d in Array(d[1..<d.count]).reduce(0, { acc, val in acc + (val ?? 0) }) })
            
            self.isLive = true
        } catch {
            debugPrint("[fetchCpu] Failed to fetch chart data")
            self.isLive = false
        }
    }
    
    func fetchLoad() async {
        do {
            self.load = self.dataMode == .now ?
            try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.load") :
            try await NetdataClient.shared.getChartDataWithHistory(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.load")
            
            self.load1ChartData = Array(self.load.data).reversed().map({ $0[1] ?? 0 })
            self.load5ChartData = Array(self.load.data).reversed().map({ $0[2] ?? 0  })
            self.load15ChartData = Array(self.load.data).reversed().map({ $0[3] ?? 0 })
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
                if let free = dataPoint[1], let used = dataPoint[2], let cached = dataPoint[3] {
                    self.ramUsageGauge = CGFloat(used / (free + used + cached))
                    
                    self.ramChartData = Array(self.ramUsage.data).reversed().map({ $0[2] ?? 0 })
                    self.ramMax = free + used + cached
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
    
    func fetchDiskSpace() async {
        do {
            let data = try await NetdataClient.shared.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "disk_space._")
            self.diskSpaceUsage = data
            
            if let dataPoint = self.diskSpaceUsage.data.first {
                if let avail = dataPoint[1], let used = dataPoint[2] {
                    self.diskSpaceUsageGauge = CGFloat(used / (avail + used))
                    
                    self.diskChartData = Array(self.diskSpaceUsage.data).reversed().map({ $0[2] ?? 0 })
                    self.diskMax = avail + used
                }
            }
        } catch {
            debugPrint("[fetchDiskSpace] Failed to fetch chart data")
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
        return data.count == 0 ? 0 : CGFloat(Array(data.first![1..<data.first!.count]).reduce(0, { acc, val in acc + (val ?? 0) }) / 100)
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


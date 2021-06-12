//
//  ServerDetailViewModel.swift
//  netdata
//
//  Created by Arjun Komath on 27/7/20.
//

import Foundation
import Combine
import SwiftUI

final class ServerDetailViewModel: ObservableObject {
    
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
    
    var baseUrl = ""
    var basicAuthBase64 = ""
    
    var netdataClient = NetdataClient()
    
    func fetchCpu() async {
        do {
            let data = try await netdataClient.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.cpu")
            
            self.cpuUsage = data
            self.cpuUsageData = Array(self.cpuUsage.data).reversed().map({ d in Array(d[1..<d.count]).reduce(0, { acc, val in acc + (val ?? 0) }) })
        } catch {
            debugPrint("Failed to fetch chart data")
        }
    }
    
    func fetchLoad() async {
        do {
            self.load = try await netdataClient.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.load")
        } catch {
            debugPrint("Failed to fetch chart data")
        }
    }
    
    func fetchRam() async {
        do {
            let data = try await netdataClient.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.ram")
            
            self.ramUsage = data
            self.ramUsageGauge = CGFloat(self.ramUsage.data.first![2]! / (self.ramUsage.data.first![1]! + self.ramUsage.data.first![2]! + self.ramUsage.data.first![3]!))
        } catch {
            debugPrint("Failed to fetch chart data")
        }
    }
    
    func fetchDiskIo() async {
        do {
            self.diskIO = try await netdataClient.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.io")
        } catch {
            debugPrint("Failed to fetch chart data")
        }
    }
    
    func fetchNetwork() async {
        do {
            self.network = try await netdataClient.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.net")
            self.networkIPv4 = try await netdataClient.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.ip")
            self.networkIPv6 = try await netdataClient.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "system.ipv6")
        } catch {
            debugPrint("Failed to fetch chart data")
        }
    }
    
    func fetchDiskSpace() async {
        do {
            let data = try await netdataClient.getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: "disk_space._")
            
            self.diskSpaceUsage = data
            self.diskSpaceUsageGauge = CGFloat(self.diskSpaceUsage.data.first![2]! / (self.diskSpaceUsage.data.first![1]! + self.diskSpaceUsage.data.first![2]!))
        } catch {
            debugPrint("Failed to fetch chart data")
        }
    }
    
    func updateBookmarks(baseUrl: String, basicAuthBase64: String) async {
        // Always fetch latest bookmarks, avoid adding user settings
        let bookmarks = NSUbiquitousKeyValueStore.default.array(forKey: "bookmarks") as? [String] ?? []
        
        // Fetch charts for bookmarks
        if bookmarks.count > 0 {
            do {
                let charts = try await netdataClient.getCharts(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64)
                
                self.bookmarks = bookmarks
                    .compactMap { chart in
                        charts.charts[chart]
                    }.filter { chart in
                        chart.enabled
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
            let _ = try await netdataClient.getInfo(baseUrl: serverUrl)
            return true
        } catch {
            debugPrint(error)
            return false
        }
    }
}


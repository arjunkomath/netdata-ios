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
    
    // MARK:- Custom Charts
    @Published var serverCharts: ServerCharts = ServerCharts(version: "", release_channel: "", charts: [:])
    @Published var customChartData: ServerData = ServerData(labels: [], data: [])
    @Published var bookmarkedChartData: [ServerData] = []
    
    // MARK:- Alarms
    @Published var serverAlarms: ServerAlarms = ServerAlarms(status: false, alarms: [:])
    
    // MARK:- Bookmarks
    @Published var bookmarks: [ServerChart] = []
    
    private var baseUrl = ""
    private var basicAuthBase64 = ""
    
    // MARK:- Timers
    private var timer = Timer()
    private var customChartTimer = Timer()
    private var bookmarksDataTimer = Timer()
    
    private var cancellable = Set<AnyCancellable>()
    
    func fetch(baseUrl: String, basicAuthBase64: String) {
        debugPrint("fetch", baseUrl)
        self.baseUrl = baseUrl
        self.basicAuthBase64 = basicAuthBase64
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.fetchCpu()
            self.fetchLoad()
            self.fetchRam()
            self.fetchDiskIo()
            self.fetchNetwork()
            self.fetchDiskSpace()
        }
    }
    
    func updateBookmarks(baseUrl: String, basicAuthBase64: String) {
        // Always fetch latest bookmarks, avoid adding user settings
        let bookmarks = NSUbiquitousKeyValueStore.default.array(forKey: "bookmarks") as? [String] ?? []
        
        self.bookmarksDataTimer.invalidate()
        
        // Fetch charts for bookmarks
        if bookmarks.count > 0 {
            NetDataAPI
                .getCharts(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        debugPrint("fetchCharts", error)
                    }
                }) { data in
                    self.bookmarks = bookmarks
                        .compactMap { chart in
                            data.charts[chart]
                        }.filter { chart in
                            chart.enabled
                        }
                    
                    self.bookmarkedChartData = Array(repeating: ServerData(labels: [], data: []), count: self.bookmarks.count)
                    
                    self.bookmarksDataTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                        for (index, bookmark) in self.bookmarks.enumerated() {
                            NetDataAPI
                                .getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: bookmark.id)
                                .sink(receiveCompletion: { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure(let error):
                                        debugPrint("fetch bookmarks data", error)
                                    }
                                }) { data in
                                    self.bookmarkedChartData[index] = data
                                }
                                .store(in: &self.cancellable)
                        }
                    }
                }
                .store(in: &self.cancellable)
        } else {
            self.bookmarks = []
        }
    }
    
    func fetchCpu() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64, chart: "system.cpu")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.cpuUsage = data
                self.cpuUsageData = Array(self.cpuUsage.data).reversed().map({ d in Array(d[1..<d.count]).reduce(0, { acc, val in acc + (val ?? 0) }) })
            }
            .store(in: &self.cancellable)
    }
    
    func fetchLoad() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64, chart: "system.load")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.load = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchRam() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64, chart: "system.ram")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.ramUsage = data
                
                self.ramUsageGauge = CGFloat(self.ramUsage.data.first![2]! / (self.ramUsage.data.first![1]! + self.ramUsage.data.first![2]! + self.ramUsage.data.first![3]!))
            }
            .store(in: &self.cancellable)
    }
    
    func fetchDiskIo() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64, chart: "system.io")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.diskIO = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchNetwork() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64, chart: "system.net")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.network = data
            }
            .store(in: &self.cancellable)
        
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64, chart: "system.ip")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.networkIPv4 = data
            }
            .store(in: &self.cancellable)
        
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64, chart: "system.ipv6")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.networkIPv6 = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchDiskSpace() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64, chart: "disk_space._")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.diskSpaceUsage = data
                
                self.diskSpaceUsageGauge = CGFloat(self.diskSpaceUsage.data.first![2]! / (self.diskSpaceUsage.data.first![1]! + self.diskSpaceUsage.data.first![2]!))
            }
            .store(in: &self.cancellable)
    }
    
    func fetchCharts(baseUrl: String, basicAuthBase64: String) {
        debugPrint("fetchCharts", baseUrl)
        NetDataAPI
            .getCharts(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint("fetchCharts", error)
                }
            }) { data in
                self.serverCharts = data
            }
            .store(in: &self.cancellable)
    }
    
    func destroyChartsList() {
        debugPrint("destroyChartsList")
        serverCharts = ServerCharts(version: "", release_channel: "", charts: [:])
    }
    
    func fetchCustomChartData(baseUrl: String, basicAuthBase64: String, chart: String) {
        debugPrint("fetchCustomChartData", baseUrl)
        self.customChartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            NetDataAPI
                .getChartData(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64, chart: chart)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        debugPrint("fetchCustomChartData", error)
                    }
                }) { data in
                    self.customChartData = data
                }
                .store(in: &self.cancellable)
        }
    }
    
    func destroyCustomChartData() {
        debugPrint("destroyCustomChartData")
        customChartData = ServerData(labels: [], data: [])
        
        self.customChartTimer.invalidate()
    }
    
    func fetchAlarms(baseUrl: String, basicAuthBase64: String) {
        debugPrint("fetchAlarms", baseUrl)
        NetDataAPI
            .getAlarms(baseUrl: baseUrl, basicAuthBase64: basicAuthBase64)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint("getAlarms", error)
                }
            },
            receiveValue: { alarms in
                self.serverAlarms = alarms
            })
            .store(in: &cancellable)
    }
    
    func getGaugeData(data: [[Double?]]) -> CGFloat {
        return data.count == 0 ? 0 : CGFloat(Array(data.first![1..<data.first!.count]).reduce(0, { acc, val in acc + (val ?? 0) }) / 100)
    }
    
    func destroyAlarmsData() {
        debugPrint("destroyAlarmsData")
        serverAlarms = ServerAlarms(status: false, alarms: [:])
    }
    
    func validateServer(serverUrl: String, completion: @escaping (Bool) -> ()) {
        NetDataAPI
            .getInfo(baseUrl: serverUrl)
            .sink(receiveCompletion: { _completion in
                print(_completion)
                switch _completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint(error)
                    completion(false)
                }
            },
            receiveValue: { info in
                completion(true)
            })
            .store(in: &cancellable)
    }
    
    func destroy() {
        debugPrint("destroy")
        // stop timer
        self.timer.invalidate()
        self.bookmarksDataTimer.invalidate()
    }
}


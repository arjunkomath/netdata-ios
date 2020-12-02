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
    
    @Published var loading = true
    
    // MARK:- Charts
    @Published var serverCharts: ServerCharts = ServerCharts(version: "", release_channel: "", charts: [:])
    @Published var serverChartsToolbarButton = true
    
    @Published var cpuUsage: ServerData = ServerData(labels: [], data: [])
    @Published var cpuUsageGauge: CGFloat = 0
    
    @Published  var ramUsage: ServerData = ServerData(labels: [], data: [])
    @Published  var ramUsageGauge : CGFloat = 0
    
    @Published  var diskSpaceUsage: ServerData = ServerData(labels: [], data: [])
    @Published  var diskSpaceUsageGauge : CGFloat = 0
    
    @Published var load: ServerData = ServerData(labels: [], data: [])
    @Published var diskIO: ServerData = ServerData(labels: [], data: [])
    @Published var network: ServerData = ServerData(labels: [], data: [])
    
    // MARK:- Custom Charts
    @Published var customChartData: ServerData = ServerData(labels: [], data: [])
    
    private var baseUrl = ""
    private var basicAuthBase64 = ""
    private var timer = Timer()
    private var customChartTimer = Timer()
    private var cancellable = Set<AnyCancellable>()
    
    func fetch(baseUrl: String, basicAuthBase64: String) {
        self.loading = true
        self.baseUrl = baseUrl
        self.basicAuthBase64 = basicAuthBase64
        
        self.fetchCharts()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !self.serverCharts.charts.isEmpty {
                if (self.serverChartsToolbarButton) {
                    self.serverChartsToolbarButton = false
                }
            }
            self.fetchCpu()
            self.fetchLoad()
            self.fetchRam()
            self.fetchDiskIo()
            self.fetchNetwork()
            self.fetchDiskSpace()
        }
    }
    
    func destroy() {
        self.timer.invalidate()
    }
    
    func fetchCpu() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.cpu", basicAuthBase64: self.basicAuthBase64)
            .sink(receiveCompletion: { _ in
            }) { data in
                self.cpuUsage = data
                
                withAnimation(.linear(duration: 0.5)) {
                    self.cpuUsageGauge = CGFloat(Array(self.cpuUsage.data.first![1..<self.cpuUsage.data.first!.count]).reduce(0, { acc, val in acc + (val ?? 0) }) / 100)
                }
            }
            .store(in: &self.cancellable)
    }
    
    func fetchLoad() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.load", basicAuthBase64: self.basicAuthBase64)
            .sink(receiveCompletion: { _ in
            }) { data in
                self.load = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchRam() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.ram", basicAuthBase64: self.basicAuthBase64)
            .sink(receiveCompletion: { _ in
            }) { data in
                self.ramUsage = data
                
                withAnimation(.linear(duration: 0.5)) {
                    self.ramUsageGauge = CGFloat(self.ramUsage.data.first![2]! / (self.ramUsage.data.first![1]! + self.ramUsage.data.first![2]! + self.ramUsage.data.first![3]!))
                }
            }
            .store(in: &self.cancellable)
    }
    
    func fetchDiskIo() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.io", basicAuthBase64: self.basicAuthBase64)
            .sink(receiveCompletion: { _ in
            }) { data in
                self.diskIO = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchNetwork() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.net", basicAuthBase64: self.basicAuthBase64)
            .sink(receiveCompletion: { _ in
            }) { data in
                self.network = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchDiskSpace() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "disk_space._", basicAuthBase64: self.basicAuthBase64)
            .sink(receiveCompletion: { _ in
            }) { data in
                self.diskSpaceUsage = data
                
                withAnimation(.linear(duration: 0.5)) {
                    self.diskSpaceUsageGauge = CGFloat(self.diskSpaceUsage.data.first![2]! / (self.diskSpaceUsage.data.first![1]! + self.diskSpaceUsage.data.first![2]!))
                }
            }
            .store(in: &self.cancellable)
    }
    
    func fetchCharts() {
        NetDataAPI
            .getCharts(baseUrl: self.baseUrl, basicAuthBase64: self.basicAuthBase64)
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
    
    func fetchCustomChartData(baseUrl: String, chart: String) {
        self.customChartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            NetDataAPI
                .getChartData(baseUrl: baseUrl, chart: chart, basicAuthBase64: self.basicAuthBase64)
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
        customChartData = ServerData(labels: [], data: [])
        
        self.customChartTimer.invalidate()
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
    
    func destroyModel() {
        serverCharts = ServerCharts(version: "", release_channel: "", charts: [:])
        serverChartsToolbarButton = true
        
        cpuUsage = ServerData(labels: [], data: [])
        cpuUsageGauge = CGFloat(0)
        
        ramUsage = ServerData(labels: [], data: [])
        ramUsageGauge = CGFloat(0)
        
        diskSpaceUsage = ServerData(labels: [], data: [])
        diskSpaceUsageGauge = CGFloat (0)
        
        load = ServerData(labels: [], data: [])
        diskIO = ServerData(labels: [], data: [])
        network = ServerData(labels: [], data: [])
    }
}


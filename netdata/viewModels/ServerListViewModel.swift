//
//  ServerListViewModel.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import Foundation
import SwiftUI
import Combine

final class ServerListViewModel: ObservableObject {
    @Published var loading = true
    @Published var serverInfo = NDServer(uid: "uuid",
                                         os_name: "name",
                                         os_version: "os_version",
                                         kernel_name: "kernel_name",
                                         architecture: "architecture")
    
    // MARK:- Charts
    @Published var cpuUsage: NDChartData = NDChartData(labels: [], data: [])
    @Published var cpuUsageGauge: CGFloat = 0
    
    @Published  var ramUsage: NDChartData = NDChartData(labels: [], data: [])
    @Published  var ramUsageGauge : CGFloat = 0
    
    @Published var load: NDChartData = NDChartData(labels: [], data: [])
    @Published var diskIO: NDChartData = NDChartData(labels: [], data: [])
    @Published var network: NDChartData = NDChartData(labels: [], data: [])
    
    private var baseUrl = ""
    private var timer = Timer()
    private var cancellable = Set<AnyCancellable>()
    
    func fetch(baseUrl: String) {
        self.loading = true
        self.baseUrl = baseUrl
        
        NetDataAPI
            .getInfo(baseUrl: baseUrl)
            .sink(receiveCompletion: { completion in
                self.loading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    debugPrint(error)
                }
            }) { info in
                self.loading = false
                self.serverInfo = info
            }
            .store(in: &self.cancellable)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.fetchCpu()
            self.fetchLoad()
            self.fetchRam()
            self.fetchDiskIo()
            self.fetchNetwork()
        }
    }
    
    func destroy() {
        self.timer.invalidate()
    }
    
    func fetchCpu() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.cpu")
            .subscribe(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in
            }) { data in
                self.cpuUsage = data
                self.cpuUsageGauge = CGFloat(Array(self.cpuUsage.data.first![1..<self.cpuUsage.data.first!.count]).reduce(0, +) / 100)
            }
            .store(in: &self.cancellable)
    }
    
    func fetchLoad() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.load")
            .subscribe(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in
            }) { data in
                self.load = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchRam() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.ram")
            .subscribe(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in
            }) { data in
                self.ramUsage = data
                self.ramUsageGauge = CGFloat(self.ramUsage.data.first![1] / (self.ramUsage.data.first![1] + self.ramUsage.data.first![2]))
            }
            .store(in: &self.cancellable)
    }
    
    func fetchDiskIo() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.io")
            .subscribe(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in
            }) { data in
                self.diskIO = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchNetwork() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.net")
            .subscribe(on: DispatchQueue.global())
            .sink(receiveCompletion: { _ in
            }) { data in
                self.network = data
            }
            .store(in: &self.cancellable)
    }
}

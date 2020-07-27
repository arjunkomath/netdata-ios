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
    @Published var cpuUsage: ServerData = ServerData(labels: [], data: [])
    @Published var cpuUsageGauge: CGFloat = 0
    
    @Published  var ramUsage: ServerData = ServerData(labels: [], data: [])
    @Published  var ramUsageGauge : CGFloat = 0
    
    @Published var load: ServerData = ServerData(labels: [], data: [])
    @Published var diskIO: ServerData = ServerData(labels: [], data: [])
    @Published var network: ServerData = ServerData(labels: [], data: [])
    
    private var baseUrl = ""
    private var timer = Timer()
    private var cancellable = Set<AnyCancellable>()
    
    func fetch(baseUrl: String) {
        self.loading = true
        self.baseUrl = baseUrl
        
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
            .sink(receiveCompletion: { _ in
            }) { data in
                self.cpuUsage = data
                
                withAnimation(.linear(duration: 0.5)) {
                    self.cpuUsageGauge = CGFloat(Array(self.cpuUsage.data.first![1..<self.cpuUsage.data.first!.count]).reduce(0, +) / 100)
                }
            }
            .store(in: &self.cancellable)
    }
    
    func fetchLoad() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.load")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.load = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchRam() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.ram")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.ramUsage = data
                
                withAnimation(.linear(duration: 0.5)) {
                    self.ramUsageGauge = CGFloat(self.ramUsage.data.first![1] / (self.ramUsage.data.first![1] + self.ramUsage.data.first![2]))
                }
            }
            .store(in: &self.cancellable)
    }
    
    func fetchDiskIo() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.io")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.diskIO = data
            }
            .store(in: &self.cancellable)
    }
    
    func fetchNetwork() {
        NetDataAPI
            .getChartData(baseUrl: self.baseUrl, chart: "system.net")
            .sink(receiveCompletion: { _ in
            }) { data in
                self.network = data
            }
            .store(in: &self.cancellable)
    }
}

//
//  ServerDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI
import SwiftyJSON

struct ServerDetailView: View {
    var server: Server;
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var loading: Bool = true
    @State private var serverInfo: NDServerInfo = NDServerInfo.placeholder()
    
    // MARK:- Charts
    @State private var cpuUsage: NDServerData = NDServerData.placeholder()
    @State private var cpuUsageGauge : CGFloat = 0
    
    @State private var ramUsage: NDServerData = NDServerData.placeholder()
    @State private var ramUsageGauge : CGFloat = 0
    
    var body: some View {
        List {
            if self.loading {
                RowLoadingView()
            } else {
                Section(header: Text("Info")) {
                    Text("\(serverInfo.osName) \(serverInfo.osVersion)")
                    Text("\(serverInfo.kernelName) (\(serverInfo.architecture))")
                }
                
                Section(header: Text("System Usage")) {
                    HStack {
                        Meter(progress: self.$cpuUsageGauge, title: .constant("CPU"))
                        Meter(progress: self.$ramUsageGauge, title: .constant("RAM"))
                    }
                }
                .onReceive(timer) { input in
                    self.fetchCharts()
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle(server.name)
        .onAppear(perform: self.fetchServerInfo)
    }
    
    private func fetchCharts() {
        NetDataApiService.getChartData(baseUrl: server.url, chart: "system.cpu") { data in
            if let json = try? JSON(data: data) {
                self.cpuUsage = NDServerData(labels: json["labels"].arrayValue.map { $0.stringValue},
                                             data: json["data"].arrayValue.map { $0.arrayValue.map { $0.doubleValue } })
                
                withAnimation(Animation.default.speed(0.55)){
                    self.cpuUsageGauge = CGFloat(Array(self.cpuUsage.data.first![1..<self.cpuUsage.data.first!.count]).reduce(0, +) / 100)
                }
            }
        }
        
        NetDataApiService.getChartData(baseUrl: server.url, chart: "system.ram") { data in
            if let json = try? JSON(data: data) {
                self.ramUsage = NDServerData(labels: json["labels"].arrayValue.map { $0.stringValue},
                                             data: json["data"].arrayValue.map { $0.arrayValue.map { $0.doubleValue } })
                
                let latestEntry = self.ramUsage.data.first!
                
                withAnimation(Animation.default.speed(0.55)){
                    self.ramUsageGauge = CGFloat(latestEntry[1] / (latestEntry[1] + latestEntry[2]))
                }
            }
        }
    }
    
    private func fetchServerInfo() {
        self.loading = true
        
        NetDataApiService.getServerInfo(baseUrl: server.url) { data in
            self.loading = false
            
            if let json = try? JSON(data: data) {
                self.serverInfo = NDServerInfo(osName: json["os_name"].string!,
                                               osVersion: json["os_version"].string!,
                                               kernelName: json["kernel_name"].string!,
                                               architecture: json["architecture"].string!)
            }
        }
    }
}


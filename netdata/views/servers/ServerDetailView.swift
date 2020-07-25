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
            Section(header: Text("Info")) {
                Text("\(serverInfo.osName) \(serverInfo.osVersion)")
                    .redacted(reason: loading ? .placeholder : .init())
                Text("\(serverInfo.kernelName) (\(serverInfo.architecture))")
                    .redacted(reason: loading ? .placeholder : .init())
            }
            
            Section(header: Text("CPU Usage")) {
                VStack {
                    Spacer()
                    HStack {
                        Meter(progress: self.$cpuUsageGauge, title: .constant("Total"))
                            .frame(width: 110)
                            .redacted(reason: cpuUsage.labels.count < 1 ? .placeholder : .init())
                        
                        if cpuUsage.labels.count > 1 {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                                ForEach(1..<self.cpuUsage.labels.count) { i in
                                    PercentageUsageData(usage: .constant(CGFloat(self.cpuUsage.data[i])), title: self.$cpuUsage.labels[i])
                                }
                            }
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                                ForEach((1...6), id: \.self) { _ in
                                    PercentageUsageData(usage: .constant(0.1), title: .constant("loading"))
                                        .redacted(reason: .placeholder)
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
            
            Section(header: Text("Memory Usage")) {
                VStack {
                    Spacer()
                    HStack {
                        Meter(progress: self.$ramUsageGauge, title: .constant("Total"))
                            .frame(width: 110)
                            .redacted(reason: ramUsage.labels.count < 1 ? .placeholder : .init())
                        
                        if ramUsage.labels.count > 1 {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                                ForEach(1..<self.ramUsage.labels.count) { i in
                                    AbsoluteUsageData(usage: .constant(CGFloat(self.ramUsage.data[i])), title: self.$ramUsage.labels[i])
                                }
                            }
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                                ForEach((1...6), id: \.self) { _ in
                                    AbsoluteUsageData(usage: .constant(0.1), title: .constant("loading"))
                                        .redacted(reason: .placeholder)
                                }
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear(perform: self.fetchServerInfo)
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(server.name)
        .onReceive(timer) { _ in
            self.fetchCharts()
        }
    }
    
    private func fetchCharts() {
        NetDataApiService.getChartData(baseUrl: server.url, chart: "system.cpu") { data in
            if let json = try? JSON(data: data) {
                self.cpuUsage = NDServerData(labels: json["labels"].arrayValue.map { $0.stringValue},
                                             data: json["data"][0].arrayValue.map { $0.doubleValue } )
                
                withAnimation(Animation.default.speed(0.55)){
                    self.cpuUsageGauge = CGFloat(Array(self.cpuUsage.data[1..<self.cpuUsage.data.count]).reduce(0, +) / 100)
                }
            }
        }
        
        NetDataApiService.getChartData(baseUrl: server.url, chart: "system.ram") { data in
            if let json = try? JSON(data: data) {
                self.ramUsage = NDServerData(labels: json["labels"].arrayValue.map { $0.stringValue},
                                             data: json["data"][0].arrayValue.map { $0.doubleValue } )
                
                let latestEntry = self.ramUsage.data
                
                withAnimation(Animation.default.speed(0.55)){
                    self.ramUsageGauge = CGFloat(latestEntry[1] / (latestEntry[1] + latestEntry[2]))
                }
            }
        }
    }
    
    private func fetchServerInfo() {        
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


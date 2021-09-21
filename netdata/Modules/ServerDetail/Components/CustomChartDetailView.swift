//
//  CustomChartDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 2/8/20.
//

import SwiftUI

struct CustomChartDetailView: View {
    var serverChart: ServerChart
    var serverUrl: String
    var basicAuthBase64: String
    
    @State private var chartData = ServerData(labels: [], data: [])
    @State private var isLive = false
    
    @ObservedObject var userSettings = UserSettings()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        List {
            Section("\(serverChart.name) (\(units()))") {
                DataGrid(labels: chartData.labels,
                         data: chartData.data,
                         dataType: self.getDataType(),
                         showArrows: false)
            }
            .headerProminence(.increased)
            .readableGuidePadding()
            
            if userSettings.bookmarks.contains(serverChart.id) {
                Button(action: {
                    withAnimation {
                        userSettings.bookmarks = userSettings.bookmarks.filter { $0 != serverChart.id }
                    }
                }, label: {
                    Label("Remove pin", systemImage: "pin")
                })
                .readableGuidePadding()
            } else {
                Button(action: {
                    withAnimation {
                        userSettings.bookmarks.insert(serverChart.id, at: 0)
                    }
                }, label: {
                    Label("Pin chart", systemImage: "pin.fill")
                })
                .readableGuidePadding()
            }
        }
        .navigationBarTitle(serverChart.name, displayMode: .inline)
        .onReceive(timer) { _ in
            Task {
                do {
                    chartData = try await NetdataClient.shared.getChartData(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, chart: serverChart.name)
                    isLive = true
                } catch {
                    debugPrint("Failed to fetchCustomChartData", serverChart.name)
                    isLive = false
                }
            }
        }
        .onDisappear {
            self.timer.upstream.connect().cancel()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                PulsatingView(live: isLive)
            }
        }
    }
    
    func units() -> String {
        if serverChart.units == "seconds" {
            return "hours"
        }
        else {
            return serverChart.units
        }
    }
    
    func getDataType() -> GridDataType {
        if serverChart.units == "percentage" {
            return .percentage
        }
        else if serverChart.units == "seconds" {
            return .secondsToHours
        }
        
        return .absolute
    }
}

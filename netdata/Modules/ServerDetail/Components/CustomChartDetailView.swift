//
//  CustomChartDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 2/8/20.
//

import SwiftUI
import AlertToast

struct CustomChartDetailView: View {
    var serverChart: ServerChart
    var serverUrl: String
    var basicAuthBase64: String
    
    @State private var chartData = ServerData.empty
    @State private var refreshFailed = false
    
    @State private var showAddedToast = false
    @State private var showRemovedToast = false
    
    @ObservedObject var userSettings = UserSettings()
    
    var body: some View {
        List {
            if refreshFailed {
                ErrorMessage(message: "Unable to refresh chart data. Check the server connection.")
                    .readableGuidePadding()
            }

            Section("\(serverChart.name) (\(units()))") {
                DataGrid(labels: chartData.labels,
                         data: chartData.data,
                         dataType: self.getDataType(),
                         showArrows: false)
                    .readableGuidePadding()
            }
            .headerProminence(.increased)
            
            if userSettings.bookmarks.contains(serverChart.id) {
                Button(action: {
                    userSettings.bookmarks = userSettings.bookmarks.filter { $0 != serverChart.id }
                    showRemovedToast.toggle()
                }, label: {
                    Label("Remove pin", systemImage: "pin")
                })
                .readableGuidePadding()
            } else {
                Button(action: {
                    // Fix warning https://developer.apple.com/forums/thread/711899
                    userSettings.bookmarks.insert(serverChart.id, at: 0)
                    showAddedToast.toggle()
                }, label: {
                    Label("Pin chart", systemImage: "pin.fill")
                })
                .readableGuidePadding()
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitle(serverChart.name, displayMode: .inline)
        .task(id: [serverUrl, basicAuthBase64, serverChart.id]) {
            while !Task.isCancelled {
                do {
                    let data = try await NetdataClient.shared.getChartData(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, chart: serverChart.name)
                    guard !Task.isCancelled else { return }
                    chartData = data
                    refreshFailed = false
                } catch {
                    guard !Task.isCancelled else { return }
                    debugPrint("Failed to fetchCustomChartData", serverChart.name)
                    refreshFailed = true
                }

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
        .toast(isPresenting: $showAddedToast) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: "Chart Added")
        }
        .toast(isPresenting: $showRemovedToast) {
            AlertToast(displayMode: .banner(.pop), type: .complete(.green), title: "Chart Removed")
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

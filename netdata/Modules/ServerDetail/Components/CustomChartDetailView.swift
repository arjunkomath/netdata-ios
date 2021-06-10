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
    
    @StateObject var viewModel = ServerDetailViewModel()
    @ObservedObject var userSettings = UserSettings()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        List {
            Section(header: Text("\(serverChart.name) (\(units()))").sectionHeaderStyle().padding(.top)) {
                DataGrid(labels: viewModel.customChartData.labels,
                         data: viewModel.customChartData.data,
                         dataType: self.getDataType(),
                         showArrows: false)
            }
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
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(serverChart.name)
        .onDisappear {
            viewModel.customChartData = ServerData(labels: [], data: [])
        }
        .onReceive(timer) { _ in
            async {
                do {
                    viewModel.customChartData = try await viewModel.netdataClient.getChartData(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, chart: serverChart.name)
                } catch {
                    debugPrint("Failed to fetchCustomChartData", serverChart.name)
                }
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

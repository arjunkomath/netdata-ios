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
    
    var body: some View {
        List {
            Section(header: Text("Info").sectionHeaderStyle()) {
                Text(serverChart.title)
                    .font(.headline)
            }
            
            Section(header: Text("\(serverChart.name) (\(units()))").sectionHeaderStyle()) {
                DataGrid(labels: viewModel.customChartData.labels,
                         data: viewModel.customChartData.data,
                         dataType: self.getDataType(),
                         showArrows: false)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            viewModel.fetchCustomChartData(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, chart: serverChart.name)
        }
        .onDisappear {
            viewModel.destroyCustomChartData()
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

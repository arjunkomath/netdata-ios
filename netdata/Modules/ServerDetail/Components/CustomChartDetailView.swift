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
    
    @StateObject var viewModel = ServerDetailViewModel()
    
    var body: some View {
        List {
            Section(header: Text("Info").sectionHeaderStyle()) {
                Text(serverChart.title)
                    .font(.headline)
            }
            
            Section(header: Text("\(serverChart.name) (\(serverChart.units))").sectionHeaderStyle()) {
                DataGrid(labels: viewModel.customChartData.labels,
                         data: viewModel.customChartData.data,
                         dataType: self.getDataType(),
                         showArrows: false)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .onAppear {
            viewModel.fetchCustomChartData(baseUrl: serverUrl, chart: serverChart.name)
        }
        .onDisappear {
            viewModel.destroyCustomChartData()
        }
    }
    
    func getDataType() -> GridDataType {
        if serverChart.units == "percentage" {
            return .percentage
        }
        
        return .absolute
    }
}

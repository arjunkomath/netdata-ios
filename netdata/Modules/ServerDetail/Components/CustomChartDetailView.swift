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
            Text(serverChart.title)
                .font(.headline)
            
            Section(header: makeSectionHeader(text: serverChart.name)) {
                DataGrid(labels: viewModel.customChartData.labels,
                         data: viewModel.customChartData.data,
                         dataType: .absolute,
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
    
    func makeSectionHeader(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .bold()
            .foregroundColor(.gray)
    }
}

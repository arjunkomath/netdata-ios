//
//  ChartsListView.swift
//  netdata
//
//  Created by Arjun Komath on 1/8/20.
//

import SwiftUI

struct ChartsListView: View {
    var serverCharts: ServerCharts
    var serverUrl: String
    
    var body: some View {
        NavigationView {
            List {
                ForEach(serverCharts.charts.keys.sorted(), id: \.self) { key in
                    if serverCharts.charts[key] != nil && serverCharts.charts[key]!.enabled == true {
                        NavigationLink(destination: CustomChartDetailView(serverChart: serverCharts.charts[key]!,
                                                                          serverUrl: serverUrl)) {
                            ChartListRow(chart: serverCharts.charts[key]!)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Available Charts"), displayMode: .inline)
        }
    }
}

struct ChartsListView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsListView(serverCharts: ServerCharts(version: "1.0",
                                                  release_channel: "beta",
                                                  charts: [:]),
                       serverUrl: "")
    }
}

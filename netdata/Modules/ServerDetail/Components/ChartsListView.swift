//
//  ChartsListView.swift
//  netdata
//
//  Created by Arjun Komath on 1/8/20.
//

import SwiftUI

struct ChartsListView: View {
    @Environment(\.presentationMode) private var presentationMode
    var serverCharts: ServerCharts
    var serverUrl: String
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                List {
                    ForEach(serverCharts.charts.keys.sorted().filter({ searchText.isEmpty ? true : $0.contains(searchText) }), id: \.self) { key in
                        if serverCharts.charts[key] != nil && serverCharts.charts[key]!.enabled == true {
                            NavigationLink(destination: CustomChartDetailView(serverChart: serverCharts.charts[key]!,
                                                                              serverUrl: serverUrl)) {
                                ChartListRow(chart: serverCharts.charts[key]!)
                            }
                        }
                    }
                }
                .navigationTitle(Text("Available Charts")).navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: dismissButton)
            }
        }
    }
    
    private var dismissButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .imageScale(.small)
        }
        .buttonStyle(BorderedBarButtonStyle())
        .accentColor(Color.red)
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

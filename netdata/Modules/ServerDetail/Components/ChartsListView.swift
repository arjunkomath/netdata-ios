//
//  ChartsListView.swift
//  netdata
//
//  Created by Arjun Komath on 1/8/20.
//

import SwiftUI

struct ChartsListView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var serverUrl: String
    var basicAuthBase64: String
    
    @State private var searchText = ""
    @State private var charts = ServerCharts(version: "", release_channel: "", charts: [:])
    
    var body: some View {
        List {
            ForEach(getActiveCharts()) { chart in
                ChartListRow(chart: chart,
                             serverUrl: serverUrl,
                             basicAuthBase64: basicAuthBase64)
            }
        }
        .navigationTitle(Text("All Charts"))
        .searchable(text: $searchText)
        .onAppear {
            async {
                do {
                    charts = try await NetdataClient.shared.getCharts(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64)
                } catch {
                    debugPrint("fetchCharts", error)
                }
            }
        }
    }
    
    private func getActiveCharts() -> [ServerChart] {
        if searchText.isEmpty {
            return charts.activeCharts
        }
        
        return charts.activeCharts.filter {
            $0.name.lowercased().contains(searchText.lowercased())
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
        ChartsListView(serverUrl: "", basicAuthBase64: "")
    }
}

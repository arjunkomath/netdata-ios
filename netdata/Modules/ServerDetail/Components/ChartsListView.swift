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
    
    @State private var loading = false
    @State private var charts = ServerCharts(version: "", release_channel: "", charts: [:])
    @State private var searchText = ""
    
    var body: some View {
        List {
            if loading {
                VStack(alignment: .center, spacing: 16) {
                    ProgressView()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
            }
            
            ForEach(getActiveCharts()) { chart in
                ChartListRow(chart: chart,
                             serverUrl: serverUrl,
                             basicAuthBase64: basicAuthBase64)
            }
        }
        .navigationTitle(Text("All Charts"))
        .searchable(text: $searchText)
        .refreshable {
            await fetchCharts()
        }
        .onAppear {
            async {
                await fetchCharts()
            }
        }
    }
    
    private func fetchCharts() async {
        loading = true
        do {
            loading = false
            charts = try await NetdataClient.shared.getCharts(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64)
        } catch {
            loading = false
            debugPrint("fetchCharts", error)
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

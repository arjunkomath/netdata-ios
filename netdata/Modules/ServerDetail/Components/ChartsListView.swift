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
    
    @StateObject var viewModel = ServerDetailViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.serverCharts.charts.keys.sorted().filter({ searchText.isEmpty ? true : $0.lowercased().contains(searchText.lowercased()) }), id: \.self) { key in
                        if viewModel.serverCharts.charts[key] != nil && viewModel.serverCharts.charts[key]!.enabled == true {
                            NavigationLink(destination: CustomChartDetailView(serverChart: viewModel.serverCharts.charts[key]!,
                                                                              serverUrl: serverUrl,
                                                                              basicAuthBase64: basicAuthBase64)) {
                                ChartListRow(chart: viewModel.serverCharts.charts[key]!)
                            }
                        }
                    }
                }
                .navigationTitle(Text("Available Charts")).navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: dismissButton)
                .searchable(text: $searchText)
                .onAppear {
                    async {
                        await viewModel.fetchCharts(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64)
                    }
                }
                .onDisappear {
                    viewModel.destroyChartsList()
                }
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
        ChartsListView(serverUrl: "", basicAuthBase64: "")
    }
}

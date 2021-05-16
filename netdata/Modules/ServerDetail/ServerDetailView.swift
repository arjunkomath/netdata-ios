//
//  ServerDetailView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI
import Combine

final class ServerDetailActiveSheet: ObservableObject {
    enum Kind {
        case alarms
        case charts
        case none
    }
    
    @Published var kind: Kind = .none {
        didSet { showSheet = kind != .none }
    }
    
    @Published var showSheet: Bool = false
}

struct ServerDetailView: View {
    var server: NDServer;
    
    @StateObject var viewModel = ServerDetailViewModel()
    @ObservedObject var activeSheet = ServerDetailActiveSheet()
    
    @State private var showSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(header: makeSectionHeader(text: "CPU (%)")) {
                    HStack {
                        VStack {
                            Meter(progress: viewModel.getGaugeData(data: viewModel.cpuUsage.data))
                                .redacted(reason: viewModel.cpuUsage.labels.count < 1 ? .placeholder : .init())
                            
                            if (server.serverInfo != nil && viewModel.cpuUsage.labels.count > 0) {
                                Spacer()
                                
                                AbsoluteUsageData(stringValue: server.serverInfo?.cores_total,
                                                  title: "cores",
                                                  showArrows: false)
                            }
                            
                            
                        }
                        
                        self.getiPadSpacer()
                        
                        DataGrid(labels: viewModel.cpuUsage.labels,
                                 data: viewModel.cpuUsage.data,
                                 dataType: .percentage,
                                 showArrows: false)
                    }
                }
                .readableGuidePadding()
                
                Section(header: makeSectionHeader(text: "Load")) {
                    DataGrid(labels: viewModel.load.labels,
                             data: viewModel.load.data,
                             dataType: .absolute,
                             showArrows: false)
                }
                .readableGuidePadding()
                
                Section(header: makeSectionHeader(text: "Memory (MiB)")) {
                    HStack {
                        Meter(progress: viewModel.ramUsageGauge)
                            .redacted(reason: self.viewModel.ramUsage.labels.count < 1 ? .placeholder : .init())
                        
                        self.getiPadSpacer()
                        
                        DataGrid(labels: viewModel.ramUsage.labels,
                                 data: viewModel.ramUsage.data,
                                 dataType: .absolute,
                                 showArrows: false)
                    }
                }
                .readableGuidePadding()
                
                Section(header: makeSectionHeader(text: "Disk")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Space (GiB)")
                            .font(.subheadline)
                            .padding(.vertical, 4)
                        
                        HStack {
                            Meter(progress: viewModel.diskSpaceUsageGauge)
                                .redacted(reason: viewModel.diskSpaceUsage.labels.count < 1 ? .placeholder : .init())
                            
                            self.getiPadSpacer()
                            
                            DataGrid(labels: viewModel.diskSpaceUsage.labels,
                                     data: viewModel.diskSpaceUsage.data,
                                     dataType: .absolute,
                                     showArrows: false)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I/O (KiB/s)")
                            .font(.subheadline)
                            .padding(.vertical, 4)
                        
                        DataGrid(labels: viewModel.diskIO.labels,
                                 data: viewModel.diskIO.data,
                                 dataType: .absolute,
                                 showArrows: true)
                    }
                }
                .readableGuidePadding()
                
                Section(header: makeSectionHeader(text: "Network")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("system.net (kilobits/s)")
                            .font(.subheadline)
                            .padding(.vertical, 4)
                        
                        DataGrid(labels: viewModel.network.labels,
                                 data: viewModel.network.data,
                                 dataType: .absolute,
                                 showArrows: true)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("system.ip (megabits/s)")
                            .font(.subheadline)
                            .padding(.vertical, 4)
                        
                        DataGrid(labels: viewModel.networkIPv4.labels,
                                 data: viewModel.networkIPv4.data,
                                 dataType: .absolute,
                                 showArrows: true)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("system.ipv6 (kilobits/s)")
                            .font(.subheadline)
                            .padding(.vertical, 4)
                        
                        DataGrid(labels: viewModel.networkIPv6.labels,
                                 data: viewModel.networkIPv6.data,
                                 dataType: .absolute,
                                 showArrows: true)
                    }
                }
                .readableGuidePadding()
                
                if viewModel.bookmarkedChartData.count > 0 {
                    Section(header: makeSectionHeader(text: "Bookmarks")) {
                        ForEach(Array(viewModel.bookmarkedChartData.enumerated()), id: \.offset) { i, chart in
                            HStack {
                                if self.getDataType(chart: viewModel.bookmarks[i]) == .percentage {
                                    Meter(progress: viewModel.getGaugeData(data: chart.data))
                                        .redacted(reason: chart.labels.count < 1 ? .placeholder : .init())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.bookmarks[i].id)
                                        .font(.subheadline)
                                        .padding(.vertical, 4)
                                    
                                    DataGrid(labels: chart.labels,
                                             data: chart.data,
                                             dataType: self.getDataType(chart: viewModel.bookmarks[i]),
                                             showArrows: false)
                                }
                            }
                        }
                    }
                    .readableGuidePadding()
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            BottomBar {
                Button(action: {
                    self.activeSheet.kind = .charts
                    self.viewModel.destroy()
                    self.showSheet.toggle()
                }) {
                    Image(systemName: "chart.pie")
                    Text("Charts")
                }
                .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    self.activeSheet.kind = .alarms
                    self.viewModel.destroy()
                    self.showSheet.toggle()
                }) {
                    Image(systemName: "alarm")
                    Text("Alarms")
                }
                .padding(.trailing)
            }
        }
        .onAppear {
            self.viewModel.fetch(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            self.viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            // hide scroll indicators
            UITableView.appearance().showsVerticalScrollIndicator = false
        }
        .onDisappear {
            self.viewModel.destroy()
        }
        .navigationBarTitle(server.name, displayMode: .inline)
        .sheet(isPresented: self.$activeSheet.showSheet, onDismiss: {
            // workaround for onAppear not being called after the sheet is dismissed
            self.viewModel.fetch(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
            self.viewModel.updateBookmarks(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)
        }, content: {
            self.sheet
        })
    }
    
    private var sheet: some View {
        switch activeSheet.kind {
        case .none: return AnyView(EmptyView())
        case .alarms: return AnyView(AlarmsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64))
        case .charts: return AnyView(ChartsListView(serverUrl: server.url, basicAuthBase64: server.basicAuthBase64))
        }
    }
    
    func getDataType(chart: ServerChart) -> GridDataType {
        if chart.units == "percentage" {
            return .percentage
        }
        else if chart.units == "seconds" {
            return .secondsToHours
        }
        
        return .absolute
    }
    
    func makeSectionHeader(text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
    }
    
    func getiPadSpacer() -> AnyView? {
        #if targetEnvironment(macCatalyst)
        return AnyView(Spacer(minLength: 36))
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? AnyView(Spacer(minLength: 36)) : nil
        #endif
    }
}


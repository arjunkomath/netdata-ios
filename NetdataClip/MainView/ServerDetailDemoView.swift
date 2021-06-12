//
//  ServerDetailDemoView.swift
//  NetdataClip
//
//  Created by Arjun Komath on 25/10/20.
//

import SwiftUI

struct ServerDetailDemoView: View {
    var serverUrl: String
    
    @StateObject var viewModel = ServerDetailViewModel()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        List {
            Section(header: makeSectionHeader(text: "CPU (%)")) {
                HStack {
                    VStack {
                        Meter(progress: viewModel.getGaugeData(data: viewModel.cpuUsage.data))
                            .redacted(reason: self.viewModel.cpuUsage.labels.count < 1 ? .placeholder : .init())
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
                        .redacted(reason: viewModel.ramUsage.labels.count < 1 ? .placeholder : .init())
                    
                    self.getiPadSpacer()
                    
                    DataGrid(labels: viewModel.ramUsage.labels,
                             data: viewModel.ramUsage.data,
                             dataType: .absolute,
                             showArrows: false)
                }
            }
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Disk Space (GiB)")) {
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
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Disk I/O (KiB/s)")) {
                DataGrid(labels: viewModel.diskIO.labels,
                         data: viewModel.diskIO.data,
                         dataType: .absolute,
                         showArrows: true)
            }
            .readableGuidePadding()
            
            Section(header: makeSectionHeader(text: "Network (kilobits/s)")) {
                DataGrid(labels: viewModel.network.labels,
                         data: viewModel.network.data,
                         dataType: .absolute,
                         showArrows: true)
            }
            .readableGuidePadding()
        }
        .onAppear {
            viewModel.baseUrl = serverUrl
            viewModel.basicAuthBase64 = ""
            
            // hide scroll indicators
            UITableView.appearance().showsVerticalScrollIndicator = false
        }
        .onReceive(timer) { _ in
            async {
                await viewModel.fetchCpu()
                await viewModel.fetchLoad()
                await viewModel.fetchRam()
                await viewModel.fetchDiskIo()
                await viewModel.fetchNetwork()
                await viewModel.fetchDiskSpace()
            }
        }
        .onDisappear {
            self.timer.upstream.connect().cancel()
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    func makeSectionHeader(text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
    }
    
    @ViewBuilder
    func getiPadSpacer() -> some View {
        #if targetEnvironment(macCatalyst)
        Spacer(minLength: 36)
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? Spacer(minLength: 36) : nil
        #endif
    }
}

struct ServerDetailDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ServerDetailDemoView(serverUrl: "https://cdn77.my-netdata.io")
    }
}

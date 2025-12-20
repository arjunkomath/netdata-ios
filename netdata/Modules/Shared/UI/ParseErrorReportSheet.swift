//
//  ParseErrorReportSheet.swift
//  netdata
//
//  Created by Claude on 20/12/24.
//

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ParseErrorReportSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var serverService: ServerService

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Some servers couldn't be loaded due to data parsing errors. This may happen if the server returned an unexpected response format.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Failed Servers")) {
                    ForEach(serverService.serversWithErrors, id: \.id) { server in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.name)
                                .font(.headline)
                            Text(server.parseError ?? "Unknown error")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button(action: openGitHubIssue) {
                        HStack {
                            Image(systemName: "ant")
                            Text("Report on GitHub")
                        }
                    }
                }
            }
            .navigationTitle("Parse Errors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .imageScale(.medium)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func openGitHubIssue() {
        guard let url = serverService.generateErrorReportURL() else { return }

        #if os(iOS)
        UIApplication.shared.open(url)
        #else
        NSWorkspace.shared.open(url)
        #endif
    }
}

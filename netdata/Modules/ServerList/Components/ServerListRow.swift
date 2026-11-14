//
//  ServerListRow.swift
//  netdata
//
//  Created by Arjun Komath on 27/7/20.
//

import SwiftUI

struct ServerListRow: View {
    enum Presentation {
        case card(isSelected: Bool, onSelect: () -> Void)
        // Kept for iOS 16, where only List selection drives the collapsed split view.
        case listRow
    }

    @EnvironmentObject private var serverService: ServerService
    @ObservedObject var userSettings = UserSettings()
    
    var server: NDServer
    var presentation: Presentation = .listRow
    
    @State private var showEditServerSheet = false

    @ScaledMetric(relativeTo: .body) private var minimumCardHeight: CGFloat = 96

    private let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)
    
    var body: some View {
        content
        .task(id: [server.url, server.basicAuthBase64, String(serverService.statusGeneration)]) {
            await serverService.loadStatus(for: server)
        }
        .animation(.default, value: status?.fetchedAt)
        .sheet(isPresented: $showEditServerSheet, content: {
            EditServerForm(editingServer: server)
        })
        .contextMenu {
            editServerButton
            
            self.getFavouriteButtons()
            
            if let serverURL = URL(string: server.url) {
                Link(destination: serverURL, label: {
                    Label("Open in browser", systemImage: "safari")
                })
            }
            
            Button(role: .destructive, action: {
                ServerService.shared.requestDelete(server: server)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch presentation {
        case let .card(isSelected, onSelect):
            Button(action: onSelect) {
                card(isSelected: isSelected)
            }
            .buttonStyle(.plain)
            .contentShape(.contextMenuPreview, cardShape)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        case .listRow:
            NavigationLink(value: server.id) {
                listRow
            }
#if targetEnvironment(macCatalyst)
            .buttonStyle(.borderless)
#endif
        }
    }

    private func card(isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                RedactedView(loading: isCheckingStatus) {
                    HStack(spacing: 5) {
                        if isOffline() {
                            Image(systemName: "display.trianglebadge.exclamationmark")
                        } else {
                            Circle()
                                .fill(getAlarmStatusColor())
                                .frame(width: 8, height: 8)
                        }
                        Text(statusTitle)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isOffline() ? Color.red : Color.secondary)
                }

                Spacer(minLength: 4)

                if !server.basicAuthBase64.isEmpty {
                    Image(systemName: "lock.shield")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel("Basic authentication")
                }
            }

            Text(server.name)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(isOffline() ? Color.red : Color.primary)

            if !server.description.isEmpty {
                Text(server.description)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.leading)
        .padding(12)
        // maxHeight lets LazyVGrid stretch both cards in a row to the taller one.
        .frame(maxWidth: .infinity, minHeight: minimumCardHeight, maxHeight: .infinity, alignment: .topLeading)
        .background(cardShape.fill(Color(.secondarySystemGroupedBackground)))
        .overlay(cardShape.strokeBorder(Color.accentColor, lineWidth: isSelected ? 2 : 0))
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
    }

    private var listRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    if self.isOffline() {
                        Image(systemName: "display.trianglebadge.exclamationmark")
                            .foregroundColor(.red)
                    }

                    Text(server.name)
                        .lineLimit(2)
                        .font(.headline)
                        .foregroundColor(self.isOffline() ? .red : .primary)
                }

                Text(server.description)
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            if !server.basicAuthBase64.isEmpty {
                Image(systemName: "lock.shield")
                    .foregroundColor(.accentColor)
            }

            RedactedView(loading: isCheckingStatus) {
                Circle()
                    .fill(self.getAlarmStatusColor())
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
    }

    private var status: ServerStatus? {
        serverService.status(for: server)
    }

    private var isCheckingStatus: Bool {
        status == nil
    }

    private var statusTitle: String {
        guard let status else { return "Checking" }
        if !status.isOnline { return "Offline" }
        if status.hasCriticalAlarm { return "Critical" }
        if status.hasActiveAlarms { return "Warning" }
        return "Healthy"
    }
    
    private var editServerButton: some View {
        Button(action: {
            self.showEditServerSheet = true
        }) {
            Text("Edit")
            Image(systemName: "pencil")
        }
        .tint(.orange)
    }
    
    @ViewBuilder
    private func getFavouriteButtons() -> some View {
        if server.isFavourite == 1 {
            Button(action: {
                Task { await updateServer(favourite: false) }
            }) {
                Text("Unfavourite")
                Image(systemName: "star.slash")
            }
            .tint(.red)
        } else {
            Button(action: {
                Task { await updateServer(favourite: true) }
            }) {
                Text("Favourite")
                Image(systemName: "star.fill")
            }
            .tint(.accentColor)
        }
    }
    
    func updateServer(favourite: Bool) async {
        var updatedServer = NDServer(id: server.id,
                                     name: server.name,
                                     description: server.description,
                                     url: server.url,
                                     serverInfo: server.serverInfo,
                                     basicAuthBase64: server.basicAuthBase64,
                                     isFavourite: favourite ? 1 : 0)
        
        if let record = server.record {
            updatedServer.record = record
            
            ServerService.shared.edit(server: updatedServer)
            FeedbackGenerator.shared.triggerNotification(type: .success)
            
            await serverService.refresh()
        }
    }
    
    func isOffline() -> Bool {
        guard let status else { return false }
        return !status.isOnline
    }

    func getAlarmStatusColor() -> Color {
        guard let status, status.isOnline else { return .gray }
        if status.hasCriticalAlarm { return .red }
        return status.hasActiveAlarms ? .orange : .green
    }
}

struct ServerListRow_Previews: PreviewProvider {
    static var previews: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            ServerListRow(server: NDServer(name: "Techulus",
                                           description: "gc us server",
                                           url: "techulus.com",
                                           serverInfo: nil,
                                           basicAuthBase64: nil,
                                           isFavourite: 0),
                          presentation: .card(isSelected: true, onSelect: {}))

            ServerListRow(server: NDServer(name: "Techulus",
                                           description: "gc us server",
                                           url: "techulus.com",
                                           serverInfo: nil,
                                           basicAuthBase64: "base64==",
                                           isFavourite: 0),
                          presentation: .card(isSelected: false, onSelect: {}))
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .environmentObject(ServerService.shared)
    }
}

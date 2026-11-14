//
//  ServerListView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import UIKit
import CloudKit

struct ServerListView: View {
    @EnvironmentObject var serverService: ServerService
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    
    @ObservedObject var userSettings = UserSettings()
    
    @State private var showAddServer = false
    @State private var showWelcome = false
    @State private var showSettings = false
    @State private var selectedServerID: String?
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    // Backs iOS 17's preferredCompactColumn without exposing an iOS 17-only type as stored state.
    @State private var showsDetailWhenCollapsed = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var minimumCardWidth: CGFloat = 150

    private let gridSpacing: CGFloat = 12
    private let gridPadding: CGFloat = 16

    private var selectedServer: NDServer? {
        (serverService.favouriteServers + serverService.defaultServers)
            .first { $0.id == selectedServerID }
    }
    
    var body: some View {
        splitView
        .navigationSplitViewStyle(.balanced)
        .task {
            await serverService.refresh()
            
            // show welcome screen
            if !userSettings.HasLaunchedOnce {
                userSettings.HasLaunchedOnce = true
                showWelcome = true
            }
        }
        // Picks up an iCloud sign-in made in Settings while the app was in the background.
        .onChange(of: scenePhase) { phase in
            guard phase == .active, !serverService.isCloudEnabled else { return }
            Task { await serverService.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .CKAccountChanged)) { _ in
            Task { await serverService.refresh() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAddServer) {
            AddServerForm()
        }
        .sheet(isPresented: $showWelcome) {
            WelcomeScreen()
        }
        .confirmationDialog(
            "Delete Server",
            isPresented: $serverService.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await serverService.confirmDelete()
                    if selectedServer == nil {
                        selectedServerID = nil
                        showsDetailWhenCollapsed = false
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                serverService.cancelDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(serverService.serverToDelete?.name ?? "this server")'? This action cannot be undone.")
        }
    }

    @ViewBuilder
    private var splitView: some View {
        // Let the system align the columns with the fold's reserved region.
        if #available(iOS 17.0, *) {
            NavigationSplitView(
                columnVisibility: $columnVisibility,
                preferredCompactColumn: Binding(
                    get: { showsDetailWhenCollapsed ? .detail : .sidebar },
                    set: { showsDetailWhenCollapsed = $0 == .detail }
                )
            ) {
                serverGrid
            } detail: {
                detail
            }
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                serverList
            } detail: {
                detail
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let server = selectedServer {
            ServerDetailNavigationView(server: server)
                .id([server.id, server.url, server.basicAuthBase64])
        } else {
            VStack(spacing: 12) {
                Image(systemName: "server.rack")
                    .font(.largeTitle)
                Text("Select a server")
                    .font(.title2)
                Text("Choose a server to view its charts and alarms.")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding()
        }
    }

    private var serverGrid: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusMessages

                    if !serverService.favouriteServers.isEmpty {
                        serverSection(title: "Favourites",
                                      systemImage: "star.fill",
                                      servers: serverService.favouriteServers,
                                      width: geometry.size.width)
                    }

                    if !serverService.defaultServers.isEmpty {
                        serverSection(title: "All Servers",
                                      systemImage: "folder.fill",
                                      servers: serverService.defaultServers,
                                      width: geometry.size.width)
                    }
                }
                .padding(gridPadding)
            }
            .background(Color(.systemGroupedBackground))
        }
        .modifier(SidebarColumnBackground())
        .modifier(serverListChrome)
    }

    private var needsICloudSignIn: Bool {
        !serverService.isCloudEnabled
    }

    @ViewBuilder
    private var statusMessages: some View {
        if needsICloudSignIn {
            ICloudSignInPrompt(
                openSettings: {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settingsURL)
                    }
                },
                retry: { await serverService.refresh() }
            )
        } else if let error = serverService.mostRecentError {
            // While signed out CloudKit only reports a raw "authenticated account" error,
            // which the sign-in prompt above already explains.
            ErrorMessage(message: error.localizedDescription)
        }
    }

    private func serverSection(title: LocalizedStringKey,
                               systemImage: String,
                               servers: [NDServer],
                               width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: gridColumns(for: width), alignment: .leading, spacing: gridSpacing) {
                ForEach(servers) { server in
                    ServerListRow(
                        server: server,
                        presentation: .card(isSelected: isHighlighted(server)) {
                            selectedServerID = server.id
                            showsDetailWhenCollapsed = true
                        }
                    )
                }
            }
        }
    }

    // Columns are derived from the sidebar's actual width rather than the size class, because
    // the sidebar width varies with the fold state while the size class only flips at the extremes.
    private func gridColumns(for width: CGFloat) -> [GridItem] {
        let availableWidth = width - gridPadding * 2
        let fitsTwoColumns = availableWidth >= minimumCardWidth * 2 + gridSpacing
        let count = dynamicTypeSize.isAccessibilitySize || !fitsTwoColumns ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: gridSpacing, alignment: .top), count: count)
    }

    // When collapsed the detail is pushed over the grid, so a lingering highlight would only
    // show after popping back and would look like a stuck selection.
    private func isHighlighted(_ server: NDServer) -> Bool {
        horizontalSizeClass != .compact && server.id == selectedServerID
    }

    private var serverListChrome: ServerListChrome {
        ServerListChrome(
            isCloudEnabled: serverService.isCloudEnabled,
            isLoading: serverService.isCloudEnabled && serverService.isSynching
                && serverService.favouriteServers.isEmpty && serverService.defaultServers.isEmpty,
            showSettings: $showSettings,
            showAddServer: $showAddServer,
            refresh: { await serverService.refresh() }
        )
    }

    private var serverList: some View {
        List(selection: $selectedServerID) {
            statusMessages

            if !serverService.favouriteServers.isEmpty {
                Section {
                    ForEach(serverService.favouriteServers) { server in
                        ServerListRow(server: server)
                    }
                } header: {
                    Label("Favourites", systemImage: "star.fill")
                }
            }

            if !serverService.defaultServers.isEmpty {
                Section {
                    ForEach(serverService.defaultServers) { server in
                        ServerListRow(server: server)
                    }
                } header: {
                    Label("All Servers", systemImage: "folder.fill")
                }
            }
        }
        .listStyle(.sidebar)
        .modifier(serverListChrome)
    }

    func deleteServer(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        serverService.requestDelete(server: serverService.defaultServers[index])
    }

    func deleteFavouriteServer(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        serverService.requestDelete(server: serverService.favouriteServers[index])
    }
}

private struct ICloudSignInPrompt: View {
    let openSettings: () -> Void
    let retry: () async -> Void

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Sign in to iCloud to see your servers")
                    .font(.title3.weight(.semibold))

                Text("Netdata stores your servers in iCloud so they stay in sync across all your devices. Sign in with your Apple Account in Settings to view and add servers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button(action: openSettings) {
                    Text("Open Settings")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    Task {
                        isRetrying = true
                        await retry()
                        isRetrying = false
                    }
                } label: {
                    Group {
                        if isRetrying {
                            ProgressView()
                        } else {
                            Text("Try Again")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isRetrying)
            }

            Label {
                Text("Already signed in? If your servers don't appear, quit Netdata and open it again.")
            } icon: {
                Image(systemName: "info.circle")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .frame(maxWidth: .infinity)
    }
}

private struct ServerListChrome: ViewModifier {
    let isCloudEnabled: Bool
    let isLoading: Bool
    @Binding var showSettings: Bool
    @Binding var showAddServer: Bool
    let refresh: () async -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    ProgressView("Loading servers…")
                }
            }
            .refreshable {
                await refresh()
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gearshape")
                            Text("Settings")
                        }
                    }
                }

                if isCloudEnabled {
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: {
                            showAddServer = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("My Servers")
    }
}

// The split view's sidebar column has its own background, and on wide layouts part of it sits
// outside the grid. In dark mode that strip shows as a grey bar next to the black grid.
private struct SidebarColumnBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.containerBackground(Color(.systemGroupedBackground), for: .navigation)
        } else {
            content
        }
    }
}

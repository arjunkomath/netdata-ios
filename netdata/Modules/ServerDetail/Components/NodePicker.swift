//
//  NodePicker.swift
//  netdata
//

import SwiftUI

/// Discovers the nodes a Netdata Parent stores and remembers which one the user is viewing.
///
/// The choice is kept per device in UserDefaults rather than on `NDServer`: it is a viewing preference, not part
/// of the connection, and storing it in CloudKit would need a schema change and sync a choice made on one device
/// to all of them.
@MainActor final class NodeSelection: ObservableObject {
    @Published private(set) var nodes: [NetdataNode] = []
    @Published private(set) var parentGuid: String?
    /// Machine GUID of the selected Child; nil while viewing the Agent behind the server URL.
    @Published private(set) var selectedGuid: String?
    @Published private(set) var isLoading = false
    @Published private(set) var loadFailed = false

    private let server: NDServer
    private var storageKey: String { "selectedNode.\(server.id)" }

    init(server: NDServer) {
        self.server = server
        self.parentGuid = server.serverInfo?.uid
        self.selectedGuid = UserDefaults.standard.string(forKey: "selectedNode.\(server.id)")
    }

    var isParent: Bool { nodes.count > 1 }

    var parentNode: NetdataNode? {
        if let node = nodes.first(where: \.isLocalhost) {
            return node
        }
        // Agents that ignore `options=mcp` don't say which node they are, so match /api/v1/info's uid instead.
        if let parentGuid, let node = nodes.first(where: { $0.mg == parentGuid }) {
            return node
        }
        return nodes.first { $0.ni == 0 }
    }

    var childNodes: [NetdataNode] {
        let parent = parentNode?.mg
        return nodes.filter { $0.mg != parent }
    }

    /// The selected Child, or nil while viewing the Parent itself.
    var selectedNode: NetdataNode? {
        guard let selectedGuid else { return nil }
        return nodes.first { $0.mg == selectedGuid }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        async let nodesResult = fetchNodesRetrying()
        async let info = try? NetdataClient.shared.getInfo(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64)

        let (result, parentInfo) = await (nodesResult, info)
        guard !Task.isCancelled else { return }

        if let uid = parentInfo?.uid {
            parentGuid = uid
        }

        switch result {
        case .success(let nodes):
            loadFailed = false
            self.nodes = nodes
            // A Parent that no longer has the saved Child, or an Agent that stopped being a Parent.
            if let selectedGuid, !nodes.contains(where: { $0.mg == selectedGuid }) || selectedGuid == parentNode?.mg {
                select(nil)
            }
        case .failure(let error) where (error as? APIError) == .notFound:
            // Agents without /api/v3/nodes can only be viewed directly.
            loadFailed = false
            nodes = []
            select(nil)
        case .failure:
            // Keep any saved selection: the Parent may just be unreachable for now.
            loadFailed = true
        }
    }

    /// A missed node list hides the picker until the server is reopened, so transient failures get two more tries.
    private func fetchNodesRetrying() async -> Result<[NetdataNode], Error> {
        var result = await fetchNodes()
        for _ in 0..<2 {
            guard case .failure(let error) = result,
                  (error as? APIError) != .notFound,
                  !Task.isCancelled,
                  (try? await Task.sleep(for: .seconds(2))) != nil else { break }
            result = await fetchNodes()
        }
        return result
    }

    private func fetchNodes() async -> Result<[NetdataNode], Error> {
        do {
            return .success(try await NetdataClient.shared.getNodes(baseUrl: server.url, basicAuthBase64: server.basicAuthBase64))
        } catch {
            return .failure(error)
        }
    }

    func select(_ node: NetdataNode?) {
        let guid = node.flatMap { $0.mg == parentNode?.mg ? nil : $0.mg }
        guard guid != selectedGuid else { return }

        selectedGuid = guid
        if let guid {
            UserDefaults.standard.set(guid, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }
}

/// Hands the server list and the detail screen the same `NodeSelection` per server, so a node picked in
/// the sidebar switches the detail too.
@MainActor final class NodeSelectionStore: ObservableObject {
    private var selections: [String: NodeSelection] = [:]

    func selection(for server: NDServer) -> NodeSelection {
        // Editing the URL or credentials points at a different Agent, so it gets a fresh node list.
        let key = [server.id, server.url, server.basicAuthBase64].joined(separator: "|")
        if let selection = selections[key] {
            return selection
        }
        let selection = NodeSelection(server: server)
        selections[key] = selection
        return selection
    }
}

/// Title-bar control that names the node being viewed and opens the node list.
struct NodePickerButton: View {
    let serverName: String
    @ObservedObject var selection: NodeSelection
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text(selection.selectedNode?.nm ?? serverName)
                        .font(.headline)
                        .lineLimit(1)
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.footnote)
                        .symbolRenderingMode(.hierarchical)
                }
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .foregroundStyle(.primary)
        }
        .accessibilityLabel("Node: \(selection.selectedNode?.nm ?? serverName)")
        .accessibilityHint("Choose which node of this Parent to view")
    }

    private var subtitle: String {
        if selection.selectedNode != nil {
            return "via \(serverName)"
        }
        return "Parent · \(selection.nodes.count) nodes"
    }
}

struct NodePickerSheet: View {
    @ObservedObject var selection: NodeSelection
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if selection.loadFailed {
                    ErrorMessage(message: "Couldn't refresh the node list. Showing the last known nodes.")
                        .font(.subheadline)
                }

                if let parent = selection.parentNode, matches(parent) {
                    Section("Parent") {
                        row(parent, isSelected: selection.selectedGuid == nil)
                    }
                }

                let children = selection.childNodes.filter(matches)
                if !children.isEmpty {
                    Section {
                        ForEach(children) { node in
                            row(node, isSelected: selection.selectedGuid == node.mg)
                        }
                    } header: {
                        Text("Children")
                    } footer: {
                        Text("Children stream their metrics to this Parent. Stale nodes are no longer connected, so recent data may be missing.")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search nodes")
            .refreshable { await selection.load() }
            .overlay {
                if selection.nodes.isEmpty && selection.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Nodes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await selection.load() }
    }

    private func matches(_ node: NetdataNode) -> Bool {
        searchText.isEmpty || node.nm.localizedCaseInsensitiveContains(searchText)
    }

    private func row(_ node: NetdataNode, isSelected: Bool) -> some View {
        Button {
            selection.select(node)
            dismiss()
        } label: {
            NodeRow(node: node, isSelected: isSelected)
        }
        .foregroundStyle(.primary)
    }
}

struct NodeRow: View {
    let node: NetdataNode
    let isSelected: Bool
    /// Drops the OS and version so a row fits the narrow sidebar on one line.
    var compact = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(node.isReachable ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(node.nm)
                    .font(.body)
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if node.criticalAlerts > 0 {
                alertBadge(count: node.criticalAlerts, color: .red, label: "critical")
            }
            if node.warningAlerts > 0 {
                alertBadge(count: node.warningAlerts, color: .orange, label: "warning")
            }

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var details: String {
        var parts = [node.isReachable ? "Streaming" : "Stale"]
        if !compact, let os = node.os?.nm, !os.isEmpty {
            parts.append(os)
        }
        if let cpus = node.hw?.cpus, !cpus.isEmpty {
            parts.append("\(cpus) cores")
        }
        if !compact, let version = node.v, !version.isEmpty {
            parts.append(version)
        }
        return parts.joined(separator: " · ")
    }

    private func alertBadge(count: Int, color: Color, label: String) -> some View {
        Text("\(count)")
            .font(.caption.weight(.semibold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: Capsule())
            .accessibilityLabel("\(count) \(label)")
    }
}

/// Floats over the bottom of the server list on layouts that show it beside the detail, so the selected
/// Parent's nodes are a tap away without pushing the server cards around.
struct SidebarNodesPanel: View {
    let serverName: String
    @ObservedObject var selection: NodeSelection
    /// The tallest the expanded list may grow before it scrolls.
    let maxListHeight: CGFloat

    @State private var isExpanded = false
    @State private var listHeight: CGFloat = 0

    private let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

    var body: some View {
        if selection.isParent {
            VStack(spacing: 0) {
                if isExpanded {
                    nodeList
                    Divider()
                }
                summary
            }
            .background(shape.fill(.regularMaterial))
            .overlay(shape.strokeBorder(Color.primary.opacity(0.08)))
            .clipShape(shape)
            .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var summary: some View {
        Button {
            withAnimation(.snappy) { isExpanded.toggle() }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(activeNode?.isReachable == false ? Color.gray : Color.green)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(activeNode?.nm ?? serverName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text("\(serverName) · \(selection.nodes.count) nodes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Node: \(activeNode?.nm ?? serverName), \(selection.nodes.count) nodes")
        .accessibilityHint(isExpanded ? "Hides the node list" : "Shows this Parent's nodes")
    }

    private var nodeList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(orderedNodes.enumerated()), id: \.element.id) { index, node in
                    if index > 0 {
                        Divider().padding(.leading, 36)
                    }
                    Button {
                        // Stays open so you can flip between nodes; the header collapses it.
                        selection.select(node)
                    } label: {
                        NodeRow(node: node, isSelected: node.mg == activeNode?.mg, compact: true)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }

            }
            .background(GeometryReader { proxy in
                Color.clear.preference(key: NodeListHeightKey.self, value: proxy.size.height)
            })
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: min(listHeight, maxListHeight))
        .onPreferenceChange(NodeListHeightKey.self) { listHeight = $0 }
    }

    /// The node being viewed: the selected Child, or the Parent itself.
    private var activeNode: NetdataNode? {
        selection.selectedNode ?? selection.parentNode
    }

    private var orderedNodes: [NetdataNode] {
        [selection.parentNode].compactMap { $0 } + selection.childNodes
    }
}

private struct NodeListHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Shown above a Child's metrics when the Parent reports it as disconnected.
struct StaleNodeBanner: View {
    let nodeName: String
    let chooseNode: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("\(nodeName) isn't connected", systemImage: "antenna.radiowaves.left.and.right.slash")
                .font(.headline)
            Text("The Parent has stopped receiving metrics from this node, so live data may be missing until it streams again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Choose Another Node", action: chooseNode)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

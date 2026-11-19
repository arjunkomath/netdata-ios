//
//  ChartsListView.swift
//  netdata
//
//  Created by Arjun Komath on 1/8/20.
//

import SwiftUI

struct ChartsListView: View {
    var serverUrl: String
    var basicAuthBase64: String
    var node: String? = nil

    @Binding var searchText: String

    /// Nil until the first answer, so a failed refresh keeps showing the charts already loaded.
    @State private var catalog: ChartCatalog?
    @State private var isLoading = false
    @State private var fetchError: APIError?
    @State private var expandedSections: Set<String> = [pinnedSectionID, "system"]
    @StateObject private var userSettings = UserSettings()

    private static let pinnedSectionID = "pinned"

    var body: some View {
        let groups = catalog?.groups(matching: searchText) ?? []

        List {
            if let fetchError, catalog != nil {
                ErrorMessage(message: fetchError.listMessage(subject: "charts"))
            }

            if catalog == nil && fetchError == nil {
                placeholderSection
            }

            if isSearching {
                ForEach(groups) { group in
                    Section {
                        rows(group.charts)
                    } header: {
                        sectionHeader(group.title, count: group.charts.count)
                    }
                }
            } else {
                pinnedSection

                ForEach(groups) { group in
                    Section(isExpanded: expansion(for: group.id)) {
                        rows(group.charts)
                    } header: {
                        sectionHeader(group.title, count: group.charts.count)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollDismissesKeyboard(.immediately)
        .overlay {
            emptyState(isEmpty: groups.isEmpty)
        }
        // In the content rather than .searchable, because all server tabs share one navigation bar
        // and search only belongs to this tab.
        .safeAreaInset(edge: .top, spacing: 0) {
            if let catalog, !catalog.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ChartSearchField(text: $searchText)

                    if isSearching && !groups.isEmpty {
                        Text(resultCount(groups.reduce(0) { $0 + $1.charts.count }, of: catalog.count))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
        .refreshable {
            await fetchCharts()
        }
        .task {
            await fetchCharts()
        }
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Sections

    @ViewBuilder
    private var pinnedSection: some View {
        let pinned = userSettings.bookmarks.compactMap { catalog?.chart(withID: $0) }
        if !pinned.isEmpty {
            Section(isExpanded: expansion(for: Self.pinnedSectionID)) {
                rows(pinned)
            } header: {
                sectionHeader("Pinned", count: pinned.count)
            }
        }
    }

    private var placeholderSection: some View {
        Section {
            ForEach(0..<8, id: \.self) { _ in
                ChartListRow(chart: .placeholder)
            }
        } header: {
            sectionHeader("System", count: 0)
        }
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private func rows(_ charts: [ServerChart]) -> some View {
        ForEach(charts) { chart in
            ChartListRow(chart: chart,
                         isPinned: userSettings.bookmarks.contains(chart.id),
                         togglePin: { userSettings.togglePin(chart.id) })
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(count, format: .number)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(count) charts")
        }
    }

    private func expansion(for id: String) -> Binding<Bool> {
        Binding {
            expandedSections.contains(id)
        } set: { isExpanded in
            if isExpanded {
                expandedSections.insert(id)
            } else {
                expandedSections.remove(id)
            }
        }
    }

    @ViewBuilder
    private func emptyState(isEmpty: Bool) -> some View {
        if catalog == nil, let fetchError {
            ContentUnavailableView {
                Label("Couldn't Load Charts", systemImage: "exclamationmark.triangle")
            } description: {
                Text(fetchError.listMessage(subject: "charts"))
            } actions: {
                Button("Try Again") {
                    Task { await fetchCharts() }
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
        } else if let catalog, catalog.isEmpty {
            ContentUnavailableView("No Charts",
                                   systemImage: "chart.xyaxis.line",
                                   description: Text("This node isn't reporting any charts."))
        } else if catalog != nil, isSearching, isEmpty {
            ContentUnavailableView.search(text: searchText)
        }
    }

    private func resultCount(_ matches: Int, of total: Int) -> String {
        "\(matches.formatted()) of \(total.formatted()) charts"
    }

    // MARK: - Loading

    private func fetchCharts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let charts = try await NetdataClient.shared.getCharts(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, node: node)
            catalog = ChartCatalog(charts: charts.activeCharts)
            fetchError = nil
        } catch {
            guard !Task.isCancelled else { return }
            debugPrint("fetchCharts", error)
            fetchError = error as? APIError ?? .somethingWentWrong
        }
    }
}

/// The charts grouped for display, with the search text worked out once per load rather than on
/// every keystroke.
private struct ChartCatalog {
    struct ChartGroup: Identifiable {
        let id: String
        let title: String
        let charts: [ServerChart]
    }

    private struct Entry {
        let chart: ServerChart
        let searchText: String
    }

    private struct Category {
        let id: String
        let title: String
        let entries: [Entry]
    }

    private let categories: [Category]
    private let chartsByID: [String: ServerChart]
    let count: Int

    var isEmpty: Bool { count == 0 }

    init(charts: [ServerChart]) {
        chartsByID = Dictionary(charts.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        count = charts.count
        categories = Dictionary(grouping: charts, by: \.category)
            .sorted { ChartCategory.areInIncreasingOrder($0.key, $1.key) }
            .map { category, charts in
                let sorted = charts.sorted {
                    let order = $0.displayTitle.localizedStandardCompare($1.displayTitle)
                    return order == .orderedSame ? $0.id.localizedStandardCompare($1.id) == .orderedAscending : order == .orderedAscending
                }
                let entries = sorted.map { chart in
                    // Newlines keep a search term from matching across two fields.
                    Entry(chart: chart,
                          searchText: [chart.name, chart.title, chart.family, chart.context, chart.units]
                            .joined(separator: "\n")
                            .lowercased())
                }
                return Category(id: category, title: ChartCategory.title(for: category), entries: entries)
            }
    }

    func chart(withID id: String) -> ServerChart? {
        chartsByID[id]
    }

    /// Every word in the query has to match, so "cpu nginx" narrows to nginx's CPU charts.
    func groups(matching query: String) -> [ChartGroup] {
        let terms = query.lowercased().split(whereSeparator: \.isWhitespace)

        return categories.compactMap { category in
            let charts = category.entries
                .filter { entry in terms.allSatisfy { entry.searchText.contains($0) } }
                .map(\.chart)
            return charts.isEmpty ? nil : ChartGroup(id: category.id, title: category.title, charts: charts)
        }
    }
}

private struct ChartSearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Search charts", text: $text)
                .focused($isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }
}

#Preview {
    ChartsListView(serverUrl: "", basicAuthBase64: "", searchText: .constant(""))
}

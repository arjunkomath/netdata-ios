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
    @Binding var searchText: String
    @StateObject private var userSettings = UserSettings()
    
    var body: some View {
        let visibleCharts = filteredCharts

        List {
            if loading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            } else if visibleCharts.isEmpty && !searchText.isEmpty {
                Text("No charts match “\(searchText)”")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowSeparator(.hidden)
            }

            ForEach(visibleCharts) { chart in
                ChartListRow(chart: chart,
                             isPinned: userSettings.bookmarks.contains(chart.id),
                             togglePin: { userSettings.togglePin(chart.id) })
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.immediately)
        // In the content rather than .searchable, because all server tabs share one navigation bar
        // and search only belongs to this tab.
        .safeAreaInset(edge: .top, spacing: 0) {
            ChartSearchField(text: $searchText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
        }
        .task {
            await fetchCharts()
        }
    }
    
    private func fetchCharts() async {
        loading = true
        defer { loading = false }
        do {
            charts = try await NetdataClient.shared.getCharts(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64)
        } catch {
            debugPrint("fetchCharts", error)
        }
    }
    
    /// Every word in the query has to match one of the chart's fields, so "cpu nginx" narrows to nginx's CPU charts.
    private var filteredCharts: [ServerChart] {
        let terms = searchText.lowercased().split(whereSeparator: \.isWhitespace)
        guard !terms.isEmpty else { return charts.activeCharts }

        return charts.activeCharts.filter { chart in
            let fields = [chart.name, chart.title, chart.family, chart.context, chart.units].map { $0.lowercased() }
            return terms.allSatisfy { term in fields.contains { $0.contains(term) } }
        }
    }
    
    private var dismissButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .imageScale(.medium)
        }
    }
}

struct ChartsListView_Previews: PreviewProvider {
    static var previews: some View {
        ChartsListView(serverUrl: "", basicAuthBase64: "", searchText: .constant(""))
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

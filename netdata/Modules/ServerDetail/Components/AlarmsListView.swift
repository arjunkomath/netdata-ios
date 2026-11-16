//
//  AlarmsListView.swift
//  netdata
//
//  Created by Arjun Komath on 29/7/20.
//

import SwiftUI

/// Alarms for one server, or the selected Child on a Parent. Owned by the detail screen rather than the
/// Alarms tab so the tab's badge is right before the tab is first opened.
@MainActor final class AlarmsStore: ObservableObject {
    @Published private(set) var alarms: ServerAlarms?
    @Published private(set) var lastError: APIError?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isLoading = false

    private let serverUrl: String
    private let basicAuthBase64: String
    private var node: String?
    private var loadTask: Task<Void, Never>?

    init(serverUrl: String, basicAuthBase64: String) {
        self.serverUrl = serverUrl
        self.basicAuthBase64 = basicAuthBase64
    }

    /// Fetches in a task this object owns, like `NodeSelection.refresh()`, so a view's cancelled `.task`
    /// can't drop the result. Calls while a fetch for the same node is running join it.
    func refresh(node: String?) {
        if node != self.node {
            // The old node's alarms would show under the new node's name. Drop them; a load still
            // running for the old node finishes without publishing.
            self.node = node
            alarms = nil
            lastError = nil
            lastUpdated = nil
            loadTask = nil
        }
        guard loadTask == nil else { return }
        loadTask = Task { await load(node: node) }
    }

    func refreshAndWait(node: String?) async {
        refresh(node: node)
        await loadTask?.value
    }

    func criticalCount(ignoring ignored: [String]) -> Int {
        guard let alarms = alarms?.alarms else { return 0 }
        return alarms.values.filter { $0.isCritical && !ignored.contains($0.name ?? "") }.count
    }

    private func load(node: String?) async {
        isLoading = true
        do {
            let result = try await NetdataClient.shared.getAlarms(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, node: node)
            guard node == self.node else { return }
            alarms = result
            lastError = nil
            lastUpdated = Date()
        } catch {
            guard node == self.node else { return }
            debugPrint("getAlarms", error)
            lastError = error as? APIError ?? .somethingWentWrong
        }
        isLoading = false
        loadTask = nil
    }
}

struct AlarmsListView: View {
    @ObservedObject var store: AlarmsStore
    @ObservedObject var userSettings: UserSettings

    var serverUrl: String
    var basicAuthBase64: String
    var node: String? = nil

    /// Real chart metadata for the alarms' charts, so an opened chart gets its proper title and units.
    @State private var charts: [String: ServerChart] = [:]
    @State private var showsHidden = false

    private let refreshInterval: Duration = .seconds(15)

    private struct Entry: Identifiable {
        let id: String
        let alarm: ServerAlarm
    }

    var body: some View {
        let entries = visibleEntries

        List {
            statusSection(entries: entries)

            alarmSection("Critical", entries: entries.filter { $0.alarm.isCritical })
            alarmSection("Warning", entries: entries.filter { $0.alarm.isWarning })
            alarmSection("Other", entries: entries.filter { !$0.alarm.isCritical && !$0.alarm.isWarning })

            hiddenSection
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await store.refreshAndWait(node: node)
        }
        .task {
            // Polls only while the tab is on screen; the detail screen refreshes once for the badge.
            while !Task.isCancelled {
                store.refresh(node: node)
                try? await Task.sleep(for: refreshInterval)
            }
        }
        .task(id: store.alarms?.alarms?.isEmpty == false) {
            await loadCharts()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func statusSection(entries: [Entry]) -> some View {
        if let lastError = store.lastError {
            ErrorMessage(message: lastError.listMessage(subject: "alarms"))
        }

        if store.alarms == nil {
            if store.isLoading {
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        AlarmListRow(alarm: .placeholder)
                    }
                }
                .redacted(reason: .placeholder)
            }
        } else if store.alarms?.status == false {
            Text("Health monitoring isn't running for this node, so there are no alarms to show.")
                .foregroundStyle(.secondary)
        } else {
            Section {
                summaryRow(entries: entries)
            }
        }
    }

    private func summaryRow(entries: [Entry]) -> some View {
        let critical = entries.filter { $0.alarm.isCritical }.count
        let warning = entries.filter { $0.alarm.isWarning }.count
        let other = entries.count - critical - warning

        return HStack(spacing: 12) {
            Image(systemName: entries.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(critical > 0 ? Color.red : entries.isEmpty ? Color.green : Color.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(entries.isEmpty ? "No active alarms" : summaryText(critical: critical, warning: warning, other: other))
                    .font(.headline)
                if let lastUpdated = store.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func summaryText(critical: Int, warning: Int, other: Int) -> String {
        [(critical, "critical"), (warning, "warning"), (other, "other")]
            .filter { $0.0 > 0 }
            .map { "\($0.0) \($0.1)" }
            .joined(separator: " · ")
    }

    @ViewBuilder
    private func alarmSection(_ title: String, entries: [Entry]) -> some View {
        if !entries.isEmpty {
            Section(title) {
                ForEach(entries) { entry in
                    alarmRow(entry.alarm)
                }
            }
        }
    }

    @ViewBuilder
    private func alarmRow(_ alarm: ServerAlarm) -> some View {
        Group {
            if let chart = chart(for: alarm) {
                NavigationLink(value: chart) {
                    AlarmListRow(alarm: alarm)
                }
            } else {
                AlarmListRow(alarm: alarm)
            }
        }
        .swipeActions(edge: .trailing) {
            Button {
                hide(alarm)
            } label: {
                Label("Hide", systemImage: "eye.slash")
            }
            .tint(.gray)
        }
        .contextMenu {
            Button {
                hide(alarm)
            } label: {
                Label("Hide Alarm", systemImage: "eye.slash")
            }
        }
    }

    @ViewBuilder
    private var hiddenSection: some View {
        let hidden = hiddenEntries
        if !hidden.isEmpty {
            Section {
                DisclosureGroup(isExpanded: $showsHidden) {
                    ForEach(hidden) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.alarm.title)
                                    .lineLimit(2)
                                if let name = entry.alarm.name {
                                    Text(name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Unhide") { unhide(entry.alarm) }
                                .buttonStyle(.borderless)
                        }
                    }
                } label: {
                    Text("\(hidden.count) hidden")
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Hiding an alarm hides every alarm with the same name, on all your servers and devices.")
            }
        }
    }

    // MARK: - Data

    private var visibleEntries: [Entry] {
        sortedEntries.filter { !isHidden($0.alarm) }
    }

    private var hiddenEntries: [Entry] {
        sortedEntries.filter { isHidden($0.alarm) }
    }

    /// Most recent status change first, so a just-raised alarm sits at the top of its section. Alarms
    /// often change together (same timestamp), so the key breaks ties; otherwise dictionary order would
    /// reshuffle the rows on every refresh.
    private var sortedEntries: [Entry] {
        (store.alarms?.alarms ?? [:])
            .map { Entry(id: $0.key, alarm: $0.value) }
            .sorted {
                let lhs = $0.alarm.last_status_change ?? 0
                let rhs = $1.alarm.last_status_change ?? 0
                return lhs != rhs ? lhs > rhs : $0.id < $1.id
            }
    }

    private func isHidden(_ alarm: ServerAlarm) -> Bool {
        guard let name = alarm.name else { return false }
        return userSettings.ignoredAlarms.contains(name)
    }

    private func hide(_ alarm: ServerAlarm) {
        guard let name = alarm.name, !userSettings.ignoredAlarms.contains(name) else { return }
        withAnimation {
            userSettings.ignoredAlarms.append(name)
        }
    }

    private func unhide(_ alarm: ServerAlarm) {
        guard let name = alarm.name else { return }
        withAnimation {
            userSettings.ignoredAlarms.removeAll { $0 == name }
        }
    }

    private func chart(for alarm: ServerAlarm) -> ServerChart? {
        guard let id = alarm.chart, !id.isEmpty else { return nil }
        if let chart = charts[id] {
            return chart
        }
        // Until the chart list arrives (or if it fails), the id alone is enough to load the chart's data.
        return ServerChart(id: id,
                           name: id,
                           type: id.split(separator: ".").first.map(String.init) ?? id,
                           family: "",
                           context: "",
                           title: id,
                           units: alarm.units ?? "")
    }

    private func loadCharts() async {
        guard charts.isEmpty, store.alarms?.alarms?.isEmpty == false else { return }
        if let result = try? await NetdataClient.shared.getCharts(baseUrl: serverUrl, basicAuthBase64: basicAuthBase64, node: node) {
            charts = result.charts
        }
    }
}

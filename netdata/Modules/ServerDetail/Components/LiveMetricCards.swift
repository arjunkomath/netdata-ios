//
//  LiveMetricCards.swift
//  netdata
//

import SwiftUI

// MARK: - Data helpers

struct MetricDimension: Identifiable {
    let label: String
    let value: Double
    // Position in the chart's original dimension order, kept so colours stay stable
    // while the dimensions are re-sorted by value on every refresh.
    let index: Int

    var id: String { label }
}

extension ServerData {
    /// Latest value of every dimension, skipping the leading `time` column.
    var latestDimensions: [MetricDimension] {
        guard let row = data.first, labels.count > 1 else { return [] }
        return labels.indices.dropFirst().compactMap { i in
            guard row.indices.contains(i) else { return nil }
            return MetricDimension(label: labels[i], value: row[i] ?? 0, index: i - 1)
        }
    }

    func latestValue(_ label: String) -> Double? {
        latestDimensions.first { $0.label == label }?.value
    }

    var isLoaded: Bool { labels.count > 1 && !data.isEmpty }
}

enum MetricFormat {
    static func percent(_ value: Double) -> String {
        value > 0 && value < 1 ? "<1%" : String(format: "%.0f%%", value)
    }

    static func mebibytes(_ value: Double) -> String {
        value >= 1024 ? String(format: "%.1f GiB", value / 1024) : String(format: "%.0f MiB", value)
    }

    static func kibPerSecond(_ value: Double) -> String {
        let value = abs(value)
        if value >= 1024 * 1024 { return String(format: "%.1f GiB/s", value / 1024 / 1024) }
        if value >= 1024 { return String(format: "%.1f MiB/s", value / 1024) }
        return String(format: "%.0f KiB/s", value)
    }

    static func kilobitsPerSecond(_ value: Double) -> String {
        let value = abs(value)
        if value >= 1_000_000 { return String(format: "%.1f Gb/s", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1f Mb/s", value / 1_000) }
        return String(format: "%.0f kb/s", value)
    }

    static func usageColor(_ percent: Double) -> Color {
        if percent >= 80 { return .red }
        if percent >= 50 { return .orange }
        return .green
    }
}

private let dimensionPalette: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .yellow, .indigo, .mint, .brown]

private func dimensionColor(_ dimension: MetricDimension) -> Color {
    dimensionPalette[dimension.index % dimensionPalette.count]
}

// Fixed colours so "used" never reads as a green, healthy value.
private func memoryColor(_ dimension: MetricDimension) -> Color {
    switch dimension.label {
    case "free": return Color(.tertiarySystemFill)
    case "used": return .blue
    case "cached": return .teal
    case "buffers": return .purple
    default: return dimensionColor(dimension)
    }
}

// MARK: - Building blocks

struct MetricCard<Content: View, Accessory: View>: View {
    let title: String
    @ViewBuilder var accessory: () -> Accessory
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                Spacer(minLength: 8)
                accessory()
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

extension MetricCard where Accessory == EmptyView {
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, accessory: { EmptyView() }, content: content)
    }
}

struct StackedUsageBar: View {
    let segments: [(value: Double, color: Color)]
    let total: Double

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: total > 0 ? geometry.size.width * min(max(segment.value, 0) / total, 1) : 0)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 10)
        .background(Color(.tertiarySystemFill))
        .clipShape(Capsule())
        .animation(.easeOut(duration: 0.3), value: segments.map { $0.value })
        .accessibilityHidden(true)
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
        }
        .font(.footnote)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}

private struct LabeledValue: View {
    let label: String
    let value: String
    var dotColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)
                }
                Text(label)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Summary

struct MetricSummaryTile: View {
    let title: String
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Cards

struct CPUUsageCard: View {
    let data: ServerData
    let cores: String?

    @State private var showsAllDimensions = false

    private var dimensions: [MetricDimension] {
        data.latestDimensions.sorted { $0.value > $1.value }
    }

    // Anything that rounds to 0% is noise on most servers (guest, steal, irq…).
    private var activeDimensions: [MetricDimension] {
        dimensions.filter { $0.value >= 0.5 }
    }

    var body: some View {
        MetricCard(title: "CPU") {
            if let cores, !cores.isEmpty {
                Text("\(cores) cores")
            }
        } content: {
            StackedUsageBar(segments: activeDimensions.map { ($0.value, dimensionColor($0)) }, total: 100)

            let visible = showsAllDimensions ? dimensions : activeDimensions
            let hiddenCount = dimensions.count - activeDimensions.count

            FlowingLegend {
                if visible.isEmpty {
                    LegendItem(color: .secondary, label: "idle", value: "100%")
                }
                ForEach(visible) { dimension in
                    LegendItem(color: dimensionColor(dimension),
                               label: dimension.label,
                               value: MetricFormat.percent(dimension.value))
                }
            }

            if hiddenCount > 0 {
                Button(showsAllDimensions ? "Show less" : "Show \(hiddenCount) more") {
                    withAnimation(.easeOut(duration: 0.2)) { showsAllDimensions.toggle() }
                }
                .font(.footnote)
            }
        }
    }
}

struct MemoryUsageCard: View {
    let data: ServerData

    private var dimensions: [MetricDimension] { data.latestDimensions }
    private var total: Double { dimensions.reduce(0) { $0 + max($1.value, 0) } }
    private var used: Double { data.latestValue("used") ?? 0 }

    var body: some View {
        MetricCard(title: "Memory") {
            if total > 0 {
                Text("\(MetricFormat.mebibytes(used)) of \(MetricFormat.mebibytes(total))")
                    .monospacedDigit()
            }
        } content: {
            // "free" is the unfilled remainder of the bar rather than its own segment.
            StackedUsageBar(
                segments: dimensions
                    .filter { $0.label != "free" }
                    .map { ($0.value, memoryColor($0)) },
                total: total
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), alignment: .leading)], alignment: .leading, spacing: 8) {
                ForEach(dimensions) { dimension in
                    LabeledValue(label: dimension.label,
                                 value: MetricFormat.mebibytes(dimension.value),
                                 dotColor: memoryColor(dimension))
                }
            }
        }
    }
}

struct LoadAverageCard: View {
    let data: ServerData

    var body: some View {
        MetricCard(title: "Load") {
            HStack(spacing: 8) {
                ForEach(data.latestDimensions) { dimension in
                    LabeledValue(label: Self.displayLabel(dimension.label),
                                 value: String(format: "%.2f", dimension.value))
                }
            }
        }
    }

    // Netdata names these load1 / load5 / load15.
    static func displayLabel(_ label: String) -> String {
        guard label.hasPrefix("load"), let minutes = Int(label.dropFirst(4)) else { return label }
        return "\(minutes)m"
    }
}

struct ThroughputCard: View {
    let title: String
    let data: ServerData
    let format: (Double) -> String

    var body: some View {
        MetricCard(title: title) {
            // Half-width cards can't fit "received 642 kb/s"; the arrow alone still says which way.
            // Decided per card so every row in it drops its label together.
            ViewThatFits(in: .horizontal) {
                rows(showsLabels: true)
                rows(showsLabels: false)
            }
        }
    }

    private func rows(showsLabels: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(data.latestDimensions) { dimension in
                row(dimension, showsLabel: showsLabels)
                    .font(.subheadline)
                    .lineLimit(1)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(dimension.label) \(format(dimension.value))")
            }
        }
    }

    private func row(_ dimension: MetricDimension, showsLabel: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: Self.isOutbound(dimension) ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(Self.isOutbound(dimension) ? Color.blue : Color.green)
            if showsLabel {
                Text(dimension.label)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            Spacer(minLength: 4)
            Text(format(dimension.value))
                .monospacedDigit()
                .fixedSize()
        }
    }

    // Netdata reports outbound traffic (sent / out) as negative values.
    private static func isOutbound(_ dimension: MetricDimension) -> Bool {
        dimension.value < 0 || ["sent", "out", "writes"].contains(dimension.label)
    }
}

// MARK: - Layout

/// Lays out legend items left to right, wrapping onto new lines as needed.
struct FlowingLegend: Layout {
    var spacing: CGFloat = 12
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews: subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if proposedWidth > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

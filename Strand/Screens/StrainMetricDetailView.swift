import SwiftUI
import StrandDesign
import WhoopStore

struct StrainMetricDetailView: View {
    let title: String

    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profile = ProfileStore()
    @State private var range: MetricDetailRange = .month
    @State private var points: [TrendPoint] = []

    private var metric: StrainMetricConfig { .init(title: title) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    rangeSelector
                    chartSection
                    summarySection
                }
                .padding(20)
            }
            .background(StrainTheme.background.ignoresSafeArea())
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task(id: loadKey) { await load() }
    }

    private var loadKey: String { "\(title)-\(range.rawValue)-\(repo.refreshSeq)-\(profile.age)" }

    private var hero: some View {
        StrainSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text(metric.overline).strandOverline()
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(latestText)
                        .font(StrandFont.number(28))
                        .foregroundStyle(.white)
                    if !metric.unit.isEmpty, latestText != "--" {
                        Text(metric.unit)
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrainTheme.textSecondary)
                    }
                }
                Text(metric.description)
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrainTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var rangeSelector: some View {
        HStack(spacing: 4) {
            ForEach(MetricDetailRange.allCases) { item in
                Button {
                    range = item
                } label: {
                    Text(item.label)
                        .font(StrandFont.captionNumber)
                        .foregroundStyle(range == item ? StrainTheme.background : StrainTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(range == item ? StrainTheme.orange : .clear,
                                    in: Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(StrainTheme.surface, in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(StrainTheme.border, lineWidth: 1))
    }

    @ViewBuilder private var chartSection: some View {
        if points.count > 1 {
            let values = points.map(\.value)
            ChartCard(
                title: LocalizedStringKey(metric.chartTitle),
                subtitle: "\(range.days)-day view",
                trailing: latestText == "--" ? nil : latestText,
                tint: metric.color
            ) {
                TrendChart(
                    points: points,
                    gradient: Gradient(colors: [metric.color.opacity(0.35), metric.color]),
                    valueRange: MetricTrendDetailSupport.valueRange(for: values, fallback: metric.fallbackRange),
                    showsArea: true,
                    height: NoopMetrics.chartHeight,
                    valueFormat: metric.valueFormat,
                    dateFormat: { MetricTrendDetailSupport.dateFormatter.string(from: $0) },
                    accessibilityLabel: metric.chartTitle
                )
            } footer: {
                ChartFooter([
                    ("Latest", latestText),
                    ("Average", averageText(values)),
                    ("Range", rangeText(values)),
                ])
            }
        } else {
            StrainSurface {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(StrainTheme.orange)
                    Text("No data yet")
                        .font(StrandFont.title2)
                        .foregroundStyle(.white)
                    Text(metric.emptyMessage)
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrainTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
            }
        }
    }

    private var summarySection: some View {
        StrainSurface {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: metric.icon)
                    .foregroundStyle(metric.color)
                VStack(alignment: .leading, spacing: 5) {
                    Text("How NOOP uses it")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Text(metric.usageNote)
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrainTheme.textSecondary)
                }
            }
        }
    }

    private func load() async {
        switch metric.mode {
        case .series(let key):
            let series = await repo.exploreSeries(key: key, source: "my-whoop")
            let allPoints = series.compactMap { row -> TrendPoint? in
                guard let date = MetricTrendDetailSupport.dayParser.date(from: row.day) else { return nil }
                return TrendPoint(date: date, value: row.value)
            }
            points = MetricTrendDetailSupport.filteredWindow(allPoints, range: range)
        case .dailyWorkoutDuration:
            let rows = await repo.workoutRows(days: max(range.days, 365))
            points = MetricTrendDetailSupport.filteredWindow(groupWorkoutRows(rows) { row in
                (row.durationS ?? Double(max(row.endTs - row.startTs, 0))) / 60.0
            }, range: range)
        case .dailyZoneMinutes:
            let rows = await repo.workoutRows(days: max(range.days, 365))
            var totals: [String: Double] = [:]
            let formatter = MetricTrendDetailSupport.dayParser
            for row in rows {
                let minutes: Double?
                if let pct = WorkoutZones.percents(row.zonesJSON) {
                    let durationMin = (row.durationS ?? Double(max(row.endTs - row.startTs, 0))) / 60.0
                    minutes = durationMin > 0 ? pct.enumerated().reduce(0) { $0 + durationMin * $1.element / 100.0 } : nil
                } else if let derived = await repo.workoutZoneMinutes(from: row.startTs, to: row.endTs, age: profile.age) {
                    minutes = derived.reduce(0, +)
                } else {
                    minutes = nil
                }
                guard let minutes, minutes > 0 else { continue }
                let day = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(row.startTs)))
                totals[day, default: 0] += minutes
            }
            let allPoints = totals.compactMap { day, value -> TrendPoint? in
                guard let date = formatter.date(from: day) else { return nil }
                return TrendPoint(date: date, value: value)
            }.sorted { $0.date < $1.date }
            points = MetricTrendDetailSupport.filteredWindow(allPoints, range: range)
        }
    }

    private func groupWorkoutRows(_ rows: [WorkoutRow], value: (WorkoutRow) -> Double) -> [TrendPoint] {
        let formatter = MetricTrendDetailSupport.dayParser
        var totals: [String: Double] = [:]
        for row in rows {
            let day = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(row.startTs)))
            totals[day, default: 0] += value(row)
        }
        return totals.compactMap { day, total -> TrendPoint? in
            guard let date = formatter.date(from: day) else { return nil }
            return TrendPoint(date: date, value: total)
        }.sorted { $0.date < $1.date }
    }

    private var latestText: String {
        points.last.map { metric.valueFormat($0.value) } ?? "--"
    }

    private func averageText(_ values: [Double]) -> String {
        guard !values.isEmpty else { return "--" }
        return metric.valueFormat(values.reduce(0, +) / Double(values.count))
    }

    private func rangeText(_ values: [Double]) -> String {
        guard let min = values.min(), let max = values.max() else { return "--" }
        return "\(metric.valueFormat(min)) - \(metric.valueFormat(max))"
    }
}

private enum StrainMetricMode {
    case series(String)
    case dailyWorkoutDuration
    case dailyZoneMinutes
}

private struct StrainMetricConfig {
    let mode: StrainMetricMode
    let unit: String
    let color: Color
    let icon: String
    let overline: LocalizedStringKey
    let chartTitle: String
    let description: String
    let usageNote: String
    let emptyMessage: String
    let fallbackRange: ClosedRange<Double>
    let valueFormat: (Double) -> String

    init(title: String) {
        switch title.lowercased() {
        case "strain score":
            mode = .series("strain")
            unit = ""
            color = StrainTheme.orange
            icon = "flame.fill"
            overline = "EFFORT"
            chartTitle = "Effort trend"
            description = "Daily NOOP Effort over recent days."
            usageNote = "Effort is NOOP's cardiovascular load score derived from time spent across heart-rate intensity zones."
            emptyMessage = "No Effort history has been scored for this range yet."
            fallbackRange = 0...100
            valueFormat = { String(format: "%.1f", $0) }
        case "duration":
            mode = .dailyWorkoutDuration
            unit = "min"
            color = StrandPalette.metricCyan
            icon = "timer"
            overline = "DURATION"
            chartTitle = "Workout duration trend"
            description = "Total workout time banked each day."
            usageNote = "This reuses your recorded workout rows and sums active duration per day."
            emptyMessage = "No workout duration has been recorded in this range yet."
            fallbackRange = 0...120
            valueFormat = { String(Int($0.rounded())) }
        case "total energy":
            mode = .series("active_kcal")
            unit = "kcal"
            color = StrandPalette.metricAmber
            icon = "bolt.fill"
            overline = "ENERGY"
            chartTitle = "Active-energy trend"
            description = "Daily active energy from NOOP's merged metrics."
            usageNote = "Total energy reuses the same daily active-kcal source shown on Today and Strain."
            emptyMessage = "No activity energy has been banked for this range yet."
            fallbackRange = 0...1500
            valueFormat = { String(Int($0.rounded())) }
        case "steps":
            mode = .series("steps")
            unit = "steps"
            color = StrandPalette.metricPurple
            icon = "figure.walk"
            overline = "STEPS"
            chartTitle = "Steps trend"
            description = "Daily steps from merged device and imported sources."
            usageNote = "This uses the same daily steps metric surfaced throughout NOOP."
            emptyMessage = "No step counts have been banked in this range yet."
            fallbackRange = 0...12000
            valueFormat = { String(Int($0.rounded())) }
        default:
            mode = .dailyZoneMinutes
            unit = "min"
            color = StrandPalette.metricRose
            icon = "heart.text.square.fill"
            overline = "HR ZONES"
            chartTitle = "Zone-time trend"
            description = "Total time spent in heart-rate zones from your workouts."
            usageNote = "This aggregates per-workout zone splits from imported zone data or NOOP's strap-derived zone minutes when available."
            emptyMessage = "No workout heart-rate zone data exists in this range yet."
            fallbackRange = 0...120
            valueFormat = { String(Int($0.rounded())) }
        }
    }
}

private enum MetricDetailRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case quarter = "3M"
    case half = "6M"
    case year = "1Y"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .half: return 180
        case .year: return 365
        }
    }

    var label: String { rawValue }
}

private enum MetricTrendDetailSupport {
    static let dayParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func filteredWindow(_ points: [TrendPoint], range: MetricDetailRange, now: Date = Date()) -> [TrendPoint] {
        guard let start = Calendar.current.date(byAdding: .day, value: -(range.days - 1), to: now) else {
            return points
        }
        return points.filter { $0.date >= Calendar.current.startOfDay(for: start) }
    }

    static func valueRange(for values: [Double], fallback: ClosedRange<Double>, pad: Double = 0.12) -> ClosedRange<Double> {
        guard let min = values.min(), let max = values.max() else { return fallback }
        guard max > min else { return (min - 1)...(max + 1) }
        let padding = (max - min) * pad
        return (min - padding)...(max + padding)
    }
}

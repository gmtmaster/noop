import SwiftUI
import StrandDesign
import WhoopStore

struct SleepMetricDetailView: View {
    let title: String

    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss
    @State private var range: MetricDetailRange = .month
    @State private var points: [TrendPoint] = []

    private var metric: SleepMetricConfig { .init(title: title) }

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
            .background(SleepTheme.background.ignoresSafeArea())
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

    private var loadKey: String { "\(title)-\(range.rawValue)-\(repo.refreshSeq)" }

    private var hero: some View {
        SleepSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text(metric.overline).strandOverline()
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(latestText)
                        .font(StrandFont.number(28))
                        .foregroundStyle(.white)
                    if !metric.unit.isEmpty, latestText != "--" {
                        Text(metric.unit)
                            .font(StrandFont.footnote)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                }
                Text(metric.description)
                    .font(StrandFont.subhead)
                    .foregroundStyle(SleepTheme.textSecondary)
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
                        .foregroundStyle(range == item ? .white : SleepTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(range == item ? SleepTheme.violet : .clear,
                                    in: Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(SleepTheme.surface, in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(SleepTheme.border, lineWidth: 1))
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
            SleepSurface {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(SleepTheme.purple)
                    Text("No data yet")
                        .font(StrandFont.title2)
                        .foregroundStyle(.white)
                    Text(metric.emptyMessage)
                        .font(StrandFont.subhead)
                        .foregroundStyle(SleepTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
            }
        }
    }

    private var summarySection: some View {
        SleepSurface {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: metric.icon)
                    .foregroundStyle(metric.color)
                VStack(alignment: .leading, spacing: 5) {
                    Text("How NOOP uses it")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Text(metric.usageNote)
                        .font(StrandFont.subhead)
                        .foregroundStyle(SleepTheme.textSecondary)
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
        case .daily(let extractor):
            let allPoints = repo.days.compactMap { day -> TrendPoint? in
                guard let value = extractor(day),
                      let date = MetricTrendDetailSupport.dayParser.date(from: day.day) else { return nil }
                return TrendPoint(date: date, value: value)
            }
            points = MetricTrendDetailSupport.filteredWindow(allPoints, range: range)
        case .imported(let extractor):
            let allPoints = repo.importedSleep.compactMap { day, figures -> TrendPoint? in
                guard let value = extractor(figures),
                      let date = MetricTrendDetailSupport.dayParser.date(from: day) else { return nil }
                return TrendPoint(date: date, value: value)
            }.sorted { $0.date < $1.date }
            points = MetricTrendDetailSupport.filteredWindow(allPoints, range: range)
        }
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

private enum SleepMetricMode {
    case series(String)
    case daily((DailyMetric) -> Double?)
    case imported((ImportedSleepFigures) -> Double?)
}

private struct SleepMetricConfig {
    let mode: SleepMetricMode
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
        case "rest":
            mode = .series("sleep_performance")
            unit = "%"
            color = SleepTheme.purple
            icon = "moon.stars.fill"
            overline = "REST"
            chartTitle = "Rest trend"
            description = "NOOP's Rest score across recent nights."
            usageNote = "Rest is NOOP's own sleep score, persisted as sleep_performance and reused by Charge."
            emptyMessage = "Wear your strap overnight or import history to build Rest."
            fallbackRange = 0...100
            valueFormat = { String(Int($0.rounded())) }
        case "sleep efficiency":
            mode = .series("sleep_efficiency")
            unit = "%"
            color = StrandPalette.metricCyan
            icon = "gauge.with.dots.needle.67percent"
            overline = "EFFICIENCY"
            chartTitle = "Sleep-efficiency trend"
            description = "Share of time in bed that turned into sleep."
            usageNote = "Efficiency comes from the same nightly sleep session data used by Sleep detail."
            emptyMessage = "No efficiency values exist in this range yet."
            fallbackRange = 50...100
            valueFormat = { String(Int($0.rounded())) }
        case "time asleep":
            mode = .daily { $0.totalSleepMin }
            unit = "h"
            color = StrandPalette.restColor
            icon = "moon.zzz.fill"
            overline = "TIME ASLEEP"
            chartTitle = "Sleep-duration trend"
            description = "Total sleep duration each night."
            usageNote = "This reuses NOOP's nightly sleep totals, not a display-only estimate."
            emptyMessage = "No sleep duration has been banked for this range yet."
            fallbackRange = 0...10
            valueFormat = { String(format: "%.1f", $0 / 60.0) }
        case "time in bed":
            mode = .series("in_bed_min")
            unit = "h"
            color = StrandPalette.metricPurple
            icon = "bed.double.fill"
            overline = "TIME IN BED"
            chartTitle = "Time-in-bed trend"
            description = "Window spent in bed each night."
            usageNote = "This uses NOOP's stored in-bed minutes, the same source that SleepView trends."
            emptyMessage = "No time-in-bed data exists in this range yet."
            fallbackRange = 0...12
            valueFormat = { String(format: "%.1f", $0 / 60.0) }
        case "sleep need":
            mode = .imported { $0.needMin }
            unit = "h"
            color = StrandPalette.metricAmber
            icon = "target"
            overline = "SLEEP NEED"
            chartTitle = "Sleep-need trend"
            description = "Imported nightly sleep need where history provided it."
            usageNote = "This is only shown when the underlying imported WHOOP history includes sleep-need values."
            emptyMessage = "No imported sleep-need data exists for this range."
            fallbackRange = 0...12
            valueFormat = { String(format: "%.1f", $0 / 60.0) }
        case "sleep debt":
            mode = .imported { max($0.debtMin ?? 0, 0) }
            unit = "h"
            color = StrandPalette.metricRose
            icon = "minus.circle.fill"
            overline = "SLEEP DEBT"
            chartTitle = "Sleep-debt trend"
            description = "Imported rolling sleep debt, when present."
            usageNote = "This stays hidden until imported history actually carries debt values."
            emptyMessage = "No imported sleep-debt values exist for this range."
            fallbackRange = 0...6
            valueFormat = { String(format: "%.1f", $0 / 60.0) }
        case "sleep reserve":
            mode = .imported { ($0.debtMin ?? 0) < 0 ? abs($0.debtMin ?? 0) : nil }
            unit = "h"
            color = StrandPalette.statusPositive
            icon = "plus.circle.fill"
            overline = "SLEEP RESERVE"
            chartTitle = "Sleep-reserve trend"
            description = "Surplus sleep above need, where imported history provided it."
            usageNote = "Reserve is only available when the imported history explicitly carries a negative debt value."
            emptyMessage = "No imported sleep-reserve values exist for this range."
            fallbackRange = 0...6
            valueFormat = { String(format: "%.1f", $0 / 60.0) }
        default:
            mode = .imported { $0.consistencyPct }
            unit = "%"
            color = StrandPalette.metricCyan
            icon = "calendar.badge.clock"
            overline = "CONSISTENCY"
            chartTitle = "Sleep-consistency trend"
            description = "Imported bedtime consistency where the source includes it."
            usageNote = "NOOP will not invent consistency values locally here; this view only charts real imported data."
            emptyMessage = "No imported sleep-consistency values exist for this range."
            fallbackRange = 0...100
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

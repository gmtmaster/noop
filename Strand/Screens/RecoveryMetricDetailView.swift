import SwiftUI
import StrandDesign

struct RecoveryMetricDetailView: View {
    let title: String

    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss
    @State private var range: MetricDetailRange = .month
    @State private var points: [TrendPoint] = []

    private var metric: RecoveryMetricConfig { .init(title: title) }

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
            .background(RecoveryTheme.background.ignoresSafeArea())
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
        RecoverySurface {
            VStack(alignment: .leading, spacing: 8) {
                Text(metric.overline).strandOverline()
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(latestText)
                        .font(StrandFont.number(28))
                        .foregroundStyle(.white)
                    if !metric.unit.isEmpty, latestText != "--" {
                        Text(metric.unit)
                            .font(StrandFont.footnote)
                            .foregroundStyle(RecoveryTheme.textSecondary)
                    }
                }
                Text(metric.description)
                    .font(StrandFont.subhead)
                    .foregroundStyle(RecoveryTheme.textSecondary)
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
                        .foregroundStyle(range == item ? RecoveryTheme.background : RecoveryTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(range == item ? RecoveryTheme.green : .clear,
                                    in: Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RecoveryTheme.surface, in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(RecoveryTheme.border, lineWidth: 1))
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
            RecoverySurface {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(RecoveryTheme.green)
                    Text("No data yet")
                        .font(StrandFont.title2)
                        .foregroundStyle(.white)
                    Text(metric.emptyMessage)
                        .font(StrandFont.subhead)
                        .foregroundStyle(RecoveryTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
            }
        }
    }

    private var summarySection: some View {
        RecoverySurface {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: metric.icon)
                    .foregroundStyle(metric.color)
                VStack(alignment: .leading, spacing: 5) {
                    Text("How NOOP uses it")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Text(metric.usageNote)
                        .font(StrandFont.subhead)
                        .foregroundStyle(RecoveryTheme.textSecondary)
                }
            }
        }
    }

    private func load() async {
        let series = await repo.exploreSeries(key: metric.key, source: "my-whoop")
        let allPoints = series.compactMap { row -> TrendPoint? in
            guard let date = MetricTrendDetailSupport.dayParser.date(from: row.day) else { return nil }
            return TrendPoint(date: date, value: row.value)
        }
        points = MetricTrendDetailSupport.filteredWindow(allPoints, range: range)
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

private struct RecoveryMetricConfig {
    let key: String
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
        case "charge":
            key = "recovery"
            unit = "%"
            color = RecoveryTheme.green
            icon = "heart.fill"
            overline = "CHARGE"
            chartTitle = "Charge trend"
            description = "Your NOOP Charge score across recent days."
            usageNote = "Charge is NOOP's readiness score, driven by HRV, resting heart rate, Rest quality, respiratory rate, and skin temperature deviation when available."
            emptyMessage = "NOOP needs completed sleep and a baseline before Charge can trend."
            fallbackRange = 0...100
            valueFormat = { String(Int($0.rounded())) }
        case "resting hrv":
            key = "hrv"
            unit = "ms"
            color = StrandPalette.metricPurple
            icon = "waveform"
            overline = "HRV"
            chartTitle = "Resting HRV trend"
            description = "Nightly HRV from your sleep window."
            usageNote = "Charge weighs HRV most heavily against your personal baseline."
            emptyMessage = "Wear your strap overnight to build this HRV trend."
            fallbackRange = 20...120
            valueFormat = { String(Int($0.rounded())) }
        case "resting hr":
            key = "rhr"
            unit = "bpm"
            color = StrandPalette.metricRose
            icon = "heart.fill"
            overline = "RESTING HR"
            chartTitle = "Resting heart-rate trend"
            description = "Lowest resting heart rate captured overnight."
            usageNote = "Lower resting heart rate versus your baseline supports a stronger Charge."
            emptyMessage = "Wear your strap overnight to build this resting-HR trend."
            fallbackRange = 40...80
            valueFormat = { String(Int($0.rounded())) }
        case "respiratory rate":
            key = "resp_rate"
            unit = "br/min"
            color = StrandPalette.metricCyan
            icon = "lungs.fill"
            overline = "RESPIRATORY"
            chartTitle = "Respiratory-rate trend"
            description = "Breathing rate estimated over sleep."
            usageNote = "NOOP uses respiratory rate as a supporting recovery signal when enough overnight data exists."
            emptyMessage = "No respiratory-rate data has been banked yet."
            fallbackRange = 10...20
            valueFormat = { String(format: "%.1f", $0) }
        case "wrist temperature":
            key = "skin_temp"
            unit = "°C"
            color = StrandPalette.metricAmber
            icon = "thermometer.medium"
            overline = "SKIN TEMP"
            chartTitle = "Skin-temperature trend"
            description = "Nightly skin-temperature signal from NOOP or imported history."
            usageNote = "NOOP uses skin temperature as an illness or overreach flag when baseline-aware deviation data exists."
            emptyMessage = "No skin-temperature data has been decoded for this range yet."
            fallbackRange = -1...1
            valueFormat = { String(format: "%+.1f", $0) }
        default:
            key = "spo2"
            unit = "%"
            color = StrandPalette.metricCyan
            icon = "drop.fill"
            overline = "BLOOD OXYGEN"
            chartTitle = "Blood-oxygen trend"
            description = "Average overnight SpO₂ when the source data exists."
            usageNote = "SpO₂ is shown as a supporting signal in Charge and Health, but NOOP does not invent a derived value when no source data exists."
            emptyMessage = "No SpO₂ data has been imported or decoded for this range yet."
            fallbackRange = 90...100
            valueFormat = { String(format: "%.1f", $0) }
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

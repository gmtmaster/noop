import SwiftUI
import StrandDesign
import WhoopStore

struct MetricRingCard: View {
    let title: LocalizedStringKey
    let value: String
    let progress: Double?
    let tint: Color
    let systemImage: String
    var caption: LocalizedStringKey? = nil

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(StrandPalette.hairline, lineWidth: 9)

                Circle()
                    .trim(from: 0, to: normalizedProgress)
                    .stroke(
                        AngularGradient(
                            colors: [tint.opacity(0.45), tint, tint.opacity(0.8)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: tint.opacity(0.32), radius: 7)

                Text(value)
                    .font(StrandFont.number(value.count > 5 ? 19 : 25))
                    .foregroundStyle(StrandPalette.textPrimary)
                    .minimumScaleFactor(0.68)
                    .lineLimit(1)
                    .padding(12)
            }
            .frame(width: 96, height: 96)

            VStack(spacing: 1) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StrandPalette.textPrimary)
                    .labelStyle(.titleAndIcon)
                if let caption {
                    Text(caption)
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textTertiary)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var normalizedProgress: Double {
        min(max(progress ?? 0, 0), 1)
    }
}

struct CompactInsightCard: View {
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("TODAY’S INSIGHT")
                        .font(StrandFont.overline)
                        .tracking(StrandFont.overlineTracking)
                        .foregroundStyle(StrandPalette.textSecondary)
                    Text(title)
                        .font(StrandFont.headline)
                        .foregroundStyle(tint)
                    Text(detail)
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct TodaySummaryStat {
    let label: String
    let value: String
}

struct TodaySummaryCard: View {
    let title: String
    let detail: String
    let tint: Color
    let stats: [TodaySummaryStat]

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 34, height: 34)
                        .background(tint.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TODAY SUMMARY")
                            .font(StrandFont.overline)
                            .tracking(StrandFont.overlineTracking)
                            .foregroundStyle(StrandPalette.textSecondary)
                        Text(title)
                            .font(StrandFont.headline)
                            .foregroundStyle(tint)
                        Text(detail)
                            .font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                if !stats.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stat.label.uppercased())
                                    .font(StrandFont.overline)
                                    .tracking(StrandFont.overlineTracking)
                                    .foregroundStyle(StrandPalette.textTertiary)
                                Text(stat.value)
                                    .font(StrandFont.headline)
                                    .foregroundStyle(StrandPalette.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

struct StressEnergyCard: View {
    let stress: String
    let stressDetail: String
    let energy: String

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            HStack(spacing: 0) {
                summary(
                    title: "Stress",
                    value: stress,
                    detail: stressDetail,
                    systemImage: "waveform.path.ecg",
                    tint: StrandPalette.metricAmber
                )
                Divider()
                    .overlay(StrandPalette.hairline)
                    .padding(.horizontal, 16)
                summary(
                    title: "Energy",
                    value: energy,
                    detail: "kcal today",
                    systemImage: "bolt.fill",
                    tint: StrandPalette.statusPositive
                )
            }
        }
    }

    private func summary(
        title: LocalizedStringKey,
        value: String,
        detail: String,
        systemImage: String,
        tint: Color,
        isPlaceholder: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).strandOverline()
                Text(value)
                    .font(isPlaceholder ? StrandFont.captionNumber : StrandFont.number(20))
                    .foregroundStyle(isPlaceholder ? StrandPalette.textSecondary : StrandPalette.textPrimary)
                    .lineLimit(1)
                Text(detail)
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TodayHeartRateTrendCard: View {
    let points: [TrendPoint]
    let liveHeartRate: Int?

    private var values: [Double] { points.map(\.value) }

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("HEART RATE").strandOverline()
                        Text("5-minute average · since midnight")
                            .font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                    Spacer(minLength: 12)
                    if let current = currentHeartRate {
                        Text("\(current) bpm")
                            .font(StrandFont.number(24))
                            .foregroundStyle(StrandPalette.metricRose)
                            .monospacedDigit()
                    }
                }

                if points.count > 1 {
                    TrendChart(
                        points: points,
                        gradient: Gradient(colors: [StrandPalette.metricRose.opacity(0.45), StrandPalette.metricRose]),
                        valueRange: valueRange,
                        showsArea: true,
                        height: NoopMetrics.chartHeight,
                        valueFormat: { "\(Int($0.rounded())) bpm" },
                        dateFormat: { Self.timeFormatter.string(from: $0) },
                        accessibilityLabel: "Heart rate today",
                        nowCapColor: StrandPalette.metricRose
                    )
                    ChartFooter([
                        ("Min", statText(values.min())),
                        ("Avg", statText(average)),
                        ("Max", statText(values.max())),
                    ])
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(StrandPalette.metricRose.opacity(0.8))
                        Text("No heart-rate samples yet today")
                            .font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: NoopMetrics.chartHeight)
                    .background(StrandPalette.surfaceRaised.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var currentHeartRate: Int? {
        liveHeartRate ?? points.last.map { Int($0.value.rounded()) }
    }

    private var average: Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var valueRange: ClosedRange<Double> {
        guard let min = values.min(), let max = values.max() else { return 40...120 }
        guard max > min else { return (min - 5)...(max + 5) }
        let padding = (max - min) * 0.12
        return (min - padding)...(max + padding)
    }

    private func statText(_ value: Double?) -> String {
        value.map { "\(Int($0.rounded()))" } ?? "--"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct BiomarkerCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let systemImage: String
    var tint: Color = StrandPalette.accent
    var detail: String? = nil
    var isPlaceholder = false

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 30, height: 30)
                        .background(tint.opacity(0.12), in: Circle())
                    Spacer()
                    if isPlaceholder {
                        Text("SOON")
                            .font(StrandFont.overline)
                            .tracking(StrandFont.overlineTracking)
                            .foregroundStyle(StrandPalette.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).strandOverline()
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(value)
                            .font(StrandFont.number(22))
                            .foregroundStyle(isPlaceholder ? StrandPalette.textSecondary : StrandPalette.textPrimary)
                        if !unit.isEmpty {
                            Text(unit)
                                .font(StrandFont.caption)
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                    }
                    if let detail {
                        Text(detail)
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(minHeight: 122)
        .accessibilityElement(children: .combine)
    }
}

struct ActionBiomarkerCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let systemImage: String
    var tint: Color = StrandPalette.accent
    var detail: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BiomarkerCard(
                title: title,
                value: value,
                unit: unit,
                systemImage: systemImage,
                tint: tint,
                detail: detail
            )
        }
        .buttonStyle(.plain)
    }
}

struct LatestWorkoutCard: View {
    let row: WorkoutRow
    let workoutsForDay: Int

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(StrandPalette.effortColor)
                    .frame(width: 38, height: 38)
                    .background(StrandPalette.effortColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(WorkoutSource.displaySport(row.sport))
                            .font(StrandFont.headline)
                            .foregroundStyle(StrandPalette.textPrimary)
                            .lineLimit(1)
                        if workoutsForDay > 1 {
                            Text("\(workoutsForDay) today")
                                .font(StrandFont.footnote)
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                    }
                    Text(timeLine)
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: 10) {
                        stat("Avg HR", row.avgHr.map { "\($0) bpm" } ?? "--")
                        stat("Peak", row.maxHr.map { "\($0) bpm" } ?? "--")
                        stat("Energy", row.energyKcal.map { "\(Int($0.rounded())) kcal" } ?? "--")
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StrandPalette.textTertiary)
            }
        }
    }

    private var symbol: String {
        let sport = row.sport.lowercased()
        if sport.contains("run") { return "figure.run" }
        if sport.contains("bike") || sport.contains("cycle") { return "bicycle" }
        if sport.contains("lift") || sport.contains("strength") { return "dumbbell.fill" }
        if sport.contains("walk") || sport.contains("hike") { return "figure.walk" }
        return "figure.mixed.cardio"
    }

    private var timeLine: String {
        let start = Date(timeIntervalSince1970: TimeInterval(row.startTs))
        let end = Date(timeIntervalSince1970: TimeInterval(row.endTs))
        return "\(durationLabel) · \(start.formatted(.dateTime.hour().minute())) - \(end.formatted(.dateTime.hour().minute()))"
    }

    private var durationLabel: String {
        let seconds = row.durationS ?? Double(row.endTs - row.startTs)
        let mins = Int((seconds / 60).rounded())
        let hours = mins / 60
        let rem = mins % 60
        if hours > 0 {
            return "\(hours)h \(rem)m"
        }
        return "\(rem)m"
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(StrandFont.overline)
                .tracking(StrandFont.overlineTracking)
                .foregroundStyle(StrandPalette.textTertiary)
            Text(value)
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.textPrimary)
                .lineLimit(1)
        }
    }
}

struct EmptySectionCard: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            StrandCard(padding: 16, cornerRadius: 16) {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 38, height: 38)
                        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(StrandFont.headline)
                            .foregroundStyle(StrandPalette.textPrimary)
                        Text(detail)
                            .font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(StrandPalette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct TodayDataSourcesCard: View {
    let whoopDays: Int
    let sleepCount: Int
    let appleDays: Int
    let batteryText: String
    let batterySymbol: String
    let batteryTint: Color
    let syncValue: String
    let syncDetail: String
    let onOpen: () -> Void

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sourceRow(
                    title: "WHOOP history",
                    value: whoopDays > 0 ? "\(whoopDays) days · \(sleepCount) sleeps" : "No history yet",
                    systemImage: "waveform.path.ecg",
                    tint: StrandPalette.accent
                )
                sourceRow(
                    title: "Apple Health",
                    value: appleDays > 0 ? "\(appleDays) days connected" : "Not connected",
                    systemImage: "heart.fill",
                    tint: StrandPalette.metricCyan
                )
                HStack(spacing: 10) {
                    sourceChip(title: "Battery", value: batteryText == "--" ? "--" : "\(batteryText)%", systemImage: batterySymbol, tint: batteryTint)
                    sourceChip(title: "Sync", value: syncValue, systemImage: "arrow.triangle.2.circlepath", tint: StrandPalette.accent)
                }
                Text(syncDetail)
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textTertiary)
                Button(action: onOpen) {
                    Label("Open Data Sources", systemImage: "externaldrive.fill")
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sourceRow(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrandPalette.textPrimary)
                Text(value)
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func sourceChip(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textTertiary)
                Text(value)
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textPrimary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StrandPalette.surfaceRaised.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct TodayShortcutCard: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            StrandCard(padding: 14, cornerRadius: 16) {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 34, height: 34)
                        .background(tint.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(StrandFont.headline)
                            .foregroundStyle(StrandPalette.textPrimary)
                        Text(detail)
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(StrandPalette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

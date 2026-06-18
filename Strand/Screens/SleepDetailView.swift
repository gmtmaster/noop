import SwiftUI
import StrandAnalytics
import StrandDesign
import WhoopStore

struct SleepDetailView: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var intelligence: IntelligenceEngine
    @Environment(\.dismiss) private var dismiss

    @State private var restScore: Double?
    @State private var wakeEdit: SleepDetailWakeEdit?
    @State private var selectedMetric: SleepMetricSelection?

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let night = latestNight {
                        hero(night)
                        summary(night)
                        if night.hasNoopRestOnlyMetrics {
                            sourcedMetricsNote
                        }
                        stageTimeline(night)
                        stageBreakdown(night)
                        trends(night)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, NoopMetrics.screenPadding)
                .padding(.bottom, 32)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadRestScore() }
        .task(id: repo.refreshSeq) { await loadRestScore() }
        .sheet(item: $selectedMetric) { metric in
            SleepMetricDetailView(title: metric.title)
                .environmentObject(repo)
        }
        .sheet(item: $wakeEdit) { edit in
            SleepDetailTimeEditor(bedTs: edit.bedTs, wakeTs: edit.wakeTs) { newBedTs, newWakeTs in
                await repo.editSleepTimes(
                    detectedStartTs: edit.detectedStartTs,
                    oldEndTs: edit.wakeTs,
                    storedStagesJSON: edit.stagesJSON,
                    newStartTs: newBedTs,
                    newEndTs: newWakeTs
                )
                await intelligence.analyzeRecent()
                await repo.refresh()
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StrandPalette.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(StrandPalette.surfaceRaised.opacity(0.92), in: Circle())
                    .overlay(Circle().stroke(StrandPalette.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close sleep details")

            Spacer()

            Text("Sleep")
                .font(StrandFont.title2)
                .foregroundStyle(StrandPalette.textPrimary)

            Spacer()

            if let target = latestNight?.editTarget {
                Button {
                    wakeEdit = SleepDetailWakeEdit(
                        detectedStartTs: target.startTs,
                        bedTs: target.effectiveStartTs,
                        wakeTs: target.endTs,
                        stagesJSON: target.stagesJSON
                    )
                } label: {
                    Image(systemName: target.userEdited ? "pencil.circle.fill" : "pencil.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SleepTheme.purple)
                        .frame(width: 34, height: 34)
                        .background(StrandPalette.surfaceRaised.opacity(0.92), in: Circle())
                        .overlay(Circle().stroke(StrandPalette.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(target.userEdited ? "Edit sleep times (edited)" : "Edit sleep times")
            } else {
                Color.clear.frame(width: 34, height: 34)
            }
        }
        .padding(.top, 14)
    }

    private func hero(_ night: SleepDetailNight) -> some View {
        VStack(spacing: 14) {
            SleepHeroRing(
                value: night.restText,
                progress: night.restScore.map { $0 / 100 }
            )
            VStack(spacing: 6) {
                Text(night.dateLabel)
                    .font(StrandFont.captionNumber)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(SleepTheme.surfaceRaised, in: Capsule(style: .continuous))
                    .overlay(Capsule().stroke(SleepTheme.border, lineWidth: 1))
                Text(night.restCaption)
                    .font(StrandFont.footnote)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func summary(_ night: SleepDetailNight) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
            SleepSummaryCard(title: "Time Asleep", value: night.timeAsleepText, systemImage: "moon.zzz.fill")
            SleepSummaryCard(title: "Time in Bed", value: night.timeInBedText, systemImage: "bed.double.fill")
            SleepSummaryCard(title: "Sleep Efficiency", value: night.efficiencyText, systemImage: "gauge.with.dots.needle.67percent")
            SleepSummaryCard(title: "Sleep Window", value: night.windowText, systemImage: "alarm.fill")
            SleepSummaryCard(title: "Bedtime", value: night.bedtimeText, systemImage: "bed.double.fill")
            SleepSummaryCard(title: "Wake", value: night.wakeText, systemImage: "sunrise.fill")
            if let sleepNeedText = night.sleepNeedText {
                SleepSummaryCard(title: "Sleep Need", value: sleepNeedText, systemImage: "target")
            }
            if let sleepDebtText = night.sleepDebtText {
                SleepSummaryCard(title: "Sleep Debt", value: sleepDebtText, systemImage: "minus.circle.fill")
            }
            if let sleepReserveText = night.sleepReserveText {
                SleepSummaryCard(title: "Sleep Reserve", value: sleepReserveText, systemImage: "plus.circle.fill")
            }
            if let consistencyText = night.consistencyText {
                SleepSummaryCard(title: "Consistency", value: consistencyText, systemImage: "calendar.badge.clock")
            }
        }
    }

    private func stageTimeline(_ night: SleepDetailNight) -> some View {
        ChartCard(
            title: "Stage timeline",
            subtitle: night.timelineSubtitle,
            trailing: night.timelineTrailing,
            height: NoopMetrics.chartHeight,
            tint: StrandPalette.restColor,
            chart: {
                if night.intervals.count >= 2 {
                    Hypnogram(
                        intervals: night.intervals,
                        height: NoopMetrics.chartHeight,
                        showsStageAxis: true,
                        nightStart: night.onsetDate,
                        showsTimeAxis: true
                    )
                } else {
                    SleepDetailStageBar(stages: night.stageMinutes)
                }
            },
            footer: {
                ChartFooter([
                    ("REM", "\(night.durationText(night.stageMinutes.rem)) · \(night.percentText(night.stageMinutes.rem))"),
                    ("Deep", "\(night.durationText(night.stageMinutes.deep)) · \(night.percentText(night.stageMinutes.deep))"),
                    ("Light", "\(night.durationText(night.stageMinutes.light)) · \(night.percentText(night.stageMinutes.light))"),
                    ("Awake", "\(night.durationText(night.stageMinutes.awake)) · \(night.percentText(night.stageMinutes.awake))"),
                ])
            }
        )
    }

    private func stageBreakdown(_ night: SleepDetailNight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stages")
                .font(StrandFont.title2)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                SleepDetailStageMetric(title: "REM", minutes: night.stageMinutes.rem, stage: .rem)
                SleepDetailStageMetric(title: "Deep", minutes: night.stageMinutes.deep, stage: .deep)
                SleepDetailStageMetric(title: "Light", minutes: night.stageMinutes.light, stage: .light)
                SleepDetailStageMetric(title: "Awake", minutes: night.stageMinutes.awake, stage: .awake)
            }
        }
    }

    private func trends(_ night: SleepDetailNight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends")
                .font(StrandFont.title2)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                trend("Rest", night.restText, "%", "moon.stars.fill")
                trend("Sleep Efficiency", night.efficiencyText, "", "gauge.with.dots.needle.67percent")
                trend("Time Asleep", night.timeAsleepText, "", "moon.zzz.fill")
                trend("Time in Bed", night.timeInBedText, "", "bed.double.fill")
                if let sleepNeed = night.sleepNeedText {
                    trend("Sleep Need", sleepNeed, "", "target")
                }
                if let sleepDebt = night.sleepDebtText {
                    trend("Sleep Debt", sleepDebt, "", "minus.circle.fill")
                }
                if let sleepReserve = night.sleepReserveText {
                    trend("Sleep Reserve", sleepReserve, "", "plus.circle.fill")
                }
                if let consistency = night.consistencyText {
                    trend("Consistency", consistency, "", "calendar.badge.clock")
                }
            }
        }
    }

    private func trend(_ title: String, _ value: String, _ unit: String, _ icon: String) -> some View {
        SleepTrendCard(title: LocalizedStringKey(title), value: value, unit: unit, systemImage: icon) {
            selectedMetric = SleepMetricSelection(title: title)
        }
    }

    private var emptyState: some View {
        SleepSurface {
            VStack(spacing: 12) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(SleepTheme.purple)
                Text("No sleep data yet")
                    .font(StrandFont.title2)
                    .foregroundStyle(.white)
                Text("Wear your strap overnight or import WHOOP history to unlock sleep stages and editing.")
                    .font(StrandFont.subhead)
                    .foregroundStyle(SleepTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
        }
    }

    private var background: some View {
        ZStack {
            SleepTheme.background
            RadialGradient(
                colors: [SleepTheme.violet.opacity(0.25), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 520
            )
            Canvas { context, size in
                for index in 0..<28 {
                    let x = CGFloat((index * 73) % 101) / 100 * size.width
                    let y = CGFloat((index * 47) % 37) / 100 * min(size.height, 420)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                        with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.20 : 0.09))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }

    private var latestNight: SleepDetailNight? {
        guard let session = latestSession else { return nil }
        let day = Self.dayKey(for: session.endTs)
        return SleepDetailNight(session: session, today: repo.today,
                                figures: repo.importedSleep[day], restScore: restScore)
    }

    private var latestSession: CachedSleepSession? {
        guard let todayKey = repo.today?.day else { return repo.sleeps.last }
        return repo.sleeps.last(where: { Self.dayKey(for: $0.endTs) == todayKey }) ?? repo.sleeps.last
    }

    private func loadRestScore() async {
        let targetDay = latestSession.map { Self.dayKey(for: $0.endTs) }
            ?? repo.today?.day
            ?? Repository.localDayKey(Date())
        let restSeries = await repo.exploreSeries(key: "sleep_performance", source: "my-whoop")
        let restByDay = Dictionary(restSeries.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        restScore = restByDay[targetDay]
    }

    private var sourcedMetricsNote: some View {
        SleepSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("Rest is computed by NOOP")
                    .font(StrandFont.headline)
                    .foregroundStyle(.white)
                Text("Sleep need, debt, reserve, and consistency appear only when imported history provided them. This fork does not yet compute NOOP-native versions of those fields locally.")
                    .font(StrandFont.subhead)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private static func dayKey(for timestamp: Int) -> String {
        dayFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct SleepDetailNight {
    let session: CachedSleepSession
    let today: DailyMetric?
    let figures: ImportedSleepFigures?
    let restScore: Double?
    let stageMinutes: SleepStageTotals.Minutes
    let intervals: [SleepInterval]
    let hasRecordedTimeline: Bool

    init(session: CachedSleepSession, today: DailyMetric?, figures: ImportedSleepFigures?, restScore: Double?) {
        self.session = session
        self.today = today
        self.figures = figures
        self.restScore = restScore

        let decodedMinutes = SleepStageTotals.minutes(fromStagesJSON: session.stagesJSON)
        let fallbackMinutes = SleepDetailNight.fallbackMinutes(session: session, today: today)
        let minutes = decodedMinutes ?? fallbackMinutes
        stageMinutes = minutes

        if let segments = Self.decodeSegments(session.stagesJSON, sessionStart: session.effectiveStartTs), segments.count >= 2 {
            intervals = segments
            hasRecordedTimeline = true
        } else {
            intervals = Self.syntheticIntervals(from: minutes)
            hasRecordedTimeline = false
        }
    }

    var editTarget: CachedSleepSession? { session }

    var dateLabel: String {
        let date = Date(timeIntervalSince1970: TimeInterval(session.endTs))
        let day = Calendar.current.isDateInToday(date) ? "Today" : date.formatted(.dateTime.weekday(.abbreviated))
        return "\(day), \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var restText: String {
        restScore.map { "\(Int($0.rounded()))%" } ?? "--"
    }

    var restCaption: String {
        restScore == nil ? "Calibrating" : "Rest"
    }

    var onsetDate: Date { Date(timeIntervalSince1970: TimeInterval(session.effectiveStartTs)) }

    var timeAsleepMinutes: Double { stageMinutes.asleep }
    var timeInBedMinutes: Double {
        let clockMinutes = Double(max(0, session.endTs - session.effectiveStartTs)) / 60.0
        return max(clockMinutes, stageMinutes.inBed)
    }

    var timeAsleepText: String { durationText(timeAsleepMinutes) }
    var timeInBedText: String { durationText(timeInBedMinutes) }
    var hasNoopRestOnlyMetrics: Bool {
        figures?.needMin == nil && figures?.debtMin == nil && figures?.consistencyPct == nil
    }

    var sleepNeedText: String? { optionalDurationText(figures?.needMin) }
    var sleepDebtText: String? {
        guard let debt = figures?.debtMin, debt > 0 else { return nil }
        return durationText(debt)
    }
    var sleepReserveText: String? {
        guard let debt = figures?.debtMin, debt < 0 else { return nil }
        return durationText(abs(debt))
    }
    var consistencyText: String? { percentMetricText(figures?.consistencyPct) }
    var bedtimeText: String { timeText(session.effectiveStartTs) }
    var wakeText: String { timeText(session.endTs) }

    var efficiencyPercent: Double? {
        if let stored = session.efficiency ?? today?.efficiency {
            return stored <= 1.0 ? stored * 100 : stored
        }
        guard timeInBedMinutes > 0 else { return nil }
        return min(100, timeAsleepMinutes / timeInBedMinutes * 100)
    }

    var efficiencyText: String {
        efficiencyPercent.map { "\(Int($0.rounded()))%" } ?? "--"
    }

    var windowText: String {
        "\(timeText(session.effectiveStartTs)) - \(timeText(session.endTs))"
    }

    var timelineSubtitle: String {
        "\(timeInBedText) in bed · \(efficiencyText) efficiency" + (hasRecordedTimeline ? "" : " · approximated from totals")
    }

    var timelineTrailing: String { timeAsleepText }

    func percentText(_ minutes: Double) -> String {
        guard stageMinutes.inBed > 0 else { return "0%" }
        return "\(Int((minutes / stageMinutes.inBed * 100).rounded()))%"
    }

    func durationText(_ minutes: Double) -> String {
        let rounded = max(0, Int(minutes.rounded()))
        if rounded < 60 { return "\(rounded)m" }
        return "\(rounded / 60)h \(rounded % 60)m"
    }

    private func optionalDurationText(_ minutes: Double?) -> String? {
        guard let minutes, minutes > 0 else { return nil }
        return durationText(minutes)
    }

    private func percentMetricText(_ value: Double?) -> String? {
        value.map { "\(Int($0.rounded()))%" }
    }

    private func timeText(_ timestamp: Int) -> String {
        Date(timeIntervalSince1970: TimeInterval(timestamp)).formatted(.dateTime.hour().minute())
    }

    private static func fallbackMinutes(session: CachedSleepSession, today: DailyMetric?) -> SleepStageTotals.Minutes {
        if let today {
            let asleep = today.totalSleepMin ?? 0
            let inBed = (today.efficiency ?? 0) > 0 ? asleep / max((today.efficiency ?? 0) > 1 ? (today.efficiency ?? 0) / 100.0 : today.efficiency ?? 0, 0.01) : asleep
            return SleepStageTotals.Minutes(
                awake: max(0, inBed - asleep),
                light: today.lightMin ?? 0,
                deep: today.deepMin ?? 0,
                rem: today.remMin ?? 0
            )
        }
        let inBed = Double(max(0, session.endTs - session.effectiveStartTs)) / 60.0
        return SleepStageTotals.Minutes(awake: 0, light: inBed, deep: 0, rem: 0)
    }

    private static func decodeSegments(_ json: String?, sessionStart: Int) -> [SleepInterval]? {
        guard let json,
              let data = json.data(using: .utf8),
              let array = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]],
              !array.isEmpty else { return nil }

        var intervals: [SleepInterval] = []
        for segment in array {
            guard let start = (segment["start"] as? NSNumber)?.intValue,
                  let end = (segment["end"] as? NSNumber)?.intValue,
                  end > start,
                  let name = segment["stage"] as? String else { continue }

            let stage: SleepStage
            switch name {
            case "wake", "awake": stage = .awake
            case "light": stage = .light
            case "deep": stage = .deep
            case "rem": stage = .rem
            default: continue
            }

            intervals.append(
                SleepInterval(
                    stage: stage,
                    start: TimeInterval(start - sessionStart),
                    end: TimeInterval(end - sessionStart)
                )
            )
        }

        return intervals.isEmpty ? nil : intervals
    }

    private static func syntheticIntervals(from minutes: SleepStageTotals.Minutes) -> [SleepInterval] {
        var t: TimeInterval = 0
        var out: [SleepInterval] = []

        func add(_ stage: SleepStage, _ stageMinutes: Double) {
            guard stageMinutes > 0 else { return }
            let seconds = stageMinutes * 60
            out.append(SleepInterval(stage: stage, start: t, end: t + seconds))
            t += seconds
        }

        add(.light, minutes.light * 0.4)
        add(.deep, minutes.deep)
        add(.light, minutes.light * 0.3)
        add(.rem, minutes.rem)
        add(.light, minutes.light * 0.3)
        add(.awake, minutes.awake)
        return out
    }
}

private struct SleepDetailStageBar: View {
    let stages: SleepStageTotals.Minutes

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer(minLength: 0)
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    segment(.deep, stages.deep, total: stages.inBed, width: geometry.size.width)
                    segment(.light, stages.light, total: stages.inBed, width: geometry.size.width)
                    segment(.rem, stages.rem, total: stages.inBed, width: geometry.size.width)
                    segment(.awake, stages.awake, total: stages.inBed, width: geometry.size.width)
                }
            }
            .frame(height: 34)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 16) {
                legend(.deep, "Deep")
                legend(.light, "Light")
                legend(.rem, "REM")
                legend(.awake, "Awake")
            }
            Spacer(minLength: 0)
        }
    }

    private func segment(_ stage: SleepStage, _ minutes: Double, total: Double, width: CGFloat) -> some View {
        Rectangle()
            .fill(StrandPalette.sleepStageColor(stage))
            .frame(width: total > 0 ? max(0, CGFloat(minutes / total) * width) : 0)
    }

    private func legend(_ stage: SleepStage, _ label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(StrandPalette.sleepStageColor(stage))
                .frame(width: 9, height: 9)
            Text(label)
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.textTertiary)
        }
    }
}

private struct SleepDetailStageMetric: View {
    let title: String
    let minutes: Double
    let stage: SleepStage

    var body: some View {
        SleepSurface {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(StrandPalette.sleepStageColor(stage))
                        .frame(width: 12, height: 12)
                    Text(title)
                        .font(StrandFont.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
                Text(durationText(minutes))
                    .font(StrandFont.number(24))
                    .foregroundStyle(.white)
            }
        }
    }

    private func durationText(_ minutes: Double) -> String {
        let rounded = max(0, Int(minutes.rounded()))
        if rounded < 60 { return "\(rounded)m" }
        return "\(rounded / 60)h \(rounded % 60)m"
    }
}

private struct SleepDetailWakeEdit: Identifiable {
    let detectedStartTs: Int
    let bedTs: Int
    let wakeTs: Int
    let stagesJSON: String?

    var id: Int { detectedStartTs }
}

private struct SleepMetricSelection: Identifiable {
    let title: String
    var id: String { title }
}

private struct SleepDetailTimeEditor: View {
    let onSave: (Int, Int) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var bed: Date
    @State private var wake: Date
    @State private var saving = false

    init(bedTs: Int, wakeTs: Int, onSave: @escaping (Int, Int) async -> Void) {
        self.onSave = onSave
        _bed = State(initialValue: Date(timeIntervalSince1970: TimeInterval(bedTs)))
        _wake = State(initialValue: Date(timeIntervalSince1970: TimeInterval(wakeTs)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.gap) {
            Text("Edit sleep times")
                .font(StrandFont.title2)
                .foregroundStyle(StrandPalette.textPrimary)
            Text("Correct when you went to bed and woke. Stages are re-derived from your data and kept through the next sync.")
                .font(StrandFont.subhead)
                .foregroundStyle(StrandPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            SleepSurface {
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker("Asleep", selection: $bed, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .font(StrandFont.body)
                        .tint(StrandPalette.restColor)
                    Divider().overlay(StrandPalette.hairline)
                    DatePicker("Woke", selection: $wake, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.compact)
                        .font(StrandFont.body)
                        .tint(StrandPalette.restColor)
                }
            }

            HStack(spacing: NoopMetrics.gap) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .tint(StrandPalette.textTertiary)
                    .disabled(saving)
                Spacer()
                Button(saving ? "Saving..." : "Save") {
                    saving = true
                    Task {
                        await onSave(Int(bed.timeIntervalSince1970), Int(resolvedWake().timeIntervalSince1970))
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(StrandPalette.accent)
                .disabled(saving)
            }
        }
        .padding(NoopMetrics.screenPadding)
        .frame(minWidth: 360)
        .background(StrandPalette.surfaceBase)
    }

    private func resolvedWake() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: wake)
        return calendar.nextDate(after: bed.addingTimeInterval(60), matching: components, matchingPolicy: .nextTime)
            ?? bed.addingTimeInterval(8 * 3600)
    }
}

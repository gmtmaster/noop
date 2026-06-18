import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

struct TodayDashboardView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var intelligence: IntelligenceEngine
    @AppStorage("profile.firstName") private var firstName = "Adam"
    @AppStorage(UnitPrefs.effortScaleKey) private var effortScaleRaw = EffortScale.hundred.rawValue
    @State private var showingSleepDetail = false
    @State private var showingFullSleep = false
    @State private var showingRecoveryDetail = false
    @State private var showingStrainDetail = false
    @State private var showingStressDetail = false
    @State private var showingHealthMonitor = false
    @State private var showingWorkouts = false
    @State private var showingWorkoutDetail = false
    @State private var showingDataSources = false
    @State private var hrPoints: [TrendPoint] = []
    @State private var liveTodayStrain: Double?
    @State private var restScore: Double?
    @State private var stressScore: Double?
    @State private var stressDetailText = "Calibrating"
    @State private var selectedDayOffset = 0
    @State private var latestWorkout: WorkoutRow?
    @State private var workoutsForDay = 0

    private var effortScale: EffortScale { UnitPrefs.resolveEffortScale(effortScaleRaw) }

    private let biomarkerGrid = [
        GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 10)
    ]

    private var selectedLogicalDay: Date {
        let base = Repository.logicalDay(Date())
        return Calendar.current.date(byAdding: .day, value: -selectedDayOffset, to: base) ?? base
    }

    private var selectedDayKey: String {
        if selectedDayOffset == 0, let todayKey = repo.today?.day { return todayKey }
        return Repository.localDayKey(selectedLogicalDay)
    }

    private var displayDay: DailyMetric? {
        if selectedDayOffset == 0 {
            return repo.today ?? repo.days.last(where: { $0.day == selectedDayKey })
        }
        return repo.days.last(where: { $0.day == selectedDayKey })
    }

    private var snapshot: TodayDashboardSnapshot {
        TodayDashboardSnapshot(
            today: displayDay,
            rest: restScore,
            liveHeartRate: model.bpm ?? live.heartRate,
            liveStrain: selectedDayOffset == 0 ? liveTodayStrain : nil,
            stress: stressScore,
            effortScale: effortScale,
            battery: live.batteryPct,
            lastSync: live.lastSyncedAt
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                greeting
                DayNavBar(selectedOffset: selectedDayOffset) { selectedDayOffset = $0 }
                primaryMetrics
                summary
                latestActivity
                heartRateTrend
                keyMetrics
                dataSources
            }
            .padding(.horizontal, NoopMetrics.screenPadding)
            .padding(.vertical, 18)
            .frame(maxWidth: 1120)
            .frame(maxWidth: .infinity)
        }
        .background(background)
        .task {
            await repo.refresh()
            await loadDashboardData()
        }
        .task(id: TodayDashboardLoadKey(seq: repo.refreshSeq, offset: selectedDayOffset)) { await loadDashboardData() }
#if os(macOS)
        .sheet(isPresented: $showingSleepDetail) {
            SleepDetailView()
                .environmentObject(repo)
                .environmentObject(intelligence)
        }
        .sheet(isPresented: $showingFullSleep) {
            SleepView()
                .environmentObject(repo)
                .environmentObject(live)
                .environmentObject(intelligence)
        }
        .sheet(isPresented: $showingRecoveryDetail) {
            RecoveryDetailView()
                .environmentObject(repo)
        }
        .sheet(isPresented: $showingStrainDetail) {
            StrainDetailView()
                .environmentObject(repo)
        }
        .sheet(isPresented: $showingStressDetail) {
            StressView()
                .environmentObject(repo)
        }
        .sheet(isPresented: $showingHealthMonitor) {
            HealthView()
                .environmentObject(repo)
                .environmentObject(live)
                .environmentObject(profile)
                .environmentObject(model)
        }
        .sheet(isPresented: $showingWorkouts) {
            WorkoutsView()
                .environmentObject(repo)
                .environmentObject(model)
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let latestWorkout {
                NavigationStack {
                    WorkoutDetailView(row: latestWorkout)
                        .environmentObject(repo)
                }
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showingDataSources) {
            DataSourcesView()
                .environmentObject(model)
                .environmentObject(repo)
                .environmentObject(live)
        }
#else
        .fullScreenCover(isPresented: $showingSleepDetail) {
            SleepDetailView()
                .environmentObject(repo)
                .environmentObject(intelligence)
        }
        .fullScreenCover(isPresented: $showingFullSleep) {
            SleepView()
                .environmentObject(repo)
                .environmentObject(live)
                .environmentObject(intelligence)
        }
        .fullScreenCover(isPresented: $showingRecoveryDetail) {
            RecoveryDetailView()
                .environmentObject(repo)
        }
        .fullScreenCover(isPresented: $showingStrainDetail) {
            StrainDetailView()
                .environmentObject(repo)
        }
        .fullScreenCover(isPresented: $showingStressDetail) {
            StressView()
                .environmentObject(repo)
        }
        .fullScreenCover(isPresented: $showingHealthMonitor) {
            HealthView()
                .environmentObject(repo)
                .environmentObject(live)
                .environmentObject(profile)
                .environmentObject(model)
        }
        .fullScreenCover(isPresented: $showingWorkouts) {
            WorkoutsView()
                .environmentObject(repo)
                .environmentObject(model)
        }
        .fullScreenCover(isPresented: $showingWorkoutDetail) {
            if let latestWorkout {
                NavigationStack {
                    WorkoutDetailView(row: latestWorkout)
                        .environmentObject(repo)
                }
            } else {
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showingDataSources) {
            DataSourcesView()
                .environmentObject(model)
                .environmentObject(repo)
                .environmentObject(live)
        }
#endif
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(dateText.uppercased())
                .font(StrandFont.overline)
                .tracking(StrandFont.overlineTracking)
                .foregroundStyle(StrandPalette.accent)
            Text("\(greetingText), \(firstName)")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(StrandPalette.textPrimary)
            Text("Here is how your body is doing today.")
                .font(StrandFont.subhead)
                .foregroundStyle(StrandPalette.textSecondary)
        }
    }

    private var primaryMetrics: some View {
        StrandCard(padding: 14, cornerRadius: NoopMetrics.cardRadius) {
            HStack(alignment: .top, spacing: 8) {
                Button { showingSleepDetail = true } label: {
                    sleepCard
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityHint("Opens sleep details")
                Button { showingRecoveryDetail = true } label: {
                    chargeCard
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityHint("Opens charge details")
                Button { showingStrainDetail = true } label: {
                    strainCard
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityHint("Opens strain details")
            }
        }
    }

    private var chargeCard: some View {
        MetricRingCard(
            title: "Charge",
            value: snapshot.chargeText,
            progress: snapshot.charge.map { $0 / 100 },
            tint: snapshot.charge.map(StrandPalette.recoveryColor) ?? StrandPalette.textTertiary,
            systemImage: "heart.fill",
            caption: snapshot.charge == nil ? "Calibrating" : "readiness"
        )
    }

    private var sleepCard: some View {
        MetricRingCard(
            title: "Rest",
            value: snapshot.restText,
            progress: snapshot.rest.map { $0 / 100 },
            tint: snapshot.rest.map { _ in StrandPalette.restColor } ?? StrandPalette.textTertiary,
            systemImage: "moon.stars.fill",
            caption: snapshot.rest == nil ? "Calibrating" : "rest"
        )
    }

    private var strainCard: some View {
        MetricRingCard(
            title: "Effort",
            value: snapshot.effortText,
            progress: snapshot.effort.map { $0 / snapshot.strainScaleMax },
            tint: snapshot.effort.map { StrandPalette.strainColor($0 / snapshot.strainScaleMax * 100) } ?? StrandPalette.textTertiary,
            systemImage: "flame.fill",
            caption: snapshot.effort == nil ? "Calibrating" : "today"
        )
    }

    private var summary: some View {
        TodaySummaryCard(
            title: snapshot.insightTitle,
            detail: snapshot.insightDetail,
            tint: snapshot.charge.map(StrandPalette.recoveryColor) ?? StrandPalette.accent,
            stats: [
                TodaySummaryStat(label: "Energy", value: snapshot.energy.map { "\(Int($0.rounded())) kcal" } ?? "--"),
                TodaySummaryStat(label: "Steps", value: displayDay?.steps.map { "\($0)" } ?? "--"),
                TodaySummaryStat(label: "Stress", value: snapshot.stressText)
            ]
        )
    }

    private var latestActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Latest activity")
                    .font(StrandFont.headline)
                    .foregroundStyle(StrandPalette.textPrimary)
                Spacer(minLength: 8)
                Button("All Workouts") {
                    showingWorkouts = true
                }
                .buttonStyle(.plain)
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.accent)
            }

            if let latestWorkout {
                Button {
                    showingWorkoutDetail = true
                } label: {
                    LatestWorkoutCard(row: latestWorkout, workoutsForDay: workoutsForDay)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens workout details")
            } else {
                EmptySectionCard(
                    title: "No activity for this day",
                    detail: selectedDayOffset == 0
                        ? "Your latest workout will appear here as soon as one is recorded or imported."
                        : "There is no recorded workout on this day yet.",
                    systemImage: "figure.run",
                    tint: StrandPalette.strainColor(42)
                ) {
                    showingWorkouts = true
                }
            }
        }
    }

    private var heartRateTrend: some View {
        TodayHeartRateTrendCard(points: hrPoints, liveHeartRate: snapshot.liveHeartRate)
    }

    private var keyMetrics: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Key metrics")
                    .font(StrandFont.headline)
                    .foregroundStyle(StrandPalette.textPrimary)
                Spacer(minLength: 8)
                Button("Health") {
                    showingHealthMonitor = true
                }
                .buttonStyle(.plain)
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.accent)
                Button("Stress") {
                    showingStressDetail = true
                }
                .buttonStyle(.plain)
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.accent)
            }

            LazyVGrid(columns: biomarkerGrid, alignment: .leading, spacing: 10) {
                BiomarkerCard(
                    title: "Resting HR",
                    value: snapshot.restingHeartRate.map(String.init) ?? "--",
                    unit: "bpm",
                    systemImage: "heart.text.square.fill",
                    tint: StrandPalette.metricRose
                )
                BiomarkerCard(
                    title: "HRV",
                    value: format(snapshot.hrv, decimals: 0),
                    unit: "ms",
                    systemImage: "waveform",
                    tint: StrandPalette.metricPurple
                )
                BiomarkerCard(
                    title: "Respiratory Rate",
                    value: format(snapshot.respiratoryRate, decimals: 1),
                    unit: "br/min",
                    systemImage: "lungs.fill",
                    tint: StrandPalette.metricCyan
                )
                BiomarkerCard(
                    title: "Skin Temperature",
                    value: signed(snapshot.skinTemperatureDeviation),
                    unit: "°C",
                    systemImage: "thermometer.medium",
                    tint: StrandPalette.metricAmber,
                    detail: snapshot.skinTemperatureDeviation == nil ? "Calibrating" : "vs. baseline"
                )
                BiomarkerCard(
                    title: "SpO₂",
                    value: format(snapshot.spo2, decimals: 1),
                    unit: "%",
                    systemImage: "drop.fill",
                    tint: StrandPalette.metricCyan,
                    detail: snapshot.spo2 == nil ? "Unavailable" : "sleep average"
                )
                ActionBiomarkerCard(
                    title: "Stress Monitor",
                    value: snapshot.stressText,
                    unit: "",
                    systemImage: "bolt.heart.fill",
                    tint: StrandPalette.metricAmber,
                    detail: stressDetailText,
                    action: { showingStressDetail = true }
                )
                BiomarkerCard(
                    title: "Live HR",
                    value: snapshot.liveHeartRate.map(String.init) ?? "--",
                    unit: "bpm",
                    systemImage: "heart.fill",
                    tint: StrandPalette.metricRose,
                    detail: live.connected ? "Live from WHOOP" : "Strap disconnected"
                )
            }
        }
    }

    private var dataSources: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Data sources")
                    .font(StrandFont.headline)
                    .foregroundStyle(StrandPalette.textPrimary)
                Spacer(minLength: 8)
                Button("Open Data Sources") {
                    showingDataSources = true
                }
                .buttonStyle(.plain)
                .font(StrandFont.footnote)
                .foregroundStyle(StrandPalette.accent)
            }

            TodayDataSourcesCard(
                whoopDays: repo.days.count,
                sleepCount: repo.sleeps.count,
                appleDays: repo.freshness.appleDays,
                batteryText: format(snapshot.battery, decimals: 0),
                batterySymbol: batterySymbol,
                batteryTint: batteryTint,
                syncValue: syncValue,
                syncDetail: live.backfilling ? "Syncing now" : "Strap history",
                onOpen: { showingDataSources = true }
            )
        }
    }

    private var background: some View {
        ZStack {
            StrandPalette.surfaceBase
            RadialGradient(
                colors: [StrandPalette.accent.opacity(0.10), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 620
            )
        }
        .ignoresSafeArea()
    }

    private var greetingText: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var dateText: String {
        if selectedDayOffset == 0 {
            return Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
        }
        return selectedLogicalDay.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private func format(_ value: Double?, decimals: Int) -> String {
        guard let value else { return "--" }
        return String(format: "%.\(decimals)f", value)
    }

    private func signed(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%+.1f", value)
    }

    private var syncValue: String {
        guard let lastSync = snapshot.lastSync else { return "Not yet" }
        return relativeAgo(lastSync)
    }

    private var batteryTint: Color {
        guard let battery = snapshot.battery else { return StrandPalette.textTertiary }
        if battery < 15 { return StrandPalette.statusCritical }
        if battery < 35 { return StrandPalette.statusWarning }
        return StrandPalette.statusPositive
    }

    private var batterySymbol: String {
        if live.charging == true { return "battery.100.bolt" }
        guard let battery = snapshot.battery else { return "battery.0" }
        switch battery {
        case ..<13: return "battery.0"
        case ..<38: return "battery.25"
        case ..<63: return "battery.50"
        case ..<88: return "battery.75"
        default: return "battery.100"
        }
    }

    private func loadDashboardData() async {
        let logicalDay = selectedLogicalDay
        let dayStart = Calendar.current.startOfDay(for: logicalDay)
        let windowStart = Int(dayStart.timeIntervalSince1970)
        let windowEnd = selectedDayOffset == 0
            ? Int(Date().timeIntervalSince1970)
            : Int((Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart).timeIntervalSince1970)

        hrPoints = await repo.hrBuckets(from: windowStart, to: windowEnd, bucketSeconds: 300)
            .map { TrendPoint(date: Date(timeIntervalSince1970: TimeInterval($0.ts)), value: $0.bpm) }

        let todayHr = await repo.hrSamples(from: windowStart, to: windowEnd)
        let maxHR = profile.age > 0 ? StrainScorer.tanakaHRmax(age: Double(profile.age)) : nil
        let restHR = displayDay?.restingHr.map(Double.init) ?? StrainScorer.defaultRestingHR
        liveTodayStrain = selectedDayOffset == 0
            ? StrainScorer.strain(todayHr, maxHR: maxHR, restingHR: restHR, sex: profile.sex)
            : nil

        let todayKey = selectedDayKey
        let restSeries = await repo.exploreSeries(key: "sleep_performance", source: "my-whoop")
        let restByDay = Dictionary(restSeries.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
        restScore = restByDay[todayKey]
        let stressSeries = await repo.series(key: "stress", source: "my-whoop")
        if let stressModel = StressModel(days: repo.days, stored: stressSeries) {
            stressScore = stressModel.score
            stressDetailText = stressModel.usingStored ? "Recorded daily stress" : "Estimated from HRV + resting HR"
        } else {
            stressScore = nil
            stressDetailText = "Calibrating"
        }

        let workouts = await repo.workoutRows()
        let filtered = workouts.filter {
            Repository.localDayKey(Date(timeIntervalSince1970: TimeInterval($0.startTs))) == todayKey
        }
        latestWorkout = filtered.first
        workoutsForDay = filtered.count
    }

}

private struct TodayDashboardLoadKey: Equatable {
    let seq: Int
    let offset: Int
}

#if DEBUG
#Preview("Today Dashboard") {
    let model = AppModel()
    return TodayDashboardView()
        .environmentObject(model)
        .environmentObject(model.repo)
        .environmentObject(model.live)
        .environmentObject(model.profile)
        .frame(width: 1100, height: 850)
        .preferredColorScheme(.dark)
}
#endif

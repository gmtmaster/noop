import SwiftUI
import StrandDesign
import StrandAnalytics

struct TodayDashboardView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var intelligence: IntelligenceEngine
    @AppStorage("profile.firstName") private var firstName = "Adam"
    @AppStorage(UnitPrefs.effortScaleKey) private var effortScaleRaw = EffortScale.hundred.rawValue
    @State private var showingSleepDetail = false
    @State private var showingRecoveryDetail = false
    @State private var showingStrainDetail = false
    @State private var showingStressDetail = false
    @State private var hrPoints: [TrendPoint] = []
    @State private var liveTodayStrain: Double?
    @State private var restScore: Double?
    @State private var stressScore: Double?
    @State private var stressDetailText = "Calibrating"

    private var effortScale: EffortScale { UnitPrefs.resolveEffortScale(effortScaleRaw) }

    private let biomarkerGrid = [
        GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 10)
    ]

    private var snapshot: TodayDashboardSnapshot {
        TodayDashboardSnapshot(
            today: repo.today,
            rest: restScore,
            liveHeartRate: model.bpm ?? live.heartRate,
            liveStrain: liveTodayStrain,
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
                primaryMetrics
                insight
                heartRateTrend
                stressEnergy
                biomarkers
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
        .task(id: repo.refreshSeq) { await loadDashboardData() }
#if os(macOS)
        .sheet(isPresented: $showingSleepDetail) {
            SleepDetailView()
                .environmentObject(repo)
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
#else
        .fullScreenCover(isPresented: $showingSleepDetail) {
            SleepDetailView()
                .environmentObject(repo)
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
                    recoveryCard
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityHint("Opens recovery details")
                Button { showingStrainDetail = true } label: {
                    strainCard
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityHint("Opens strain details")
            }
        }
    }

    private var recoveryCard: some View {
        MetricRingCard(
            title: "Recovery",
            value: snapshot.recoveryText,
            progress: snapshot.recovery.map { $0 / 100 },
            tint: snapshot.recovery.map(StrandPalette.recoveryColor) ?? StrandPalette.textTertiary,
            systemImage: "heart.fill",
            caption: snapshot.recovery == nil ? "Calibrating" : "readiness"
        )
    }

    private var sleepCard: some View {
        MetricRingCard(
            title: "Sleep",
            value: snapshot.restText,
            progress: snapshot.rest.map { $0 / 100 },
            tint: snapshot.rest.map { _ in StrandPalette.restColor } ?? StrandPalette.textTertiary,
            systemImage: "moon.stars.fill",
            caption: snapshot.rest == nil ? "Calibrating" : "rest score"
        )
    }

    private var strainCard: some View {
        MetricRingCard(
            title: "Strain",
            value: snapshot.strainText,
            progress: snapshot.strain.map { $0 / snapshot.strainScaleMax },
            tint: snapshot.strain.map { StrandPalette.strainColor($0 / snapshot.strainScaleMax * 100) } ?? StrandPalette.textTertiary,
            systemImage: "flame.fill",
            caption: snapshot.strain == nil ? "Calibrating" : "today"
        )
    }

    private var insight: some View {
        CompactInsightCard(
            title: snapshot.insightTitle,
            detail: snapshot.insightDetail,
            tint: snapshot.recovery.map(StrandPalette.recoveryColor) ?? StrandPalette.accent
        )
    }

    private var heartRateTrend: some View {
        TodayHeartRateTrendCard(points: hrPoints, liveHeartRate: snapshot.liveHeartRate)
    }

    private var stressEnergy: some View {
        Button { showingStressDetail = true } label: {
            StressEnergyCard(
                stress: snapshot.stressText,
                stressDetail: stressDetailText,
                energy: snapshot.energy.map { "\(Int($0.rounded()))" } ?? "--"
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens stress details")
    }

    private var biomarkers: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your signals")
                .font(StrandFont.headline)
                .foregroundStyle(StrandPalette.textPrimary)

            LazyVGrid(columns: biomarkerGrid, alignment: .leading, spacing: 10) {
                BiomarkerCard(
                    title: "Live HR",
                    value: snapshot.liveHeartRate.map(String.init) ?? "--",
                    unit: "bpm",
                    systemImage: "heart.fill",
                    tint: StrandPalette.metricRose,
                    detail: live.connected ? "Live from WHOOP" : "Strap disconnected"
                )
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
                    detail: "vs. baseline"
                )
                BiomarkerCard(
                    title: "SpO₂",
                    value: format(snapshot.spo2, decimals: 1),
                    unit: "%",
                    systemImage: "drop.fill",
                    tint: StrandPalette.metricCyan
                )
                BiomarkerCard(
                    title: "WHOOP Battery",
                    value: format(snapshot.battery, decimals: 0),
                    unit: "%",
                    systemImage: batterySymbol,
                    tint: batteryTint,
                    detail: live.charging == true ? "Charging" : nil
                )
                BiomarkerCard(
                    title: "Last Sync",
                    value: syncValue,
                    unit: "",
                    systemImage: "arrow.triangle.2.circlepath",
                    tint: StrandPalette.accent,
                    detail: live.backfilling ? "Syncing now" : "Strap history"
                )
            }
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
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
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
        let logicalDay = Repository.logicalDay(Date())
        let dayStart = Calendar.current.startOfDay(for: logicalDay)
        let windowStart = Int(dayStart.timeIntervalSince1970)
        let windowEnd = Int(Date().timeIntervalSince1970)

        hrPoints = await repo.hrBuckets(from: windowStart, to: windowEnd, bucketSeconds: 300)
            .map { TrendPoint(date: Date(timeIntervalSince1970: TimeInterval($0.ts)), value: $0.bpm) }

        let todayHr = await repo.hrSamples(from: windowStart, to: windowEnd)
        let maxHR = profile.age > 0 ? StrainScorer.tanakaHRmax(age: Double(profile.age)) : nil
        let restHR = repo.today?.restingHr.map(Double.init) ?? StrainScorer.defaultRestingHR
        liveTodayStrain = StrainScorer.strain(todayHr, maxHR: maxHR, restingHR: restHR, sex: profile.sex)

        let todayKey = repo.today?.day ?? Repository.localDayKey(logicalDay)
        let restSeries = await repo.exploreSeries(key: "sleep_performance", source: "my-whoop")
        restScore = Dictionary(restSeries.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })[todayKey]
        let stressSeries = await repo.series(key: "stress", source: "my-whoop")
        if let stressModel = StressModel(days: repo.days, stored: stressSeries) {
            stressScore = stressModel.score
            stressDetailText = stressModel.usingStored ? "Recorded daily stress" : "Estimated from HRV + resting HR"
        } else {
            stressScore = nil
            stressDetailText = "Calibrating"
        }
    }
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

import SwiftUI
import StrandDesign

struct TodayDashboardView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var live: LiveState
    @AppStorage("profile.firstName") private var firstName = "Adam"

    private let biomarkerGrid = [
        GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 10)
    ]

    private var snapshot: TodayDashboardSnapshot {
        TodayDashboardSnapshot(
            today: repo.today,
            liveHeartRate: model.bpm ?? live.heartRate,
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
                stressEnergy
                biomarkers
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: 1120)
            .frame(maxWidth: .infinity)
        }
        .background(background)
        .task { await repo.refresh() }
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
        StrandCard(padding: 14, cornerRadius: 18) {
            HStack(alignment: .top, spacing: 8) {
                sleepCard.frame(maxWidth: .infinity)
                recoveryCard.frame(maxWidth: .infinity)
                strainCard.frame(maxWidth: .infinity)
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
            caption: "readiness"
        )
    }

    private var sleepCard: some View {
        MetricRingCard(
            title: "Sleep",
            value: snapshot.sleepText,
            progress: snapshot.sleepMinutes.map { min($0 / (8 * 60), 1) },
            tint: StrandPalette.sleepREM,
            systemImage: "moon.stars.fill",
            caption: "last night"
        )
    }

    private var strainCard: some View {
        MetricRingCard(
            title: "Strain",
            value: snapshot.strainText,
            progress: snapshot.strain.map { $0 / 21 },
            tint: snapshot.strain.map { StrandPalette.strainColor($0 / 21 * 100) } ?? StrandPalette.textTertiary,
            systemImage: "flame.fill",
            caption: "today"
        )
    }

    private var insight: some View {
        CompactInsightCard(
            title: snapshot.insightTitle,
            detail: snapshot.insightDetail,
            tint: snapshot.recovery.map(StrandPalette.recoveryColor) ?? StrandPalette.accent
        )
    }

    private var stressEnergy: some View {
        // TODO: Bind Stress when a stable daily stress model is exposed by the core.
        StressEnergyCard(energy: snapshot.energy.map { "\(Int($0.rounded()))" } ?? "--")
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
}

#if DEBUG
#Preview("Today Dashboard") {
    let model = AppModel()
    return TodayDashboardView()
        .environmentObject(model)
        .environmentObject(model.repo)
        .environmentObject(model.live)
        .frame(width: 1100, height: 850)
        .preferredColorScheme(.dark)
}
#endif

import Foundation
import WhoopStore

/// Presentation-only snapshot for the consumer Today dashboard.
/// Keeps formatting and the WHOOP-style 0-21 strain conversion out of core models.
struct TodayDashboardSnapshot {
    let recovery: Double?
    let sleepMinutes: Double?
    let strain: Double?
    let liveHeartRate: Int?
    let restingHeartRate: Int?
    let hrv: Double?
    let respiratoryRate: Double?
    let skinTemperatureDeviation: Double?
    let spo2: Double?
    let stress: Double?
    let energy: Double?
    let battery: Double?
    let lastSync: TimeInterval?
    let strainScaleMax: Double

    init(
        today: DailyMetric?,
        liveHeartRate: Int?,
        liveStrain: Double?,
        stress: Double?,
        effortScale: EffortScale,
        battery: Double?,
        lastSync: TimeInterval?
    ) {
        recovery = today?.recovery
        sleepMinutes = today?.totalSleepMin
        // NOOP stores Effort on a 0-100 scale. Keep that source of truth and convert only for display.
        let effort = liveStrain ?? today?.strain
        strain = effort.map { UnitFormatter.effortValue(min(max($0, 0), 100), scale: effortScale) }
        strainScaleMax = effortScale == .whoop ? 21 : 100
        self.liveHeartRate = liveHeartRate
        restingHeartRate = today?.restingHr
        hrv = today?.avgHrv
        respiratoryRate = today?.respRateBpm
        skinTemperatureDeviation = today?.skinTempDevC
        spo2 = today?.spo2Pct
        self.stress = stress
        energy = today?.activeKcalEst
        self.battery = battery
        self.lastSync = lastSync
    }

    var recoveryText: String {
        recovery.map { "\(Int($0.rounded()))%" } ?? "--"
    }

    var sleepText: String {
        guard let sleepMinutes else { return "--" }
        let minutes = max(0, Int(sleepMinutes.rounded()))
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    var strainText: String {
        strain.map { String(format: "%.1f", $0) } ?? "--"
    }

    var stressText: String {
        stress.map { String(format: "%.1f", $0) } ?? "--"
    }

    var insightTitle: String {
        guard let recovery else { return "Your daily outlook is still building." }
        switch recovery {
        case ..<34: return "Your recovery is low."
        case ..<67: return "Your recovery is steady."
        default: return "Your recovery is solid."
        }
    }

    var insightDetail: String {
        guard let recovery else {
            return "Wear your strap through the night to unlock a personalized training recommendation."
        }
        switch recovery {
        case ..<34: return "Prioritize rest and keep movement easy today."
        case ..<67: return "A balanced training day will serve you well."
        default: return "Keep training moderate today."
        }
    }
}

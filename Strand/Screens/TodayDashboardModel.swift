import Foundation
import WhoopStore

/// Presentation-only snapshot for the consumer Today dashboard.
/// Keeps formatting and the WHOOP-style 0-21 strain conversion out of core models.
struct TodayDashboardSnapshot {
    let charge: Double?
    let rest: Double?
    let effort: Double?
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
        rest: Double?,
        liveHeartRate: Int?,
        liveStrain: Double?,
        stress: Double?,
        effortScale: EffortScale,
        battery: Double?,
        lastSync: TimeInterval?
    ) {
        charge = today?.recovery
        self.rest = rest
        // NOOP stores Effort on a 0-100 scale. Keep that source of truth and convert only for display.
        let effort = today?.strain ?? liveStrain
        self.effort = effort.map { UnitFormatter.effortValue(min(max($0, 0), 100), scale: effortScale) }
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

    var chargeText: String {
        charge.map { "\(Int($0.rounded()))%" } ?? "--"
    }

    var restText: String {
        rest.map { "\(Int($0.rounded()))%" } ?? "--"
    }

    var effortText: String {
        effort.map { String(format: "%.1f", $0) } ?? "--"
    }

    var stressText: String {
        stress.map { String(format: "%.1f", $0) } ?? "--"
    }

    var insightTitle: String {
        guard let charge else { return "Your Charge is still building." }
        switch charge {
        case ..<34: return "Your Charge is low."
        case ..<67: return "Your Charge is steady."
        default: return "Your Charge is solid."
        }
    }

    var insightDetail: String {
        guard let charge else {
            return "Wear your strap overnight to build your Rest and unlock Charge."
        }
        switch charge {
        case ..<34: return "Prioritize rest and keep movement easy today."
        case ..<67: return "A balanced training day will serve you well."
        default: return "Keep training moderate today."
        }
    }
}

import Foundation
import WhoopStore

struct RecoveryDetailSnapshot {
    let charge: Double?
    let restingHrv: Double?
    let restingHeartRate: Int?
    let respiratoryRate: Double?
    let oxygenSaturation: Double?
    let wristTemperature: Double?
    let totalSleepMinutes: Double?
    let date: Date

    init(today: DailyMetric?) {
        charge = today?.recovery
        restingHrv = today?.avgHrv
        restingHeartRate = today?.restingHr
        respiratoryRate = today?.respRateBpm
        oxygenSaturation = today?.spo2Pct
        wristTemperature = today?.skinTempDevC
        totalSleepMinutes = today?.totalSleepMin
        date = today.flatMap { Self.dayFormatter.date(from: $0.day) } ?? Date()
    }

    var chargeText: String {
        charge.map { "\(Int($0.rounded()))%" } ?? "--"
    }

    var chargeProgress: Double? {
        charge.map { min(max($0, 0), 100) / 100 }
    }

    var restingHrvText: String { whole(restingHrv) }
    var restingHeartRateText: String { restingHeartRate.map(String.init) ?? "--" }
    var respiratoryRateText: String { decimal(respiratoryRate) }
    var oxygenSaturationText: String { decimal(oxygenSaturation) }
    var wristTemperatureText: String {
        wristTemperature.map { String(format: "%+.1f", $0) } ?? "--"
    }

    var chargeCaption: String {
        charge == nil ? chargeUnavailableReason : "Readiness"
    }

    var dateLabel: String {
        let prefix = Calendar.current.isDateInToday(date)
            ? "Today"
            : date.formatted(.dateTime.weekday(.abbreviated))
        return "\(prefix), \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var coachMessage: String {
        guard let charge else {
            return chargeUnavailableCoachMessage
        }
        switch charge {
        case ..<34:
            return "Your Charge is low. Prioritize rest and keep movement easy today."
        case ..<67:
            return "Your Charge is steady. A balanced training day will serve you well."
        default:
            return "Your Charge is strong. Your body is ready for a productive day."
        }
    }

    var chargeUnavailableReason: String {
        if totalSleepMinutes == nil { return "Needs completed sleep" }
        if restingHrv == nil || restingHeartRate == nil { return "Missing overnight signals" }
        return "Building HRV baseline"
    }

    private var chargeUnavailableCoachMessage: String {
        switch chargeUnavailableReason {
        case "Needs completed sleep":
            return "No Charge yet. NOOP needs a completed sleep window before it can score today."
        case "Missing overnight signals":
            return "No Charge yet. Overnight HRV and resting heart rate were not available for this day."
        default:
            return "No Charge yet. NOOP is still building your personal HRV baseline from recent nights."
        }
    }

    private func whole(_ value: Double?) -> String {
        value.map { String(format: "%.0f", $0) } ?? "--"
    }

    private func decimal(_ value: Double?) -> String {
        value.map { String(format: "%.1f", $0) } ?? "--"
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

import Foundation
import WhoopStore

struct RecoveryDetailSnapshot {
    let recovery: Double?
    let restingHrv: Double?
    let restingHeartRate: Int?
    let respiratoryRate: Double?
    let oxygenSaturation: Double?
    let wristTemperature: Double?
    let date: Date

    init(today: DailyMetric?) {
        recovery = today?.recovery
        restingHrv = today?.avgHrv
        restingHeartRate = today?.restingHr
        respiratoryRate = today?.respRateBpm
        oxygenSaturation = today?.spo2Pct
        wristTemperature = today?.skinTempDevC
        date = today.flatMap { Self.dayFormatter.date(from: $0.day) } ?? Date()
    }

    var recoveryText: String {
        recovery.map { "\(Int($0.rounded()))%" } ?? "0%"
    }

    var recoveryProgress: Double? {
        recovery.map { min(max($0, 0), 100) / 100 }
    }

    var restingHrvText: String { whole(restingHrv) }
    var restingHeartRateText: String { restingHeartRate.map(String.init) ?? "--" }
    var respiratoryRateText: String { decimal(respiratoryRate) }
    var oxygenSaturationText: String { decimal(oxygenSaturation) }
    var wristTemperatureText: String {
        wristTemperature.map { String(format: "%+.1f", $0) } ?? "--"
    }

    var dateLabel: String {
        let prefix = Calendar.current.isDateInToday(date)
            ? "Today"
            : date.formatted(.dateTime.weekday(.abbreviated))
        return "\(prefix), \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var coachMessage: String {
        guard let recovery else {
            return "No recovery insight yet. Wear your strap overnight to build today’s recovery."
        }
        switch recovery {
        case ..<34:
            return "Your recovery is low. Prioritize rest and keep movement easy today."
        case ..<67:
            return "Your recovery is steady. A balanced training day will serve you well."
        default:
            return "Your recovery is strong. Your body is ready for a productive day."
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


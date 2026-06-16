import Foundation
import WhoopStore

struct StrainDetailSnapshot {
    let strain: Double?
    let durationSeconds: Double?
    let totalEnergy: Double?
    let steps: Int?
    let zoneMinutes: [Double]?
    let activities: [WorkoutRow]
    let date: Date

    init(today: DailyMetric?, workouts: [WorkoutRow]) {
        strain = today?.strain.map { min(max($0, 0), 100) * 21 / 100 }
        date = today.flatMap { Self.dayFormatter.date(from: $0.day) } ?? Date()

        let day = today?.day ?? Self.dayFormatter.string(from: date)
        activities = workouts
            .filter { Self.dayFormatter.string(from: Date(timeIntervalSince1970: TimeInterval($0.startTs))) == day }
            .sorted { $0.startTs > $1.startTs }

        let durations = activities.map { $0.durationS ?? Double(max($0.endTs - $0.startTs, 0)) }
            .filter { $0 > 0 }
        durationSeconds = durations.isEmpty ? nil : durations.reduce(0, +)

        let workoutEnergy = activities.compactMap(\.energyKcal)
        totalEnergy = today?.activeKcalEst ?? (workoutEnergy.isEmpty ? nil : workoutEnergy.reduce(0, +))
        steps = today?.steps
        zoneMinutes = WorkoutZones.summary(from: activities)?.minutes
    }

    var strainText: String {
        strain.map { String(format: "%.1f", $0) } ?? "0"
    }

    var strainProgress: Double? {
        strain.map { min(max($0, 0), 21) / 21 }
    }

    var statusText: String {
        strain == nil ? "No strain data" : "Today’s strain"
    }

    var targetStrainText: String { "--" }
    var durationText: String { Self.duration(durationSeconds) }
    var totalEnergyText: String { totalEnergy.map { String(format: "%.0f", $0) } ?? "--" }
    var stepsText: String {
        guard let steps else { return "--" }
        return Self.numberFormatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    var totalZoneMinutes: Double? {
        guard let zoneMinutes else { return nil }
        return zoneMinutes.reduce(0, +)
    }

    var totalZoneTimeText: String {
        totalZoneMinutes.map { "\(Int($0.rounded())) min" } ?? "0 min"
    }

    var dateLabel: String {
        let prefix = Calendar.current.isDateInToday(date)
            ? "Today"
            : date.formatted(.dateTime.weekday(.abbreviated))
        return "\(prefix), \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var coachMessage: String {
        guard let strain else {
            return "No strain insight yet. Capture heart-rate and activity data to build today’s strain."
        }
        return "Today’s strain is \(String(format: "%.1f", strain)). Review your activities and heart-rate zones to understand how it built."
    }

    func zoneText(_ index: Int) -> String {
        guard let zoneMinutes, zoneMinutes.indices.contains(index) else { return "--" }
        return String(format: "%.0f", zoneMinutes[index])
    }

    func activityDuration(_ activity: WorkoutRow) -> String {
        Self.duration(activity.durationS ?? Double(max(activity.endTs - activity.startTs, 0)))
    }

    private static func duration(_ seconds: Double?) -> String {
        guard let seconds, seconds > 0 else { return "--" }
        let minutes = Int((seconds / 60).rounded())
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

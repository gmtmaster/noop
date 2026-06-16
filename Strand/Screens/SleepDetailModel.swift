import Foundation
import WhoopStore

struct SleepDetailSnapshot {
    let quality: Double?
    let timeInBedMinutes: Double?
    let timeAsleepMinutes: Double?
    let date: Date

    init(today: DailyMetric?, session: CachedSleepSession?, importedPerformance: Double?) {
        quality = importedPerformance ?? today?.efficiency
        timeAsleepMinutes = today?.totalSleepMin
        if let session {
            timeInBedMinutes = Double(max(0, session.endTs - session.startTs)) / 60
            date = Date(timeIntervalSince1970: TimeInterval(session.endTs))
        } else {
            timeInBedMinutes = Self.estimatedTimeInBed(today)
            date = Date()
        }
    }

    var qualityText: String {
        quality.map { "\(Int($0.rounded()))%" } ?? "0%"
    }

    var timeInBedText: String {
        Self.duration(timeInBedMinutes)
    }

    var timeAsleepText: String {
        Self.duration(timeAsleepMinutes)
    }

    var coachMessage: String {
        guard let quality else { return "Sleep --. No sleep data" }
        if quality >= 85 { return "Sleep \(Int(quality.rounded())). You recovered well overnight." }
        if quality >= 70 { return "Sleep \(Int(quality.rounded())). A steady night with room to improve." }
        return "Sleep \(Int(quality.rounded())). Protect your wind-down tonight."
    }

    var dateLabel: String {
        let day = Calendar.current.isDateInToday(date) ? "Today" : date.formatted(.dateTime.weekday(.abbreviated))
        return "\(day), \(date.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private static func estimatedTimeInBed(_ today: DailyMetric?) -> Double? {
        guard let asleep = today?.totalSleepMin,
              let efficiency = today?.efficiency,
              efficiency > 0 else { return nil }
        return asleep / (efficiency / 100)
    }

    private static func duration(_ minutes: Double?) -> String {
        guard let minutes, minutes > 0 else { return "No data" }
        let rounded = Int(minutes.rounded())
        return "\(rounded / 60)h \(rounded % 60)m"
    }
}

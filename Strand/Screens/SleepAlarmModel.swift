import Foundation

enum SleepAlarmMode: String, CaseIterable, Identifiable {
    case smart = "Smart"
    case regular = "Regular"
    case needed = "Needed"
    case off = "Off"

    var id: String { rawValue }

    var explanation: String {
        switch self {
        case .smart:
            return "Wake during a lighter sleep stage near your target time."
        case .regular:
            return "Wake at the selected time using the band’s firmware alarm."
        case .needed:
            return "Choose a wake time from your nightly sleep-need target."
        case .off:
            return "Disable the alarm currently stored on your band."
        }
    }

    /// The existing NOOP core supports only a fixed firmware alarm and disabling it.
    var isSupportedByCore: Bool {
        self == .regular || self == .off
    }
}

struct SleepAlarmDraft {
    var wakeMinutes: Int = 7 * 60
    var mode: SleepAlarmMode = .smart
    var targetMinutes: Int = 7 * 60 + 30

    var wakeDate: Date {
        get {
            Calendar.current.date(
                bySettingHour: wakeMinutes / 60,
                minute: wakeMinutes % 60,
                second: 0,
                of: Date()
            ) ?? Date()
        }
        set {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            wakeMinutes = (parts.hour ?? 7) * 60 + (parts.minute ?? 0)
        }
    }

    var targetText: String {
        "\(targetMinutes / 60)h \(targetMinutes % 60)m"
    }

    mutating func adjustTarget(by minutes: Int) {
        targetMinutes = min(max(targetMinutes + minutes, 4 * 60), 12 * 60)
    }
}

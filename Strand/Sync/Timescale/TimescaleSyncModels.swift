import Foundation

enum TimescaleSyncInterval: Int, CaseIterable, Identifiable {
    case manual = 0
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1_800
    case oneHour = 3_600

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .manual: return "Manual only"
        case .fiveMinutes: return "Every 5 minutes"
        case .fifteenMinutes: return "Every 15 minutes"
        case .thirtyMinutes: return "Every 30 minutes"
        case .oneHour: return "Every 1 hour"
        }
    }

    var seconds: TimeInterval? {
        rawValue > 0 ? TimeInterval(rawValue) : nil
    }
}

struct TimescaleSyncProfile: Equatable {
    var enabled: Bool
    var serverURL: String
    var userID: String
    var deviceID: String
    var displayName: String
    var interval: TimescaleSyncInterval

    var isConfigured: Bool {
        UUID(uuidString: userID.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
            && URL(string: serverURL.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
            && !deviceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func defaults(deviceID: String) -> TimescaleSyncProfile {
        TimescaleSyncProfile(
            enabled: false,
            serverURL: "",
            userID: "",
            deviceID: deviceID,
            displayName: "",
            interval: .fifteenMinutes)
    }
}

enum TimescaleSyncStatus: String {
    case idle = "Idle"
    case syncing = "Syncing..."
    case succeeded = "Succeeded"
    case failed = "Failed"
    case notConfigured = "Not configured"
}

struct TimescaleSyncResult: Decodable {
    let userId: String
    let deviceId: String
    let samples: Int
    let rawSamples: Int
    let dailyMetrics: Int
    let sleepSessions: Int
    let workouts: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case deviceId = "device_id"
        case samples
        case rawSamples = "raw_samples"
        case dailyMetrics = "daily_metrics"
        case sleepSessions = "sleep_sessions"
        case workouts
    }

    var summary: String {
        "Synced \(samples) samples, \(rawSamples) raw, \(dailyMetrics) daily, \(sleepSessions) sleep, \(workouts) workouts"
    }
}

enum TimescaleJSONValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: TimescaleJSONValue])
    case array([TimescaleJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: TimescaleJSONValue].self) {
            self = .object(value)
        } else {
            self = .array(try container.decode([TimescaleJSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    static func parsedObject(from json: String?) -> [String: TimescaleJSONValue]? {
        guard let json,
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
        return TimescaleJSONValue(any: object).objectValue
    }

    private init(any: Any) {
        switch any {
        case let dict as [String: Any]:
            self = .object(dict.mapValues { TimescaleJSONValue(any: $0) })
        case let array as [Any]:
            self = .array(array.map { TimescaleJSONValue(any: $0) })
        case let value as String:
            self = .string(value)
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                self = .bool(value.boolValue)
            } else {
                self = .number(value.doubleValue)
            }
        default:
            self = .null
        }
    }

    private var objectValue: [String: TimescaleJSONValue]? {
        if case .object(let object) = self { return object }
        return nil
    }
}

struct TimescaleSyncBatch: Encodable {
    let userID: String
    let device: DeviceIdentity
    var samples: [MetricSample] = []
    var rawSamples: [RawSample] = []
    var dailyMetrics: [DailyMetricPayload] = []
    var sleepSessions: [SleepSessionPayload] = []
    var workouts: [WorkoutPayload] = []
    var cursorUpdates: [String: Int] = [:]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case device
        case samples
        case rawSamples = "raw_samples"
        case dailyMetrics = "daily_metrics"
        case sleepSessions = "sleep_sessions"
        case workouts
    }

    struct DeviceIdentity: Encodable {
        let deviceID: String
        let name: String?
        let model: String?
        let firmwareVersion: String?

        enum CodingKeys: String, CodingKey {
            case deviceID = "device_id"
            case name
            case model
            case firmwareVersion = "firmware_version"
        }
    }

    struct MetricSample: Encodable {
        let metricKey: String
        let timestamp: Date
        let value: Double
        let unit: String?
        let source: String
        let quality: [String: TimescaleJSONValue]?
        let raw: [String: TimescaleJSONValue]?

        enum CodingKeys: String, CodingKey {
            case metricKey = "metric_key"
            case timestamp
            case value
            case unit
            case source
            case quality
            case raw
        }
    }

    struct RawSample: Encodable {
        let streamKey: String
        let timestamp: Date
        let payload: [String: TimescaleJSONValue]
        let source: String

        enum CodingKeys: String, CodingKey {
            case streamKey = "stream_key"
            case timestamp
            case payload
            case source
        }
    }

    struct DailyMetricPayload: Encodable {
        let day: String
        let metricKey: String
        let value: Double
        let unit: String?
        let source: String
        let quality: [String: TimescaleJSONValue]?

        enum CodingKeys: String, CodingKey {
            case day
            case metricKey = "metric_key"
            case value
            case unit
            case source
            case quality
        }
    }

    struct SleepSessionPayload: Encodable {
        let startTime: Date
        let endTime: Date
        let source: String
        let totalSleepMin: Double?
        let efficiency: Double?
        let restingHR: Int?
        let avgHRVMS: Double?
        let recovery: Double?
        let strain: Double?
        let stages: [String: TimescaleJSONValue]?

        enum CodingKeys: String, CodingKey {
            case startTime = "start_time"
            case endTime = "end_time"
            case source
            case totalSleepMin = "total_sleep_min"
            case efficiency
            case restingHR = "resting_hr"
            case avgHRVMS = "avg_hrv_ms"
            case recovery
            case strain
            case stages
        }
    }

    struct WorkoutPayload: Encodable {
        let startTime: Date
        let endTime: Date
        let sport: String
        let source: String
        let durationS: Double?
        let energyKcal: Double?
        let avgHR: Int?
        let maxHR: Int?
        let strain: Double?
        let distanceM: Double?
        let zones: [String: TimescaleJSONValue]?
        let notes: String?

        enum CodingKeys: String, CodingKey {
            case startTime = "start_time"
            case endTime = "end_time"
            case sport
            case source
            case durationS = "duration_s"
            case energyKcal = "energy_kcal"
            case avgHR = "avg_hr"
            case maxHR = "max_hr"
            case strain
            case distanceM = "distance_m"
            case zones
            case notes
        }
    }

    var isEmpty: Bool {
        samples.isEmpty && rawSamples.isEmpty && dailyMetrics.isEmpty
            && sleepSessions.isEmpty && workouts.isEmpty
    }

    var maxTimestamp: Int {
        let sampleMax = samples.map { Int($0.timestamp.timeIntervalSince1970) }.max() ?? 0
        let rawMax = rawSamples.map { Int($0.timestamp.timeIntervalSince1970) }.max() ?? 0
        let sleepMax = sleepSessions.map { Int($0.startTime.timeIntervalSince1970) }.max() ?? 0
        let workoutMax = workouts.map { Int($0.startTime.timeIntervalSince1970) }.max() ?? 0
        let dailyMax = dailyMetrics.compactMap { TimescaleSyncBatch.dayTimestamp($0.day) }.max() ?? 0
        return max(sampleMax, rawMax, sleepMax, workoutMax, dailyMax)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func dayTimestamp(_ day: String) -> Int? {
        dayFormatter.date(from: day).map { Int($0.timeIntervalSince1970) }
    }
}

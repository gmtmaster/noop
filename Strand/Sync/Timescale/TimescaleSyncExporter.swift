import Foundation
import WhoopStore
import WhoopProtocol

@MainActor
struct TimescaleSyncExporter {
    private let repo: Repository
    private let settings: TimescaleSyncSettingsStore
    private let batchLimit = 6_000

    init(repo: Repository, settings: TimescaleSyncSettingsStore) {
        self.repo = repo
        self.settings = settings
    }

    func buildBatch(fullResync: Bool = false) async -> TimescaleSyncBatch {
        let profile = settings.profile
        let now = Int(Date().timeIntervalSince1970)
        var batch = TimescaleSyncBatch(
            userID: profile.userID.trimmingCharacters(in: .whitespacesAndNewlines),
            device: TimescaleSyncBatch.DeviceIdentity(
                deviceID: profile.deviceID.trimmingCharacters(in: .whitespacesAndNewlines),
                name: profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                model: nil,
                firmwareVersion: nil))

        guard let store = await repo.storeHandle() else { return batch }
        await appendRawStreams(to: &batch, store: store, now: now, fullResync: fullResync)
        await appendDailyMetrics(to: &batch, store: store, now: now, fullResync: fullResync)
        await appendSleep(to: &batch, now: now, fullResync: fullResync)
        await appendWorkouts(to: &batch, now: now, fullResync: fullResync)
        return batch
    }

    func commitCursors(for batch: TimescaleSyncBatch) {
        for (stream, cursor) in batch.cursorUpdates where cursor > 0 {
            settings.setCursor(cursor, for: stream)
        }
        if let latestDay = batch.dailyMetrics.map(\.day).max(),
           let dayTs = Self.timestamp(forDay: latestDay) {
            settings.setCursor(dayTs, for: "daily")
            settings.setCursor(dayTs, for: "metricSeries")
        }
    }

    private func appendRawStreams(to batch: inout TimescaleSyncBatch,
                                  store: WhoopStore,
                                  now: Int,
                                  fullResync: Bool) async {
        let deviceId = repo.deviceId
        if batch.samples.count < batchLimit {
            let from = nextTs("heartRate", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.hrSamples(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            batch.samples += rows.map {
                sample("heart_rate", ts: $0.ts, value: Double($0.bpm), unit: "bpm", source: "whoop")
            }
            recordCursor("heartRate", rows.map(\.ts), in: &batch)
        }
        if batch.samples.count < batchLimit {
            let from = nextTs("rrIntervals", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.rrIntervals(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            batch.samples += rows.map {
                sample("rr_interval", ts: $0.ts, value: Double($0.rrMs), unit: "ms", source: "whoop")
            }
            recordCursor("rrIntervals", rows.map(\.ts), in: &batch)
        }
        if batch.samples.count < batchLimit {
            let from = nextTs("battery", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.batterySamples(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            for row in rows {
                if let soc = row.soc {
                    batch.samples.append(sample("battery_soc", ts: row.ts, value: soc, unit: "%", source: "whoop"))
                }
                if let mv = row.mv {
                    batch.samples.append(sample("battery_voltage", ts: row.ts, value: Double(mv), unit: "mV", source: "whoop"))
                }
                if let charging = row.charging {
                    batch.rawSamples.append(raw("battery_state", ts: row.ts, payload: ["charging": .bool(charging)]))
                }
            }
            recordCursor("battery", rows.map(\.ts), in: &batch)
        }
        if batch.rawSamples.count < batchLimit {
            let from = nextTs("spo2Optical", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.spo2Samples(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            batch.rawSamples += rows.map {
                raw("spo2_optical", ts: $0.ts, payload: [
                    "red": .number(Double($0.red)),
                    "ir": .number(Double($0.ir))
                ])
            }
            recordCursor("spo2Optical", rows.map(\.ts), in: &batch)
        }
        if batch.samples.count < batchLimit {
            let from = nextTs("skinTempRaw", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.skinTempSamples(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            batch.samples += rows.map {
                sample("skin_temperature_raw", ts: $0.ts, value: Double($0.raw), unit: nil, source: "whoop")
            }
            recordCursor("skinTempRaw", rows.map(\.ts), in: &batch)
        }
        if batch.samples.count < batchLimit {
            let from = nextTs("respRaw", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.respSamples(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            batch.samples += rows.map {
                sample("respiration_raw", ts: $0.ts, value: Double($0.raw), unit: nil, source: "whoop")
            }
            recordCursor("respRaw", rows.map(\.ts), in: &batch)
        }
        if batch.samples.count < batchLimit {
            let from = nextTs("stepsRaw", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.stepSamples(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            batch.samples += rows.map {
                sample("step_counter", ts: $0.ts, value: Double($0.counter), unit: "count", source: "whoop")
            }
            recordCursor("stepsRaw", rows.map(\.ts), in: &batch)
        }
        if batch.rawSamples.count < batchLimit {
            let from = nextTs("gravity", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.gravitySamples(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            batch.rawSamples += rows.map {
                raw("gravity", ts: $0.ts, payload: [
                    "x": .number(Double($0.x)),
                    "y": .number(Double($0.y)),
                    "z": .number(Double($0.z))
                ])
            }
            recordCursor("gravity", rows.map(\.ts), in: &batch)
        }
        if batch.rawSamples.count < batchLimit {
            let from = nextTs("events", fallbackDays: 365, fullResync: fullResync)
            let rows = (try? await store.events(deviceId: deviceId, from: from, to: now, limit: remaining(batch))) ?? []
            batch.rawSamples += rows.map {
                raw("whoop_event", ts: $0.ts, payload: [
                    "kind": .string($0.kind),
                    "payload": .string(String(describing: $0.payload))
                ])
            }
            recordCursor("events", rows.map(\.ts), in: &batch)
        }
    }

    private func appendDailyMetrics(to batch: inout TimescaleSyncBatch,
                                    store: WhoopStore,
                                    now: Int,
                                    fullResync: Bool) async {
        let fromDay = Self.dayString(from: nextTs("daily", fallbackDays: 4_000, fullResync: fullResync))
        let toDay = Self.dayString(from: now + 86_400)
        let rows = await repo.dailyMetrics(fromDay: fromDay, toDay: toDay)
        for row in rows {
            addDaily(row.totalSleepMin, key: "total_sleep_min", unit: "min", day: row.day, to: &batch)
            addDaily(row.efficiency, key: "sleep_efficiency", unit: "%", day: row.day, to: &batch)
            addDaily(row.deepMin, key: "deep_sleep_min", unit: "min", day: row.day, to: &batch)
            addDaily(row.remMin, key: "rem_sleep_min", unit: "min", day: row.day, to: &batch)
            addDaily(row.lightMin, key: "light_sleep_min", unit: "min", day: row.day, to: &batch)
            addDaily(row.disturbances.map(Double.init), key: "sleep_disturbances", unit: "count", day: row.day, to: &batch)
            addDaily(row.restingHr.map(Double.init), key: "resting_heart_rate", unit: "bpm", day: row.day, to: &batch)
            addDaily(row.avgHrv, key: "hrv_rmssd", unit: "ms", day: row.day, to: &batch)
            addDaily(row.recovery, key: "recovery", unit: "%", day: row.day, to: &batch)
            addDaily(row.strain, key: "strain", unit: nil, day: row.day, to: &batch)
            addDaily(row.exerciseCount.map(Double.init), key: "exercise_count", unit: "count", day: row.day, to: &batch)
            addDaily(row.spo2Pct, key: "spo2", unit: "%", day: row.day, to: &batch)
            addDaily(row.skinTempDevC, key: "skin_temperature_deviation", unit: "C", day: row.day, to: &batch)
            addDaily(row.respRateBpm, key: "respiratory_rate", unit: "breaths/min", day: row.day, to: &batch)
            addDaily(row.steps.map(Double.init), key: "steps", unit: "count", day: row.day, to: &batch)
            addDaily(row.activeKcalEst, key: "active_kcal_estimate", unit: "kcal", day: row.day, to: &batch)
        }

        for device in [repo.deviceId, "\(repo.deviceId)-noop", "apple-health"] {
            let keys = (try? await store.metricKeys(deviceId: device)) ?? []
            for key in keys {
                let points = (try? await store.metricSeries(deviceId: device, key: key, from: fromDay, to: toDay)) ?? []
                batch.dailyMetrics += points.map {
                    TimescaleSyncBatch.DailyMetricPayload(
                        day: $0.day,
                        metricKey: $0.key,
                        value: $0.value,
                        unit: nil,
                        source: device,
                        quality: ["source_device_id": .string(device)])
                }
            }
        }

        let appleRows = await repo.appleDailyRows()
        for row in appleRows where row.day >= fromDay {
            addDaily(row.steps.map(Double.init), key: "apple_steps", unit: "count", day: row.day, source: "apple-health", to: &batch)
            addDaily(row.activeKcal, key: "apple_active_kcal", unit: "kcal", day: row.day, source: "apple-health", to: &batch)
            addDaily(row.basalKcal, key: "apple_basal_kcal", unit: "kcal", day: row.day, source: "apple-health", to: &batch)
            addDaily(row.vo2max, key: "apple_vo2max", unit: "ml/kg/min", day: row.day, source: "apple-health", to: &batch)
            addDaily(row.avgHr.map(Double.init), key: "apple_avg_heart_rate", unit: "bpm", day: row.day, source: "apple-health", to: &batch)
            addDaily(row.maxHr.map(Double.init), key: "apple_max_heart_rate", unit: "bpm", day: row.day, source: "apple-health", to: &batch)
            addDaily(row.walkingHr.map(Double.init), key: "apple_walking_heart_rate", unit: "bpm", day: row.day, source: "apple-health", to: &batch)
            addDaily(row.weightKg, key: "apple_weight", unit: "kg", day: row.day, source: "apple-health", to: &batch)
        }
    }

    private func appendSleep(to batch: inout TimescaleSyncBatch, now: Int, fullResync: Bool) async {
        let from = nextTs("sleep", fallbackDays: 4_000, fullResync: fullResync)
        let sessions = await repo.allSleepSessions()
        for session in sessions where session.effectiveStartTs >= from {
            batch.sleepSessions.append(TimescaleSyncBatch.SleepSessionPayload(
                startTime: Date(timeIntervalSince1970: TimeInterval(session.effectiveStartTs)),
                endTime: Date(timeIntervalSince1970: TimeInterval(session.endTs)),
                source: session.userEdited ? "noop-edited" : "noop",
                totalSleepMin: max(0, Double(session.endTs - session.effectiveStartTs) / 60.0),
                efficiency: session.efficiency,
                restingHR: session.restingHr,
                avgHRVMS: session.avgHrv,
                recovery: nil,
                strain: nil,
                stages: TimescaleJSONValue.parsedObject(from: session.stagesJSON)
                    ?? session.stagesJSON.map { ["stages_json": .string($0)] }))
        }
        recordCursor("sleep", batch.sleepSessions.map { Int($0.startTime.timeIntervalSince1970) }, in: &batch)
    }

    private func appendWorkouts(to batch: inout TimescaleSyncBatch, now: Int, fullResync: Bool) async {
        let from = nextTs("workouts", fallbackDays: 4_000, fullResync: fullResync)
        let workouts = await repo.workoutRows()
        for row in workouts where row.startTs >= from {
            batch.workouts.append(TimescaleSyncBatch.WorkoutPayload(
                startTime: Date(timeIntervalSince1970: TimeInterval(row.startTs)),
                endTime: Date(timeIntervalSince1970: TimeInterval(row.endTs)),
                sport: row.sport,
                source: row.source,
                durationS: row.durationS,
                energyKcal: row.energyKcal,
                avgHR: row.avgHr,
                maxHR: row.maxHr,
                strain: row.strain,
                distanceM: row.distanceM,
                zones: TimescaleJSONValue.parsedObject(from: row.zonesJSON)
                    ?? row.zonesJSON.map { ["zones_json": .string($0)] },
                notes: row.notes))
        }
        recordCursor("workouts", batch.workouts.map { Int($0.startTime.timeIntervalSince1970) }, in: &batch)
    }

    private func sample(_ key: String,
                        ts: Int,
                        value: Double,
                        unit: String?,
                        source: String) -> TimescaleSyncBatch.MetricSample {
        TimescaleSyncBatch.MetricSample(
            metricKey: key,
            timestamp: Date(timeIntervalSince1970: TimeInterval(ts)),
            value: value,
            unit: unit,
            source: source,
            quality: nil,
            raw: nil)
    }

    private func raw(_ key: String,
                     ts: Int,
                     payload: [String: TimescaleJSONValue]) -> TimescaleSyncBatch.RawSample {
        TimescaleSyncBatch.RawSample(
            streamKey: key,
            timestamp: Date(timeIntervalSince1970: TimeInterval(ts)),
            payload: payload,
            source: "whoop")
    }

    private func addDaily(_ value: Double?,
                          key: String,
                          unit: String?,
                          day: String,
                          source: String = "noop",
                          to batch: inout TimescaleSyncBatch) {
        guard let value else { return }
        batch.dailyMetrics.append(TimescaleSyncBatch.DailyMetricPayload(
            day: day,
            metricKey: key,
            value: value,
            unit: unit,
            source: source,
            quality: nil))
    }

    private func nextTs(_ stream: String, fallbackDays: Int, fullResync: Bool) -> Int {
        if fullResync {
            return Int(Date().timeIntervalSince1970) - fallbackDays * 86_400
        }
        let saved = settings.cursor(for: stream)
        if saved > 0 { return saved + 1 }
        return Int(Date().timeIntervalSince1970) - fallbackDays * 86_400
    }

    private func remaining(_ batch: TimescaleSyncBatch) -> Int {
        max(0, batchLimit - batch.samples.count - batch.rawSamples.count)
    }

    private func recordCursor(_ stream: String, _ timestamps: [Int], in batch: inout TimescaleSyncBatch) {
        guard let maxTs = timestamps.max(), maxTs > 0 else { return }
        batch.cursorUpdates[stream] = max(batch.cursorUpdates[stream] ?? 0, maxTs)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func dayString(from timestamp: Int) -> String {
        dayFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
    }

    private static func timestamp(forDay day: String) -> Int? {
        dayFormatter.date(from: day).map { Int($0.timeIntervalSince1970) }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

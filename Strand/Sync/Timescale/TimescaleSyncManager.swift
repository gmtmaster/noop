import Combine
import Foundation

@MainActor
final class TimescaleSyncManager: ObservableObject {
    @Published var settings: TimescaleSyncSettingsStore
    @Published private(set) var isSyncing = false
    @Published var bannerMessage: String?

    private let repo: Repository
    private let client: TimescaleSyncClient
    private var periodicTask: Task<Void, Never>?

    init(repo: Repository,
         defaultDeviceID: String,
         client: TimescaleSyncClient = TimescaleSyncClient()) {
        self.repo = repo
        self.client = client
        self.settings = TimescaleSyncSettingsStore(defaultDeviceID: defaultDeviceID)
    }

    deinit {
        periodicTask?.cancel()
    }

    func startPeriodicChecks() {
        periodicTask?.cancel()
        periodicTask = Task { [weak self] in
            await self?.syncIfDue(reason: "launch")
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await self?.syncIfDue(reason: "interval")
            }
        }
    }

    func syncIfDue(reason: String) async {
        guard settings.shouldSync() else { return }
        await syncNow(reason: reason)
    }

    func syncNow(reason: String = "manual", fullResync: Bool = false) async {
        guard !isSyncing else { return }
        guard validateConfiguration() else { return }
        isSyncing = true
        settings.markAttempt()
        defer { isSyncing = false }

        do {
            let exporter = TimescaleSyncExporter(repo: repo, settings: settings)
            let batch = await exporter.buildBatch(fullResync: fullResync)
            guard !batch.isEmpty else {
                settings.markSuccess(summary: "No new local data to sync.")
                bannerMessage = "No new local data to sync."
                return
            }
            let result = try await client.send(
                batch,
                serverURL: settings.profile.serverURL,
                bearerToken: settings.token)
            exporter.commitCursors(for: batch)
            settings.markSuccess(summary: result.summary)
            bannerMessage = result.summary
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            settings.markFailure(message)
            bannerMessage = message
        }
    }

    func testConnection() async {
        guard validateConfiguration(requireToken: false) else { return }
        isSyncing = true
        settings.markAttempt()
        defer { isSyncing = false }

        do {
            try await client.testConnection(
                serverURL: settings.profile.serverURL,
                bearerToken: settings.token)
            settings.lastStatus = .succeeded
            settings.lastErrorMessage = ""
            settings.lastSummary = "Connection OK"
            bannerMessage = "Connection OK"
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            settings.markFailure(message)
            bannerMessage = message
        }
    }

    func saveTokenDraft() {
        settings.saveTokenDraft()
    }

    func clearToken() {
        settings.clearToken()
    }

    private func validateConfiguration(requireToken: Bool = true) -> Bool {
        guard settings.profile.isConfigured else {
            settings.lastStatus = .notConfigured
            settings.lastErrorMessage = "Server URL, user UUID and device ID are required."
            bannerMessage = settings.lastErrorMessage
            return false
        }
        guard !requireToken || settings.tokenStored else {
            settings.lastStatus = .notConfigured
            settings.lastErrorMessage = "Save a bearer token before syncing."
            bannerMessage = settings.lastErrorMessage
            return false
        }
        return true
    }
}

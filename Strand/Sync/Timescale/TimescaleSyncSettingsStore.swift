import Combine
import Foundation
import Security

@MainActor
final class TimescaleSyncSettingsStore: ObservableObject {
    @Published var profile: TimescaleSyncProfile {
        didSet { saveProfile() }
    }
    @Published var tokenDraft: String = ""
    @Published private(set) var tokenStored: Bool
    @Published var lastSuccessfulSync: Date? {
        didSet { saveDate(lastSuccessfulSync, key: Keys.lastSuccessfulSync) }
    }
    @Published var lastAttemptedSync: Date? {
        didSet { saveDate(lastAttemptedSync, key: Keys.lastAttemptedSync) }
    }
    @Published var lastStatus: TimescaleSyncStatus {
        didSet { defaults.set(lastStatus.rawValue, forKey: Keys.lastStatus) }
    }
    @Published var lastErrorMessage: String {
        didSet { defaults.set(lastErrorMessage, forKey: Keys.lastErrorMessage) }
    }
    @Published var lastSummary: String {
        didSet { defaults.set(lastSummary, forKey: Keys.lastSummary) }
    }

    private let defaults: UserDefaults
    private let tokenStore: TimescaleTokenStore

    init(defaultDeviceID: String,
         defaults: UserDefaults = .standard,
         tokenStore: TimescaleTokenStore = TimescaleTokenStore()) {
        self.defaults = defaults
        self.tokenStore = tokenStore
        self.profile = TimescaleSyncProfile(
            enabled: defaults.object(forKey: Keys.enabled) as? Bool ?? false,
            serverURL: defaults.string(forKey: Keys.serverURL) ?? "",
            userID: defaults.string(forKey: Keys.userID) ?? "",
            deviceID: defaults.string(forKey: Keys.deviceID) ?? defaultDeviceID,
            displayName: defaults.string(forKey: Keys.displayName) ?? "",
            interval: TimescaleSyncInterval(rawValue: defaults.integer(forKey: Keys.interval)) ?? .fifteenMinutes)
        self.tokenStored = tokenStore.readToken()?.isEmpty == false
        self.lastSuccessfulSync = Self.readDate(defaults, key: Keys.lastSuccessfulSync)
        self.lastAttemptedSync = Self.readDate(defaults, key: Keys.lastAttemptedSync)
        self.lastStatus = defaults.string(forKey: Keys.lastStatus).flatMap(TimescaleSyncStatus.init(rawValue:)) ?? .idle
        self.lastErrorMessage = defaults.string(forKey: Keys.lastErrorMessage) ?? ""
        self.lastSummary = defaults.string(forKey: Keys.lastSummary) ?? ""
    }

    var token: String? {
        tokenStore.readToken()
    }

    var hasTokenForAction: Bool {
        tokenStored || !tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var serverURLValidationMessage: String? {
        TimescaleSyncURL.validationMessage(for: profile.serverURL)
    }

    var hasValidServerURL: Bool {
        serverURLValidationMessage == nil
    }

    var hasValidUserID: Bool {
        UUID(uuidString: profile.userID.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    var hasDeviceID: Bool {
        !profile.deviceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canTestConnection: Bool {
        hasValidServerURL && hasTokenForAction
    }

    var canSyncNow: Bool {
        hasValidServerURL && hasTokenForAction && hasValidUserID && hasDeviceID
    }

    var validationMessages: [String] {
        var messages: [String] = []
        if let serverURLValidationMessage {
            messages.append(serverURLValidationMessage)
        }
        if !hasTokenForAction {
            messages.append("Paste and save a bearer token.")
        }
        if !hasValidUserID {
            messages.append("Enter a valid user UUID before syncing.")
        }
        if !hasDeviceID {
            messages.append("Enter a device ID before syncing.")
        }
        return messages
    }

    var testDisabledReason: String? {
        guard !canTestConnection else { return nil }
        if let serverURLValidationMessage { return serverURLValidationMessage }
        if !hasTokenForAction { return "Test needs a bearer token." }
        return nil
    }

    var syncDisabledReason: String? {
        guard !canSyncNow else { return nil }
        return validationMessages.first
    }

    @discardableResult
    func saveTokenDraft() -> Bool {
        let trimmed = tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return tokenStored }
        guard tokenStore.save(trimmed) else { return false }
        tokenDraft = ""
        tokenStored = true
        return true
    }

    func clearToken() {
        tokenStore.clear()
        tokenDraft = ""
        tokenStored = false
    }

    func cursor(for stream: String) -> Int {
        defaults.integer(forKey: cursorKey(stream))
    }

    func setCursor(_ value: Int, for stream: String) {
        defaults.set(value, forKey: cursorKey(stream))
    }

    func resetCursors() {
        let prefix = cursorPrefix
        for (key, _) in defaults.dictionaryRepresentation() where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    func shouldSync(now: Date = Date()) -> Bool {
        guard profile.enabled,
              canSyncNow,
              let seconds = profile.interval.seconds else { return false }
        guard let last = lastAttemptedSync else { return true }
        return now.timeIntervalSince(last) >= seconds
    }

    func markAttempt() {
        lastAttemptedSync = Date()
        lastStatus = .syncing
        lastErrorMessage = ""
    }

    func markSuccess(summary: String) {
        lastSuccessfulSync = Date()
        lastStatus = .succeeded
        lastErrorMessage = ""
        lastSummary = summary
    }

    func markFailure(_ message: String) {
        lastStatus = .failed
        lastErrorMessage = message
    }

    private func saveProfile() {
        defaults.set(profile.enabled, forKey: Keys.enabled)
        defaults.set(profile.serverURL, forKey: Keys.serverURL)
        defaults.set(profile.userID, forKey: Keys.userID)
        defaults.set(profile.deviceID, forKey: Keys.deviceID)
        defaults.set(profile.displayName, forKey: Keys.displayName)
        defaults.set(profile.interval.rawValue, forKey: Keys.interval)
    }

    private func cursorKey(_ stream: String) -> String {
        "\(cursorPrefix).\(stream)"
    }

    private var cursorPrefix: String {
        let scoped = "\(profile.userID).\(profile.deviceID)"
        let safe = scoped.map { $0.isLetter || $0.isNumber ? $0 : "_" }
        return "\(Keys.cursorPrefix).\(String(safe))"
    }

    private func saveDate(_ date: Date?, key: String) {
        if let date {
            defaults.set(date.timeIntervalSince1970, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private static func readDate(_ defaults: UserDefaults, key: String) -> Date? {
        guard defaults.object(forKey: key) != nil else { return nil }
        return Date(timeIntervalSince1970: defaults.double(forKey: key))
    }

    private enum Keys {
        static let enabled = "timescale.sync.enabled"
        static let serverURL = "timescale.sync.serverURL"
        static let userID = "timescale.sync.userID"
        static let deviceID = "timescale.sync.deviceID"
        static let displayName = "timescale.sync.displayName"
        static let interval = "timescale.sync.interval"
        static let lastSuccessfulSync = "timescale.sync.lastSuccessfulSync"
        static let lastAttemptedSync = "timescale.sync.lastAttemptedSync"
        static let lastStatus = "timescale.sync.lastStatus"
        static let lastErrorMessage = "timescale.sync.lastErrorMessage"
        static let lastSummary = "timescale.sync.lastSummary"
        static let cursorPrefix = "timescale.sync.cursor"
    }
}

struct TimescaleTokenStore {
    private let service = "com.noop.timescale-sync"
    private let account = "bearer-token"

    @discardableResult
    func save(_ token: String) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        SecItemDelete(baseQuery as CFDictionary)
        var attrs = baseQuery
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(attrs as CFDictionary, nil) == errSecSuccess
    }

    func readToken() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else { return nil }
        return token
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

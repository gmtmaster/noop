import SwiftUI
import StrandDesign

struct TimescaleSyncSettingsView: View {
    @ObservedObject var manager: TimescaleSyncManager
    @ObservedObject private var settings: TimescaleSyncSettingsStore
    @State private var confirmFullResync = false

    init(manager: TimescaleSyncManager) {
        self.manager = manager
        self.settings = manager.settings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(isOn: profileBinding(\.enabled)) {
                Text("Enable sync")
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrandPalette.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(StrandPalette.accent)

            VStack(spacing: 10) {
                field("Server URL", text: profileBinding(\.serverURL), prompt: "https://noop.example.com")
                field("User ID", text: profileBinding(\.userID), prompt: "UUID")
                field("Device ID", text: profileBinding(\.deviceID), prompt: "my-whoop")
                field("Profile label", text: profileBinding(\.displayName), prompt: "Adam Whoop")
                tokenField
            }

            Picker("Sync interval", selection: intervalBinding) {
                ForEach(TimescaleSyncInterval.allCases) { interval in
                    Text(interval.title).tag(interval)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            validationBlock
            actionRow
            statusBlock
        }
        .onChangeCompat(of: settings.profile.enabled) { enabled in
            if enabled && settings.profile.interval == .manual {
                settings.profile.interval = .fifteenMinutes
            }
        }
    }

    private var tokenField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                SecureField(settings.tokenStored ? "Token saved in Keychain" : "Bearer token", text: $settings.tokenDraft)
                    .textFieldStyle(.roundedBorder)
                Button("Save") {
                    manager.saveTokenDraft()
                }
                .disabled(settings.tokenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if settings.tokenStored {
                    Button("Clear", role: .destructive) {
                        manager.clearToken()
                    }
                }
            }
            Text(settings.tokenStored ? "Token is stored in Keychain." : "Paste the server bearer token. It is stored in Keychain, not UserDefaults.")
                .font(StrandFont.caption)
                .foregroundStyle(StrandPalette.textTertiary)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                Task { await manager.testConnection() }
            } label: {
                Label("Test", systemImage: "network")
            }
            .disabled(manager.isSyncing || !settings.canTestConnection)

            Button {
                Task { await manager.syncNow() }
            } label: {
                Label(manager.isSyncing ? "Syncing..." : "Sync now", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .tint(StrandPalette.accent)
            .disabled(manager.isSyncing || !settings.canSyncNow)

            Button {
                confirmFullResync = true
            } label: {
                Label("Full resync", systemImage: "clock.arrow.circlepath")
            }
            .disabled(manager.isSyncing || !settings.canSyncNow)
        }
        .labelStyle(.titleAndIcon)
        .confirmationDialog("Full resync replays the local export lookback windows. Server upserts keep records idempotent.",
                            isPresented: $confirmFullResync,
                            titleVisibility: .visible) {
            Button("Full resync") {
                Task { await manager.syncNow(reason: "full-resync", fullResync: true) }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var validationBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(settings.validationMessages.enumerated()), id: \.offset) { _, message in
                Text(message)
                    .font(StrandFont.caption)
                    .foregroundStyle(message == settings.serverURLValidationMessage ? StrandPalette.statusWarning : StrandPalette.textTertiary)
            }
        }
    }

    private var statusBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let banner = manager.bannerMessage, !banner.isEmpty {
                Text(banner)
                    .font(StrandFont.caption)
                    .foregroundStyle(settings.lastStatus == .failed ? StrandPalette.statusCritical : StrandPalette.statusPositive)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(StrandPalette.surfaceRaised.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
            }
            statusRow("Last status", settings.lastStatus.rawValue)
            statusRow("Last attempt", format(settings.lastAttemptedSync))
            statusRow("Last success", format(settings.lastSuccessfulSync))
            if !settings.lastSummary.isEmpty {
                statusRow("Last result", settings.lastSummary)
            }
            if !settings.lastErrorMessage.isEmpty {
                statusRow("Last error", settings.lastErrorMessage, critical: true)
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(StrandFont.caption)
                .foregroundStyle(StrandPalette.textTertiary)
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func statusRow(_ label: String, _ value: String, critical: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(StrandFont.caption)
                .foregroundStyle(StrandPalette.textTertiary)
                .frame(width: 92, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(StrandFont.caption)
                .foregroundStyle(critical ? StrandPalette.statusCritical : StrandPalette.textSecondary)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }

    private func profileBinding<Value>(_ keyPath: WritableKeyPath<TimescaleSyncProfile, Value>) -> Binding<Value> {
        Binding {
            settings.profile[keyPath: keyPath]
        } set: { newValue in
            settings.profile[keyPath: keyPath] = newValue
        }
    }

    private var intervalBinding: Binding<TimescaleSyncInterval> {
        Binding {
            settings.profile.interval
        } set: { newValue in
            settings.profile.interval = newValue
        }
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        return Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

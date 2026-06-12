import SwiftUI
import StrandDesign

struct SleepAlarmView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var behavior: BehaviorStore
    @EnvironmentObject private var live: LiveState
    @Environment(\.dismiss) private var dismiss

    @State private var draft = SleepAlarmDraft()
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ZStack {
                SleepTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        alarmConfig
                        modeExplanation
                        targetAmount
                        hapticRow
                        bandControls
                    }
                    .padding(20)
                    .padding(.bottom, 88)
                    .frame(maxWidth: 680)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Sleep Alarm")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveBar
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadExistingAlarm)
    }

    private var alarmConfig: some View {
        SleepSurface {
            VStack(alignment: .leading, spacing: 18) {
                Label("Alarm config", systemImage: "alarm.fill")
                    .font(StrandFont.headline)
                    .foregroundStyle(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wake up at")
                            .font(StrandFont.subhead)
                            .foregroundStyle(SleepTheme.textSecondary)
                        Text(wakeTimeText)
                            .font(StrandFont.number(27))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    DatePicker(
                        "Wake up at",
                        selection: Binding(
                            get: { draft.wakeDate },
                            set: { draft.wakeDate = $0; saved = false }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(SleepTheme.purple)
                }

                Divider().overlay(SleepTheme.border)

                VStack(alignment: .leading, spacing: 9) {
                    Text("Alarm mode")
                        .font(StrandFont.subhead)
                        .foregroundStyle(SleepTheme.textSecondary)
                    HStack(spacing: 4) {
                        ForEach(SleepAlarmMode.allCases) { mode in
                            Button {
                                draft.mode = mode
                                saved = false
                            } label: {
                                Text(mode.rawValue)
                                    .font(StrandFont.captionNumber)
                                    .foregroundStyle(draft.mode == mode ? .white : SleepTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        draft.mode == mode ? SleepTheme.violet : .clear,
                                        in: Capsule(style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(SleepTheme.surfaceRaised, in: Capsule(style: .continuous))
                    .overlay(Capsule().stroke(SleepTheme.border, lineWidth: 1))
                }
            }
        }
    }

    private var modeExplanation: some View {
        SleepSurface {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: draft.mode.isSupportedByCore ? "checkmark.shield.fill" : "info.circle.fill")
                    .foregroundStyle(draft.mode.isSupportedByCore ? SleepTheme.purple : StrandPalette.statusWarning)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(draft.mode.rawValue) alarm")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Text(draft.mode.explanation)
                        .font(StrandFont.subhead)
                        .foregroundStyle(SleepTheme.textSecondary)
                    if !draft.mode.isSupportedByCore {
                        Text("Not yet supported by NOOP’s existing alarm API.")
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.statusWarning)
                    }
                }
            }
        }
    }

    private var targetAmount: some View {
        SleepSurface {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target amount")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Text("Used by Smart and Needed modes")
                        .font(StrandFont.footnote)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
                Spacer()
                stepButton("minus") { draft.adjustTarget(by: -15); saved = false }
                Text(draft.targetText)
                    .font(StrandFont.number(20))
                    .foregroundStyle(.white)
                    .frame(minWidth: 78)
                stepButton("plus") { draft.adjustTarget(by: 15); saved = false }
            }
        }
    }

    private var hapticRow: some View {
        SleepSurface {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .foregroundStyle(SleepTheme.purple)
                    .frame(width: 34, height: 34)
                    .background(SleepTheme.purple.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Haptic")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Text("Progressive")
                        .font(StrandFont.subhead)
                        .foregroundStyle(SleepTheme.textSecondary)
                }
                Spacer()
                Text("Band default")
                    .font(StrandFont.footnote)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }

    private var bandControls: some View {
        SleepSurface {
            VStack(alignment: .leading, spacing: 14) {
                Text("Band controls")
                    .font(StrandFont.headline)
                    .foregroundStyle(.white)
                HStack {
                    Label(
                        live.encryptedBond ? "Band connected" : "Band connection required",
                        systemImage: live.encryptedBond ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                    )
                    .font(StrandFont.subhead)
                    .foregroundStyle(live.encryptedBond ? StrandPalette.statusPositive : SleepTheme.textSecondary)
                    Spacer()
                    Button("Test haptic") {
                        model.buzz(pattern: 2, loops: 1)
                    }
                    .buttonStyle(.bordered)
                    .tint(SleepTheme.purple)
                    .disabled(!live.encryptedBond)
                }
                Text("NOOP uses the band’s existing fixed-time firmware alarm. It can fire while the app is closed.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }

    private var saveBar: some View {
        VStack(spacing: 5) {
            Button(action: saveToBand) {
                HStack {
                    Spacer()
                    Image(systemName: saved ? "checkmark" : "wave.3.right")
                    Text(saved ? "Saved to band" : "Save to band")
                    Spacer()
                }
                .font(StrandFont.headline)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(canSave ? SleepTheme.violet : SleepTheme.surfaceRaised,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(!canSave)

            if !draft.mode.isSupportedByCore {
                Text("Choose Regular or Off to use the current band alarm API.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(SleepTheme.textSecondary)
            } else if !live.encryptedBond {
                Text("Connect and fully pair your band to save.")
                    .font(StrandFont.footnote)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 32, height: 32)
                .background(SleepTheme.surfaceRaised, in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }

    private var canSave: Bool {
        draft.mode.isSupportedByCore && live.encryptedBond
    }

    private var wakeTimeText: String {
        draft.wakeDate.formatted(date: .omitted, time: .shortened)
    }

    private func loadExistingAlarm() {
        draft.wakeMinutes = behavior.smartAlarmMinutes
        draft.mode = behavior.smartAlarmEnabled ? .regular : .smart
    }

    private func saveToBand() {
        guard canSave else { return }
        behavior.smartAlarmMinutes = draft.wakeMinutes
        behavior.smartAlarmEnabled = draft.mode != .off
        model.applySmartAlarm()
        saved = true
    }
}

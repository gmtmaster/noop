import SwiftUI
import StrandDesign

enum RecoveryTheme {
    static let background = Color(hex: "#04120E")
    static let surface = Color(hex: "#0B211A")
    static let surfaceRaised = Color(hex: "#123027")
    static let border = Color(hex: "#21483B")
    static let green = Color(hex: "#21E58B")
    static let emerald = Color(hex: "#0BBE72")
    static let mint = Color(hex: "#8DFFD0")
    static let textSecondary = Color(hex: "#9AB8AD")
}

struct RecoveryHeroRing: View {
    let value: String
    let progress: Double?

    var body: some View {
        ZStack {
            Circle()
                .stroke(RecoveryTheme.border, lineWidth: 15)
            Circle()
                .trim(from: 0, to: min(max(progress ?? 0, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [RecoveryTheme.emerald, RecoveryTheme.green, RecoveryTheme.mint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: RecoveryTheme.green.opacity(0.42), radius: 16)
            VStack(spacing: 4) {
                Text(value)
                    .font(StrandFont.number(44))
                    .foregroundStyle(.white)
                Text("Recovery")
                    .font(StrandFont.subhead)
                    .foregroundStyle(RecoveryTheme.textSecondary)
            }
        }
        .frame(width: 190, height: 190)
        .accessibilityElement(children: .combine)
    }
}

struct RecoveryMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let systemImage: String

    var body: some View {
        RecoverySurface {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RecoveryTheme.green)
                    .frame(width: 32, height: 32)
                    .background(RecoveryTheme.green.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(StrandFont.caption)
                        .foregroundStyle(RecoveryTheme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(value)
                            .font(StrandFont.number(22))
                            .foregroundStyle(.white)
                        if !unit.isEmpty {
                            Text(unit)
                                .font(StrandFont.caption)
                                .foregroundStyle(RecoveryTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 128)
        .accessibilityElement(children: .combine)
    }
}

struct RecoveryCoachCard: View {
    let message: String
    let askCoach: () -> Void

    var body: some View {
        RecoverySurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Recovery Coach", systemImage: "sparkles")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Ask Coach", action: askCoach)
                        .buttonStyle(.bordered)
                        .tint(RecoveryTheme.green)
                }
                Text(message)
                    .font(StrandFont.body)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Powered by your local NOOP analytics")
                    .font(StrandFont.footnote)
                    .foregroundStyle(RecoveryTheme.textSecondary)
            }
        }
    }
}

struct RecoveryTrendCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RecoverySurface {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .foregroundStyle(RecoveryTheme.green)
                        .frame(width: 34, height: 34)
                        .background(RecoveryTheme.green.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(StrandFont.headline)
                            .foregroundStyle(.white)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(value)
                                .font(StrandFont.captionNumber)
                                .foregroundStyle(value == "--" ? RecoveryTheme.textSecondary : .white)
                            if value != "--", !unit.isEmpty {
                                Text(unit)
                                    .font(StrandFont.footnote)
                                    .foregroundStyle(RecoveryTheme.textSecondary)
                            }
                            if value == "--" {
                                Text("No data")
                                    .font(StrandFont.footnote)
                                    .foregroundStyle(RecoveryTheme.textSecondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RecoveryTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct RecoverySurface<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RecoveryTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(RecoveryTheme.border, lineWidth: 1)
            )
    }
}

import SwiftUI
import StrandDesign

enum StrainTheme {
    static let background = StrandPalette.surfaceBase
    static let surface = StrandPalette.surfaceRaised
    static let surfaceRaised = StrandPalette.surfaceOverlay
    static let border = StrandPalette.hairline
    static let orange = StrandPalette.effortColor
    static let amber = StrandPalette.effortBright
    static let cream = StrandPalette.statusWarning
    static let textSecondary = StrandPalette.textSecondary
    static let zones = [
        StrandPalette.zone1,
        StrandPalette.zone2,
        StrandPalette.zone3,
        StrandPalette.zone4,
        StrandPalette.zone5
    ]
}

struct StrainHeroRing: View {
    let value: String
    let progress: Double?
    let status: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(StrainTheme.border, lineWidth: 15)
            Circle()
                .trim(from: 0, to: min(max(progress ?? 0, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [StrainTheme.orange, StrainTheme.amber, StrainTheme.cream],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: StrainTheme.orange.opacity(0.42), radius: 16)
            VStack(spacing: 4) {
                Text(value)
                    .font(StrandFont.number(44))
                    .foregroundStyle(.white)
                Text(status)
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrainTheme.textSecondary)
            }
        }
        .frame(width: 190, height: 190)
        .accessibilityElement(children: .combine)
    }
}

struct StrainMetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let systemImage: String

    var body: some View {
        StrainSurface {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(StrainTheme.orange)
                    .frame(width: 32, height: 32)
                    .background(StrainTheme.orange.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(StrandFont.caption)
                        .foregroundStyle(StrainTheme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(value)
                            .font(StrandFont.number(22))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if value != "--", !unit.isEmpty {
                            Text(unit)
                                .font(StrandFont.caption)
                                .foregroundStyle(StrainTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 128)
        .accessibilityElement(children: .combine)
    }
}

struct StrainHeartRateZonesCard: View {
    let totalTime: String
    let minutes: [Double]?

    var body: some View {
        StrainSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Heart rate zones")
                        .font(StrandFont.title2)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(totalTime)
                        .font(StrandFont.captionNumber)
                        .foregroundStyle(StrainTheme.orange)
                }

                if let minutes {
                    VStack(spacing: 11) {
                        ForEach(0..<5, id: \.self) { index in
                            zoneRow(index: index, minutes: minutes[index])
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(StrainTheme.orange)
                        Text("No heart rate zone data yet")
                            .font(StrandFont.headline)
                            .foregroundStyle(.white)
                        Text("Zone time will appear after an activity includes heart-rate zone data.")
                            .font(StrandFont.subhead)
                            .foregroundStyle(StrainTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
            }
        }
    }

    private func zoneRow(index: Int, minutes: Double) -> some View {
        let maximum = max(self.minutes?.max() ?? 0, 1)
        return HStack(spacing: 10) {
            Text("Z\(index + 1)")
                .font(StrandFont.captionNumber)
                .foregroundStyle(StrainTheme.zones[index])
                .frame(width: 24, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(StrainTheme.border.opacity(0.65))
                    Capsule()
                        .fill(StrainTheme.zones[index])
                        .frame(width: max(minutes > 0 ? 5 : 0, geometry.size.width * minutes / maximum))
                }
            }
            .frame(height: 9)
            Text("\(Int(minutes.rounded())) min")
                .font(StrandFont.footnote)
                .foregroundStyle(.white)
                .frame(width: 48, alignment: .trailing)
        }
    }
}

struct StrainCoachCard: View {
    let message: String
    let askCoach: () -> Void

    var body: some View {
        StrainSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Strain Coach", systemImage: "sparkles")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Ask Coach", action: askCoach)
                        .buttonStyle(.bordered)
                        .tint(StrainTheme.orange)
                }
                Text(message)
                    .font(StrandFont.body)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Powered by your local NOOP analytics")
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrainTheme.textSecondary)
            }
        }
    }
}

struct StrainTrendCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            StrainSurface {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .foregroundStyle(StrainTheme.orange)
                        .frame(width: 34, height: 34)
                        .background(StrainTheme.orange.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(StrandFont.headline)
                            .foregroundStyle(.white)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(value)
                                .font(StrandFont.captionNumber)
                                .foregroundStyle(value == "--" ? StrainTheme.textSecondary : .white)
                            if value != "--", !unit.isEmpty {
                                Text(unit)
                                    .font(StrandFont.footnote)
                                    .foregroundStyle(StrainTheme.textSecondary)
                            }
                            if value == "--" {
                                Text("No data")
                                    .font(StrandFont.footnote)
                                    .foregroundStyle(StrainTheme.textSecondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(StrainTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct StrainSurface<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StrainTheme.surface, in: RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous)
                    .stroke(StrainTheme.border, lineWidth: 1)
            )
    }
}

import SwiftUI
import StrandDesign

struct MetricRingCard: View {
    let title: LocalizedStringKey
    let value: String
    let progress: Double?
    let tint: Color
    let systemImage: String
    var caption: LocalizedStringKey? = nil

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(StrandPalette.hairline, lineWidth: 9)

                Circle()
                    .trim(from: 0, to: normalizedProgress)
                    .stroke(
                        AngularGradient(
                            colors: [tint.opacity(0.45), tint, tint.opacity(0.8)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: tint.opacity(0.32), radius: 7)

                Text(value)
                    .font(StrandFont.number(value.count > 5 ? 19 : 25))
                    .foregroundStyle(StrandPalette.textPrimary)
                    .minimumScaleFactor(0.68)
                    .lineLimit(1)
                    .padding(12)
            }
            .frame(width: 96, height: 96)

            VStack(spacing: 1) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StrandPalette.textPrimary)
                    .labelStyle(.titleAndIcon)
                if let caption {
                    Text(caption)
                        .font(StrandFont.footnote)
                        .foregroundStyle(StrandPalette.textTertiary)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var normalizedProgress: Double {
        min(max(progress ?? 0, 0), 1)
    }
}

struct CompactInsightCard: View {
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("TODAY’S INSIGHT")
                        .font(StrandFont.overline)
                        .tracking(StrandFont.overlineTracking)
                        .foregroundStyle(StrandPalette.textSecondary)
                    Text(title)
                        .font(StrandFont.headline)
                        .foregroundStyle(tint)
                    Text(detail)
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct StressEnergyCard: View {
    let energy: String

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            HStack(spacing: 0) {
                summary(
                    title: "Stress",
                    value: "Coming soon",
                    detail: "Daily level",
                    systemImage: "waveform.path.ecg",
                    tint: StrandPalette.metricAmber,
                    isPlaceholder: true
                )
                Divider()
                    .overlay(StrandPalette.hairline)
                    .padding(.horizontal, 16)
                summary(
                    title: "Energy",
                    value: energy,
                    detail: "kcal today",
                    systemImage: "bolt.fill",
                    tint: StrandPalette.statusPositive
                )
            }
        }
    }

    private func summary(
        title: LocalizedStringKey,
        value: String,
        detail: String,
        systemImage: String,
        tint: Color,
        isPlaceholder: Bool = false
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).strandOverline()
                Text(value)
                    .font(isPlaceholder ? StrandFont.captionNumber : StrandFont.number(20))
                    .foregroundStyle(isPlaceholder ? StrandPalette.textSecondary : StrandPalette.textPrimary)
                    .lineLimit(1)
                Text(detail)
                    .font(StrandFont.footnote)
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BiomarkerCard: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    let systemImage: String
    var tint: Color = StrandPalette.accent
    var detail: String? = nil
    var isPlaceholder = false

    var body: some View {
        StrandCard(padding: 14, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 30, height: 30)
                        .background(tint.opacity(0.12), in: Circle())
                    Spacer()
                    if isPlaceholder {
                        Text("SOON")
                            .font(StrandFont.overline)
                            .tracking(StrandFont.overlineTracking)
                            .foregroundStyle(StrandPalette.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).strandOverline()
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(value)
                            .font(StrandFont.number(22))
                            .foregroundStyle(isPlaceholder ? StrandPalette.textSecondary : StrandPalette.textPrimary)
                        if !unit.isEmpty {
                            Text(unit)
                                .font(StrandFont.caption)
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                    }
                    if let detail {
                        Text(detail)
                            .font(StrandFont.footnote)
                            .foregroundStyle(StrandPalette.textTertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(minHeight: 122)
        .accessibilityElement(children: .combine)
    }
}

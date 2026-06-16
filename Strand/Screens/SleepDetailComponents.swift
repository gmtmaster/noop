import SwiftUI
import StrandDesign

enum SleepTheme {
    static let background = StrandPalette.surfaceBase
    static let surface = StrandPalette.surfaceRaised
    static let surfaceRaised = StrandPalette.surfaceOverlay
    static let border = StrandPalette.hairline
    static let purple = StrandPalette.restBright
    static let violet = StrandPalette.restDeep
    static let blue = StrandPalette.restColor
    static let textSecondary = StrandPalette.textSecondary
}

struct SleepHeroRing: View {
    let value: String
    let progress: Double?

    var body: some View {
        ZStack {
            Circle()
                .stroke(SleepTheme.border, lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(max(progress ?? 0, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [SleepTheme.violet, SleepTheme.blue, SleepTheme.purple],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: SleepTheme.purple.opacity(0.45), radius: 14)
            VStack(spacing: 3) {
                Text(value)
                    .font(StrandFont.number(42))
                    .foregroundStyle(.white)
                Text("Quality")
                    .font(StrandFont.subhead)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
        .frame(width: 180, height: 180)
        .accessibilityElement(children: .combine)
    }
}

struct SleepSummaryCard: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String

    var body: some View {
        SleepSurface {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SleepTheme.purple)
                    .frame(width: 36, height: 36)
                    .background(SleepTheme.purple.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(StrandFont.caption)
                        .foregroundStyle(SleepTheme.textSecondary)
                    Text(value)
                        .font(StrandFont.number(20))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct SleepCoachCard: View {
    let message: String
    let askCoach: () -> Void

    var body: some View {
        SleepSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Sleep Coach", systemImage: "sparkles")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Ask Coach", action: askCoach)
                        .buttonStyle(.bordered)
                        .tint(SleepTheme.purple)
                }
                Text(message)
                    .font(StrandFont.body)
                    .foregroundStyle(.white)
                Text("Local sleep score and schedule")
                    .font(StrandFont.footnote)
                    .foregroundStyle(SleepTheme.textSecondary)
            }
        }
    }
}

struct SleepScheduleCard: View {
    var body: some View {
        SleepSurface {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Sleep schedule")
                        .font(StrandFont.title2)
                        .foregroundStyle(.white)
                    Text("Tonight")
                        .font(StrandFont.subhead)
                        .foregroundStyle(SleepTheme.textSecondary)
                }

                HStack(spacing: 0) {
                    schedulePoint("Wind down", "21:20", "moon.haze.fill")
                    schedulePoint("Bedtime", "21:50", "bed.double.fill")
                    schedulePoint("Wake", "05:30", "sunrise.fill")
                }

                scheduleTimeline

                Divider().overlay(SleepTheme.border)

                HStack {
                    scheduleFact("Tonight’s sleep needed", "7h 39m")
                    Spacer()
                    scheduleFact("Wake up at", "05:30", alignment: .trailing)
                }
            }
        }
    }

    private func schedulePoint(_ title: LocalizedStringKey, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(SleepTheme.purple)
            Text(title)
                .font(StrandFont.footnote)
                .foregroundStyle(SleepTheme.textSecondary)
            Text(value)
                .font(StrandFont.captionNumber)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private var scheduleTimeline: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(SleepTheme.border).frame(height: 5)
                Capsule()
                    .fill(LinearGradient(colors: [SleepTheme.violet, SleepTheme.purple, SleepTheme.blue],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * 0.84, height: 5)
                ForEach([0.0, 0.08, 0.84], id: \.self) { position in
                    Circle()
                        .fill(.white)
                        .frame(width: 10, height: 10)
                        .shadow(color: SleepTheme.purple, radius: 5)
                        .offset(x: max(0, geometry.size.width * position - 5))
                }
            }
        }
        .frame(height: 10)
    }

    private func scheduleFact(_ title: LocalizedStringKey, _ value: String,
                              alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(StrandFont.footnote)
                .foregroundStyle(SleepTheme.textSecondary)
            Text(value)
                .font(StrandFont.number(21))
                .foregroundStyle(.white)
        }
    }
}

struct SleepTrendCard: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SleepSurface {
                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .foregroundStyle(SleepTheme.purple)
                        .frame(width: 34, height: 34)
                        .background(SleepTheme.purple.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(StrandFont.headline)
                            .foregroundStyle(.white)
                        Text("No data")
                            .font(StrandFont.footnote)
                            .foregroundStyle(SleepTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SleepSurface<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SleepTheme.surface, in: RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous)
                    .stroke(SleepTheme.border, lineWidth: 1)
            )
    }
}

import SwiftUI
import StrandDesign
import WhoopStore

struct SleepDetailView: View {
    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMetric: SleepMetricSelection?
    @State private var notice: SleepNotice?
    @State private var showingAlarm = false

    private let trendMetrics: [(String, String)] = [
        ("Sleep Score", "gauge.with.dots.needle.67percent"),
        ("Time Asleep", "moon.zzz.fill"),
        ("REM sleep", "brain.head.profile.fill"),
        ("Deep Sleep", "moon.fill"),
        ("Sleep Bank", "banknote.fill"),
        ("Sleep Time", "bed.double.fill"),
        ("Wake Time", "sunrise.fill"),
        ("Time To Fall Asleep", "timer")
    ]

    private var snapshot: SleepDetailSnapshot {
        SleepDetailSnapshot(
            today: repo.today,
            session: latestSession,
            importedPerformance: repo.today.flatMap { repo.importedSleep[$0.day]?.performancePct }
        )
    }

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 20) {
                    header
                    hero
                    summary
                    SleepCoachCard(message: snapshot.coachMessage) { notice = .coach }
                    insightsRow
                    SleepScheduleCard()
                    trends
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedMetric) { metric in
            SleepMetricDetailView(title: metric.title)
        }
        .sheet(isPresented: $showingAlarm) {
            SleepAlarmView()
        }
        .alert(item: $notice) { item in
            Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }

    private var header: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(SleepTheme.surfaceRaised, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Spacer()
            Text("Sleep")
                .font(StrandFont.title2)
                .foregroundStyle(.white)
            Spacer()
            Button { showingAlarm = true } label: {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(SleepTheme.surfaceRaised, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sleep Alarm")
        }
        .foregroundStyle(.white)
        .padding(.top, 14)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            SleepHeroRing(value: snapshot.qualityText,
                          progress: snapshot.quality.map { $0 / 100 })
            Text(snapshot.dateLabel)
                .font(StrandFont.captionNumber)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(SleepTheme.surfaceRaised, in: Capsule(style: .continuous))
                .overlay(Capsule().stroke(SleepTheme.border, lineWidth: 1))
        }
        .padding(.vertical, 4)
    }

    private var summary: some View {
        HStack(spacing: 12) {
            SleepSummaryCard(title: "Time in Bed", value: snapshot.timeInBedText,
                             systemImage: "bed.double.fill")
            SleepSummaryCard(title: "Time Asleep", value: snapshot.timeAsleepText,
                             systemImage: "moon.zzz.fill")
        }
    }

    private var insightsRow: some View {
        Button { selectedMetric = SleepMetricSelection(title: "Sleep insights") } label: {
            SleepSurface {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(SleepTheme.purple)
                    Text("View insights")
                        .font(StrandFont.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SleepTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var trends: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends")
                .font(StrandFont.title2)
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                ForEach(trendMetrics, id: \.0) { metric in
                    SleepTrendCard(title: LocalizedStringKey(metric.0), systemImage: metric.1) {
                        selectedMetric = SleepMetricSelection(title: metric.0)
                    }
                }
            }
        }
    }

    private var latestSession: CachedSleepSession? {
        guard let day = repo.today?.day else { return repo.sleeps.last }
        return repo.sleeps.last(where: {
            Self.dayFormatter.string(from: Date(timeIntervalSince1970: TimeInterval($0.endTs))) == day
        })
    }

    private var background: some View {
        ZStack {
            SleepTheme.background
            RadialGradient(colors: [SleepTheme.violet.opacity(0.25), .clear],
                           center: .top, startRadius: 0, endRadius: 520)
            Canvas { context, size in
                for index in 0..<28 {
                    let x = CGFloat((index * 73) % 101) / 100 * size.width
                    let y = CGFloat((index * 47) % 37) / 100 * min(size.height, 420)
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                                 with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.20 : 0.09)))
                }
            }
        }
        .ignoresSafeArea()
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct SleepMetricSelection: Identifiable {
    let title: String
    var id: String { title }
}

private enum SleepNotice: String, Identifiable {
    case coach

    var id: String { rawValue }
    var title: String { "Sleep Coach" }
    var message: String {
        "Coach questions will be connected to the existing coach flow later."
    }
}

import SwiftUI
import StrandDesign
import WhoopStore

struct StrainDetailView: View {
    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss
    @State private var workouts: [WorkoutRow] = []
    @State private var selectedMetric: StrainMetricSelection?
    @State private var notice: StrainNotice?

    private var snapshot: StrainDetailSnapshot {
        StrainDetailSnapshot(today: repo.today, workouts: workouts)
    }

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 20) {
                    header
                    hero
                    metrics
                    StrainHeartRateZonesCard(
                        totalTime: snapshot.totalZoneTimeText,
                        minutes: snapshot.zoneMinutes
                    )
                    StrainCoachCard(message: snapshot.coachMessage) {
                        notice = .coach
                    }
                    activities
                    trends
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .task(id: repo.refreshSeq) {
            workouts = await repo.workoutRows(days: 7)
        }
        .sheet(item: $selectedMetric) { metric in
            StrainMetricDetailView(title: metric.title)
        }
        .alert(item: $notice) { item in
            Alert(title: Text(item.title), message: Text(item.message),
                  dismissButton: .default(Text("OK")))
        }
    }

    private var header: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(StrainTheme.surfaceRaised, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Spacer()
            Text("Strain")
                .font(StrandFont.title2)
                .foregroundStyle(.white)
            Spacer()
            Button { notice = .calendar } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(StrainTheme.surfaceRaised, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose date")
        }
        .foregroundStyle(.white)
        .padding(.top, 14)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            StrainHeroRing(
                value: snapshot.strainText,
                progress: snapshot.strainProgress,
                status: snapshot.statusText
            )
            Text(snapshot.dateLabel)
                .font(StrandFont.captionNumber)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(StrainTheme.surfaceRaised, in: Capsule(style: .continuous))
                .overlay(Capsule().stroke(StrainTheme.border, lineWidth: 1))
        }
        .padding(.vertical, 4)
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            StrainMetricCard(title: "Target Strain", value: snapshot.targetStrainText,
                             unit: "", systemImage: "scope")
            StrainMetricCard(title: "Duration", value: snapshot.durationText,
                             unit: "", systemImage: "timer")
            StrainMetricCard(title: "Total Energy", value: snapshot.totalEnergyText,
                             unit: "kcal", systemImage: "bolt.fill")
            StrainMetricCard(title: "Steps", value: snapshot.stepsText,
                             unit: "", systemImage: "figure.walk")
        }
    }

    private var activities: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activities")
                .font(StrandFont.title2)
                .foregroundStyle(.white)

            if snapshot.activities.isEmpty {
                StrainSurface {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .foregroundStyle(StrainTheme.orange)
                            .frame(width: 36, height: 36)
                            .background(StrainTheme.orange.opacity(0.12), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No activities")
                                .font(StrandFont.headline)
                                .foregroundStyle(.white)
                            Text("Activities will appear after workouts or detected activity are available.")
                                .font(StrandFont.subhead)
                                .foregroundStyle(StrainTheme.textSecondary)
                        }
                    }
                }
            } else {
                ForEach(Array(snapshot.activities.enumerated()), id: \.offset) { _, activity in
                    StrainSurface {
                        HStack(spacing: 12) {
                            Image(systemName: "figure.run")
                                .foregroundStyle(StrainTheme.orange)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(activity.sport.capitalized)
                                    .font(StrandFont.headline)
                                    .foregroundStyle(.white)
                                Text(Date(timeIntervalSince1970: TimeInterval(activity.startTs))
                                    .formatted(.dateTime.hour().minute()))
                                    .font(StrandFont.footnote)
                                    .foregroundStyle(StrainTheme.textSecondary)
                            }
                            Spacer()
                            Text(snapshot.activityDuration(activity))
                                .font(StrandFont.captionNumber)
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
    }

    private var trends: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends")
                .font(StrandFont.title2)
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                trend("Strain Score", snapshot.strain.map { String(format: "%.1f", $0) } ?? "--",
                      "", "gauge.with.dots.needle.67percent")
                trend("Duration", snapshot.durationText, "", "timer")
                trend("Total Energy", snapshot.totalEnergyText, "kcal", "bolt.fill")
                trend("Steps", snapshot.stepsText, "", "figure.walk")
                trend("Heart Rate Zones", snapshot.zoneMinutes == nil ? "--" : snapshot.totalZoneTimeText,
                      "", "heart.text.square.fill")
            }
        }
    }

    private func trend(_ title: String, _ value: String, _ unit: String, _ icon: String) -> some View {
        StrainTrendCard(title: LocalizedStringKey(title), value: value, unit: unit, systemImage: icon) {
            selectedMetric = StrainMetricSelection(title: title)
        }
    }

    private var background: some View {
        ZStack {
            StrainTheme.background
            RadialGradient(
                colors: [StrainTheme.orange.opacity(0.22), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 560
            )
            StrainActivityBackdrop()
                .stroke(StrainTheme.orange.opacity(0.055), lineWidth: 2)
                .frame(height: 220)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: 92)
        }
        .ignoresSafeArea()
    }
}

private struct StrainMetricSelection: Identifiable {
    let title: String
    var id: String { title }
}

private enum StrainNotice: String, Identifiable {
    case calendar
    case coach

    var id: String { rawValue }
    var title: String { self == .calendar ? "Strain Date" : "Strain Coach" }
    var message: String {
        switch self {
        case .calendar: return "Date selection will be connected when historical strain navigation is added."
        case .coach: return "Coach questions will be connected to the existing coach flow later."
        }
    }
}

private struct StrainActivityBackdrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.74))
        let points: [CGPoint] = [
            CGPoint(x: rect.width * 0.12, y: rect.height * 0.67),
            CGPoint(x: rect.width * 0.22, y: rect.height * 0.71),
            CGPoint(x: rect.width * 0.34, y: rect.height * 0.42),
            CGPoint(x: rect.width * 0.46, y: rect.height * 0.58),
            CGPoint(x: rect.width * 0.58, y: rect.height * 0.30),
            CGPoint(x: rect.width * 0.70, y: rect.height * 0.51),
            CGPoint(x: rect.width * 0.83, y: rect.height * 0.38),
            CGPoint(x: rect.width, y: rect.height * 0.54)
        ]
        for point in points { path.addLine(to: point) }
        return path
    }
}

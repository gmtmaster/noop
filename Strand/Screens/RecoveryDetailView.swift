import SwiftUI
import StrandDesign
import WhoopStore

struct RecoveryDetailView: View {
    @EnvironmentObject private var repo: Repository
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMetric: RecoveryMetricSelection?
    @State private var showingCoachNotice = false

    private var snapshot: RecoveryDetailSnapshot {
        RecoveryDetailSnapshot(today: repo.today)
    }

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 20) {
                    header
                    hero
                    metrics
                    RecoveryCoachCard(message: snapshot.coachMessage) {
                        showingCoachNotice = true
                    }
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
            RecoveryMetricDetailView(title: metric.title)
        }
        .alert("Recovery Coach", isPresented: $showingCoachNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Coach questions will be connected to the existing coach flow later.")
        }
    }

    private var header: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(RecoveryTheme.surfaceRaised, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Spacer()
            Text("Recovery")
                .font(StrandFont.title2)
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .foregroundStyle(.white)
        .padding(.top, 14)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            RecoveryHeroRing(value: snapshot.recoveryText, progress: snapshot.recoveryProgress)
            Text(snapshot.dateLabel)
                .font(StrandFont.captionNumber)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(RecoveryTheme.surfaceRaised, in: Capsule(style: .continuous))
                .overlay(Capsule().stroke(RecoveryTheme.border, lineWidth: 1))
        }
        .padding(.vertical, 4)
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
            RecoveryMetricCard(title: "Resting HRV", value: snapshot.restingHrvText,
                               unit: "ms", systemImage: "waveform")
            RecoveryMetricCard(title: "Resting HR", value: snapshot.restingHeartRateText,
                               unit: "bpm", systemImage: "heart.fill")
            RecoveryMetricCard(title: "Respiratory Rate", value: snapshot.respiratoryRateText,
                               unit: "br/min", systemImage: "lungs.fill")
            RecoveryMetricCard(title: "Oxygen Saturation", value: snapshot.oxygenSaturationText,
                               unit: "%", systemImage: "drop.fill")
            RecoveryMetricCard(title: "Wrist Temperature", value: snapshot.wristTemperatureText,
                               unit: "°C", systemImage: "thermometer.medium")
        }
    }

    private var trends: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends")
                .font(StrandFont.title2)
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                trend("Recovery Score", snapshot.recoveryText, "", "gauge.with.dots.needle.67percent")
                trend("Resting HRV", snapshot.restingHrvText, "ms", "waveform")
                trend("Resting HR", snapshot.restingHeartRateText, "bpm", "heart.fill")
                trend("Respiratory Rate", snapshot.respiratoryRateText, "br/min", "lungs.fill")
                trend("Wrist Temperature", snapshot.wristTemperatureText, "°C", "thermometer.medium")
                trend("Oxygen Saturation", snapshot.oxygenSaturationText, "%", "drop.fill")
            }
        }
    }

    private func trend(_ title: String, _ value: String, _ unit: String, _ icon: String) -> some View {
        RecoveryTrendCard(title: LocalizedStringKey(title), value: value, unit: unit, systemImage: icon) {
            selectedMetric = RecoveryMetricSelection(title: title)
        }
    }

    private var background: some View {
        ZStack {
            RecoveryTheme.background
            RadialGradient(
                colors: [RecoveryTheme.emerald.opacity(0.24), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 560
            )
            RecoveryLandscape()
                .fill(RecoveryTheme.green.opacity(0.035))
                .frame(height: 250)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: 75)
        }
        .ignoresSafeArea()
    }
}

private struct RecoveryMetricSelection: Identifiable {
    let title: String
    var id: String { title }
}

private struct RecoveryLandscape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.78))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.55, y: rect.height * 0.42),
            control1: CGPoint(x: rect.width * 0.18, y: rect.height * 0.72),
            control2: CGPoint(x: rect.width * 0.34, y: rect.height * 0.30)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.68),
            control1: CGPoint(x: rect.width * 0.72, y: rect.height * 0.32),
            control2: CGPoint(x: rect.width * 0.86, y: rect.height * 0.66)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}


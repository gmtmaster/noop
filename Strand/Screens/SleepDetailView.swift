import SwiftUI
import StrandDesign

struct SleepDetailView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SleepView()

            Button(action: dismiss.callAsFunction) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StrandPalette.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(StrandPalette.surfaceRaised.opacity(0.92), in: Circle())
                    .overlay(Circle().stroke(StrandPalette.hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
            .padding(.trailing, NoopMetrics.screenPadding)
            .accessibilityLabel("Close sleep details")
        }
    }
}

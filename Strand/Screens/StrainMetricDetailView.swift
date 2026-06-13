import SwiftUI
import StrandDesign

struct StrainMetricDetailView: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var range = "30D"

    private let ranges = ["1D", "30D", "3M", "6M", "1Y"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    noData
                    rangeSelector
                    section(
                        "Trends Analysis",
                        detail: "Trend analysis will appear when enough strain history is available.",
                        icon: "chart.xyaxis.line"
                    )
                    section(
                        "Resources",
                        detail: "Learn how activity and heart-rate intensity contribute to daily strain.",
                        icon: "book.closed.fill"
                    )
                }
                .padding(20)
            }
            .background(StrainTheme.background.ignoresSafeArea())
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: dismiss.callAsFunction)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var noData: some View {
        StrainSurface {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.system(size: 32))
                    .foregroundStyle(StrainTheme.orange)
                Text("No trend data")
                    .font(StrandFont.title2)
                    .foregroundStyle(.white)
                Text("Capture more activity and heart-rate data to build this trend.")
                    .font(StrandFont.subhead)
                    .foregroundStyle(StrainTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
        }
    }

    private var rangeSelector: some View {
        HStack(spacing: 4) {
            ForEach(ranges, id: \.self) { item in
                Button {
                    range = item
                } label: {
                    Text(item)
                        .font(StrandFont.captionNumber)
                        .foregroundStyle(range == item ? StrainTheme.background : StrainTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(range == item ? StrainTheme.orange : .clear,
                                    in: Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(StrainTheme.surface, in: Capsule(style: .continuous))
        .overlay(Capsule().stroke(StrainTheme.border, lineWidth: 1))
    }

    private func section(_ title: LocalizedStringKey, detail: LocalizedStringKey, icon: String) -> some View {
        StrainSurface {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(StrainTheme.orange)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(StrandFont.headline).foregroundStyle(.white)
                    Text(detail).font(StrandFont.subhead).foregroundStyle(StrainTheme.textSecondary)
                }
            }
        }
    }
}


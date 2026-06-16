import SwiftUI

// MARK: - Strand Typography
//
// Goose dark mode uses native Apple system typography with compact weights and
// tabular digits for live values. SF Mono stays for raw/log views. Overlines are
// small, restrained labels rather than a heavy brand treatment.
//
// All numeric styles use `.monospacedDigit()` so live values don't reflow.

public enum StrandFont {

    // MARK: Family

    /// System font at a fixed size/weight for gauges and fixed-geometry numerals.
    private static func system(_ size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Dynamic-Type aware system font for prose and labels.
    private static func systemScaled(_ size: CGFloat, weight: Font.Weight,
                                     relativeTo style: Font.TextStyle) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // MARK: Scale (§9.2)

    /// Display score number with tabular digits so changing values never reflow.
    public static func display(_ size: CGFloat = 72) -> Font {
        system(size, weight: .bold).monospacedDigit()
    }

    /// Goose keeps display tracking neutral.
    public static func displayTracking(_ size: CGFloat = 72) -> CGFloat {
        0
    }

    /// System numeric style at an arbitrary size/weight with tabular digits.
    public static func rounded(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        system(size, weight: weight).monospacedDigit()
    }

    /// Title1 28 / Bold. Scales with Dynamic Type.
    public static let title1 = systemScaled(28, weight: .bold, relativeTo: .title)

    /// Title2 22 / Semibold. Scales with Dynamic Type.
    public static let title2 = systemScaled(22, weight: .semibold, relativeTo: .title2)

    /// Headline 17 / Semibold. Scales with Dynamic Type.
    public static let headline = systemScaled(17, weight: .semibold, relativeTo: .headline)

    /// Body 15 / Regular. Scales with Dynamic Type.
    public static let body = systemScaled(15, weight: .regular, relativeTo: .body)

    /// Subhead 13. Scales with Dynamic Type.
    public static let subhead = systemScaled(13, weight: .regular, relativeTo: .subheadline)

    /// Caption 12. Scales with Dynamic Type.
    public static let caption = systemScaled(12, weight: .regular, relativeTo: .caption)

    /// Footnote 11. Scales with Dynamic Type.
    public static let footnote = systemScaled(11, weight: .regular, relativeTo: .footnote)

    /// Overline 11 / Semibold. Sparing ALL-CAPS labels. Scales with Dynamic Type.
    public static let overline = systemScaled(11, weight: .semibold, relativeTo: .caption2)

    /// `overline` at a custom point size with Dynamic-Type scaling
    /// (relativeTo `.caption2`), just smaller. Passing 11 returns exactly `.overline`. Lets a caller
    /// shrink an ALL-CAPS label to fit a small container without losing accessibility text-scaling.
    public static func overlineScaled(_ size: CGFloat) -> Font {
        systemScaled(size, weight: .semibold, relativeTo: .caption2)
    }

    /// Mono 13 (SF Mono) — raw / log views. Tabular by nature.
    public static let mono = Font.system(size: 13, weight: .regular, design: .monospaced)

    // MARK: Numeric variants (tabular digits)

    /// A numeric style at an arbitrary size/weight for live values.
    public static func number(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        system(size, weight: weight).monospacedDigit()
    }

    /// Body number for inline live values that should align. Scales with Dynamic
    /// Type alongside its sibling `body`/`caption` labels so a value and its label stay matched.
    public static let bodyNumber = systemScaled(15, weight: .medium, relativeTo: .body).monospacedDigit()

    /// Caption number for small live values (sparklines, chips). Scales with Dynamic Type.
    public static let captionNumber = systemScaled(12, weight: .medium, relativeTo: .caption).monospacedDigit()

    /// Mono at an arbitrary size.
    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// Goose keeps label tracking neutral.
    public static let overlineTracking: CGFloat = 0
}

// MARK: - Text helpers

public extension Text {
    /// Style as an overline label: compact all-caps, semibold, secondary text.
    func strandOverline() -> some View {
        self.font(StrandFont.overline)
            .tracking(StrandFont.overlineTracking)
            .textCase(.uppercase)
            .foregroundStyle(StrandPalette.textSecondary)
    }
}

public extension View {
    /// Convenience: an overline-styled label string.
    static func strandOverline(_ string: String) -> some View {
        Text(string).strandOverline()
    }
}

#if DEBUG
#Preview("Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text("88").font(StrandFont.display(72)).tracking(StrandFont.displayTracking(72)).foregroundStyle(StrandPalette.textPrimary)
            Text("Title 1 / Bold 28").font(StrandFont.title1).foregroundStyle(StrandPalette.textPrimary)
            Text("Title 2 / Semibold 22").font(StrandFont.title2).foregroundStyle(StrandPalette.textPrimary)
            Text("Headline / Semibold 17").font(StrandFont.headline).foregroundStyle(StrandPalette.textPrimary)
            Text("Body / Regular 15 — the thread of you, read in full.")
                .font(StrandFont.body).foregroundStyle(StrandPalette.textPrimary)
            Text("Subhead 13").font(StrandFont.subhead).foregroundStyle(StrandPalette.textSecondary)
            Text("Caption 12").font(StrandFont.caption).foregroundStyle(StrandPalette.textSecondary)
            Text("Footnote 11").font(StrandFont.footnote).foregroundStyle(StrandPalette.textTertiary)
            Text("Overline").strandOverline()
            Text("0xAA 41 00 1c crc32=f3a1  mono 13").font(StrandFont.mono).foregroundStyle(StrandPalette.textSecondary)
            HStack(spacing: 4) {
                Text("HRV").font(StrandFont.caption).foregroundStyle(StrandPalette.textSecondary)
                Text("62").font(StrandFont.bodyNumber).foregroundStyle(StrandPalette.textPrimary)
                Text("ms").font(StrandFont.caption).foregroundStyle(StrandPalette.textTertiary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(width: 520, height: 620)
    .background(StrandPalette.surfaceBase)
    .preferredColorScheme(.dark)
}
#endif

import SwiftUI

// MARK: - Hex Color Helper

public extension Color {
    /// Create a Color from a hex string like "#0B0D12" or "0B0D12" (RGB) or "#AARRGGBB" / "RRGGBBAA".
    /// Supported lengths: 6 (RGB), 8 (RGBA).
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&int)
        let r, g, b, a: Double
        switch raw.count {
        case 8: // RRGGBBAA
            r = Double((int >> 24) & 0xFF) / 255.0
            g = Double((int >> 16) & 0xFF) / 255.0
            b = Double((int >> 8) & 0xFF) / 255.0
            a = Double(int & 0xFF) / 255.0
        default: // RRGGBB (6) and any fallback
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
            a = 1.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Strand Palette
//
// Goose dark mode skin for Noop. The public token names stay stable because screens
// across macOS and iOS already depend on them, but the values now follow Goose's
// native grouped-background feel: charcoal surfaces, subdued borders, system-like
// typography contrast, and semantic green / blue / teal / orange accents.

public enum StrandPalette {

    // MARK: Surfaces
    public static let surfaceBase    = Color(hex: "#0F171C")
    public static let surfaceRaised  = Color(hex: "#171F24")
    public static let surfaceOverlay = Color(hex: "#202A31")
    public static let surfaceInset   = Color(hex: "#11191E")
    public static let hairline       = Color.white.opacity(0.10)
    public static let hairlineStrong = Color.white.opacity(0.18)

    // MARK: Text
    public static let textPrimary    = Color(hex: "#F2F5F7")
    public static let textSecondary  = Color(hex: "#B7C0C7")
    public static let textTertiary   = Color(hex: "#7F8B94")

    // MARK: Glow
    public static let glowAmbient    = Color(hex: "#123027")

    // MARK: Accent
    public static let accent         = Color(hex: "#64D2FF")
    public static let accentHover    = Color(hex: "#9BE7FF")
    public static let accentMuted    = Color(hex: "#17303A")
    /// Focus ring color (same as accent).
    public static let focusRing      = Color(hex: "#64D2FF")
    /// Opacity for dimmed/disabled sections (shared so screens don't invent their own value).
    public static let disabledOpacity: Double = 0.45

    // MARK: Recovery / Charge gradient
    public static let recovery000 = Color(hex: "#FF6B5F")
    public static let recovery030 = Color(hex: "#FF9F0A")
    public static let recovery055 = Color(hex: "#FFD60A")
    public static let recovery078 = Color(hex: "#32D17E")
    public static let recovery100 = Color(hex: "#63E6A3")

    /// Ordered gradient stops for the recovery scale (location + color).
    public static let recoveryStops: [Gradient.Stop] = [
        .init(color: recovery000, location: 0.00),
        .init(color: recovery030, location: 0.30),
        .init(color: recovery055, location: 0.55),
        .init(color: recovery078, location: 0.78),
        .init(color: recovery100, location: 1.00),
    ]

    /// Recovery scale: depleted red/orange through yellow into Goose green.
    public static let recoveryGradient = Gradient(stops: recoveryStops)

    // MARK: Strain / Effort ramp
    public static let strain000 = Color(hex: "#2C5364")
    public static let strain033 = Color(hex: "#FFB340")
    public static let strain066 = Color(hex: "#FF7A3D")
    public static let strain100 = Color(hex: "#FF453A")

    public static let strainStops: [Gradient.Stop] = [
        .init(color: strain000, location: 0.00),
        .init(color: strain033, location: 0.33),
        .init(color: strain066, location: 0.66),
        .init(color: strain100, location: 1.00),
    ]

    /// The strain gradient (output / heat).
    public static let strainGradient = Gradient(stops: strainStops)

    // MARK: Sleep stages
    public static let sleepAwake = Color(hex: "#9AA6AE")
    public static let sleepLight = Color(hex: "#64D2FF")
    public static let sleepDeep  = Color(hex: "#0A84FF")
    public static let sleepREM   = Color(hex: "#BF5AF2")

    // MARK: HR zones
    public static let zone1 = Color(hex: "#64D2FF")
    public static let zone2 = Color(hex: "#40C8A6")
    public static let zone3 = Color(hex: "#32D17E")
    public static let zone4 = Color(hex: "#FF9F0A")
    public static let zone5 = Color(hex: "#FF453A")

    /// HR zones indexed 1...5; index 0 mirrors zone1 for convenience.
    public static let hrZones: [Color] = [zone1, zone1, zone2, zone3, zone4, zone5]

    // MARK: Status — never reused as recovery colors.
    public static let statusPositive = Color(hex: "#32D17E")
    public static let statusWarning  = Color(hex: "#FF9F0A")
    public static let statusCritical = Color(hex: "#FF453A")

    // MARK: Per-metric accents
    public static let metricCyan   = Color(hex: "#64D2FF")
    public static let metricPurple = Color(hex: "#BF5AF2")
    public static let metricAmber  = Color(hex: "#FF9F0A")
    public static let metricRose   = Color(hex: "#FF5E7A")

    // MARK: - Domain color worlds

    /// Charge / recovery.
    public static let chargeColor      = Color(hex: "#32D17E")
    public static let chargeDeep       = Color(hex: "#1E6F4F")
    public static let chargeBright      = Color(hex: "#63E6A3")
    public static let chargeGlow       = Color(hex: "#32D17E")
    public static let chargeGradient   = Gradient(colors: [chargeDeep, chargeBright])

    /// Effort / strain.
    public static let effortColor      = Color(hex: "#FF9F0A")
    public static let effortDeep       = Color(hex: "#6D3515")
    public static let effortBright      = Color(hex: "#FFB340")
    public static let effortGlow       = Color(hex: "#FF9F0A")
    public static let effortGradient   = Gradient(colors: [effortDeep, effortBright])

    /// Rest / sleep.
    public static let restColor        = Color(hex: "#64D2FF")
    public static let restDeep         = Color(hex: "#0A84FF")
    public static let restBright        = Color(hex: "#9BE7FF")
    public static let restGlow         = Color(hex: "#64D2FF")
    public static let restGradient     = Gradient(colors: [restDeep, restBright])

    /// Stress.
    public static let stressColor      = Color(hex: "#FF9F0A")
    public static let stressDeep       = Color(hex: "#64D2FF")
    public static let stressBright      = Color(hex: "#FF453A")
    public static let stressGlow       = Color(hex: "#FF9F0A")
    public static let stressGradient   = Gradient(colors: [Color(hex: "#64D2FF"), Color(hex: "#FF9F0A"), Color(hex: "#FF453A")])

    // MARK: Scenic background
    /// Radial canvas: lit center → deep edge. Used by `ScenicHeroBackground`.
    public static let scenicCenter     = Color(hex: "#1C2A30")
    public static let scenicEdge       = Color(hex: "#0F171C")
    /// Star tint for the scenic starfield.
    public static let scenicStar       = Color(hex: "#B7C0C7")

    /// Frosted-card tint endpoints (a subtle dark fill the accent wash sits over).
    public static let cardFillTop      = Color(hex: "#202A31")
    public static let cardFillBottom   = Color(hex: "#121A1F")

    // MARK: - Legacy accent aliases
    //
    // Several older views refer to "gold" tokens. Keep the API but point it at the
    // Goose primary blue/teal accent family so those views no longer render gold.
    public static let gold          = Color(hex: "#64D2FF")
    public static let goldLight     = Color(hex: "#9BE7FF")
    public static let goldDeep      = Color(hex: "#2C5364")
    public static let goldDeepText  = Color(hex: "#06131A")
    public static let signalYellow  = Color(hex: "#FFD60A")
    public static let goldGradient  = Gradient(colors: [goldLight, gold, goldDeep])

    /// Neutral chrome ramp for icon plates and small decorative surfaces.
    public static let titaniumTop   = Color(hex: "#E7EDF0")
    public static let titaniumMid   = Color(hex: "#AAB6BE")
    public static let titaniumLow   = Color(hex: "#66727A")
    public static let titaniumDeep  = Color(hex: "#2E3A41")
    public static let titaniumGradient = Gradient(colors: [titaniumTop, titaniumMid, titaniumLow, titaniumDeep])

    // MARK: - Sampling helpers

    /// Sample the recovery gradient at a recovery score 0...100.
    /// Returns the exact interpolated color used everywhere recovery is tinted.
    public static func recoveryColor(_ score: Double) -> Color {
        sample(stops: recoveryStops, at: score / 100.0)
    }

    /// Sample the strain ("Effort") gradient at a value on NOOP's 0...100 Effort scale.
    public static func strainColor(_ strain: Double) -> Color {
        sample(stops: strainStops, at: strain / 100.0)
    }

    /// Effort tint sampled by a 0...1 fraction (e.g. value/scaleMax), spreading the full ember→amber
    /// ramp. Prefer this for gauge tips / value-tinted accents so a high Effort reads as bright amber
    /// rather than ember. `strainColor(_:)` stays for callers holding a 0...100 value.
    public static func effortTint(fraction: Double) -> Color {
        sample(stops: strainStops, at: min(max(fraction, 0), 1))
    }

    /// The state word for a recovery score, per spec §9.3.
    /// DEPLETED · LOW · MODERATE · PRIMED · PEAK
    public static func recoveryState(_ score: Double) -> String {
        switch score {
        case ..<25:  return "DEPLETED"
        case ..<50:  return "LOW"
        case ..<70:  return "MODERATE"
        case ..<88:  return "PRIMED"
        default:     return "PEAK"
        }
    }

    /// HR-zone color for a 0...5 zone index (clamped).
    public static func hrZoneColor(_ zone: Int) -> Color {
        let z = max(1, min(5, zone))
        return hrZones[z]
    }

    /// Color for a sleep stage by canonical name (awake/light/deep/rem).
    public static func sleepStageColor(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return sleepAwake
        case .light: return sleepLight
        case .deep:  return sleepDeep
        case .rem:   return sleepREM
        }
    }

    // MARK: - Linear gradient stop interpolation

    /// Interpolate a set of gradient stops at a normalized position 0...1.
    /// Clamps out-of-range positions to the end stops.
    public static func sample(stops: [Gradient.Stop], at position: Double) -> Color {
        guard let first = stops.first else { return .clear }
        guard stops.count > 1 else { return first.color }
        let t = min(max(position, 0.0), 1.0)

        // Find the bracketing pair.
        var lower = stops[0]
        var upper = stops[stops.count - 1]
        for i in 0..<(stops.count - 1) {
            let a = stops[i]
            let b = stops[i + 1]
            if t >= a.location && t <= b.location {
                lower = a
                upper = b
                break
            }
        }
        let span = upper.location - lower.location
        let localT = span > 0 ? (t - lower.location) / span : 0
        return interpolate(lower.color, upper.color, localT)
    }

    /// Linear-interpolate two colors in sRGB space.
    static func interpolate(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ca = a.rgbaComponents
        let cb = b.rgbaComponents
        let tt = min(max(t, 0.0), 1.0)
        return Color(
            .sRGB,
            red:   ca.r + (cb.r - ca.r) * tt,
            green: ca.g + (cb.g - ca.g) * tt,
            blue:  ca.b + (cb.b - ca.b) * tt,
            opacity: ca.a + (cb.a - ca.a) * tt
        )
    }
}

// MARK: - Sleep stage enum (shared with Hypnogram)

public enum SleepStage: String, CaseIterable, Sendable {
    case awake
    case light
    case deep
    case rem

    /// Display label.
    public var label: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light"
        case .deep:  return "Deep"
        case .rem:   return "REM"
        }
    }

    /// Vertical band order (top = awake, bottom = deep) for hypnogram layout.
    public var bandRank: Int {
        switch self {
        case .awake: return 0
        case .rem:   return 1
        case .light: return 2
        case .deep:  return 3
        }
    }
}

// MARK: - Color component extraction

extension Color {
    /// Resolve to sRGB RGBA components in 0...1. Works on macOS 13+ via platform color bridge.
    var rgbaComponents: (r: Double, g: Double, b: Double, a: Double) {
        #if canImport(AppKit)
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
        #elseif canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
        #else
        return (0, 0, 0, 1)
        #endif
    }
}

#if DEBUG
#Preview("Palette") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            swatchRow("Surfaces", [
                ("base", StrandPalette.surfaceBase),
                ("raised", StrandPalette.surfaceRaised),
                ("overlay", StrandPalette.surfaceOverlay),
                ("inset", StrandPalette.surfaceInset),
                ("hairline", StrandPalette.hairline),
                ("hairline.strong", StrandPalette.hairlineStrong),
            ])
            swatchRow("Text", [
                ("primary", StrandPalette.textPrimary),
                ("secondary", StrandPalette.textSecondary),
                ("tertiary", StrandPalette.textTertiary),
            ])
            swatchRow("Accent", [
                ("accent", StrandPalette.accent),
                ("hover", StrandPalette.accentHover),
                ("muted", StrandPalette.accentMuted),
            ])
            swatchRow("Gold", [
                ("gold", StrandPalette.gold),
                ("light", StrandPalette.goldLight),
                ("deep", StrandPalette.goldDeep),
                ("deepText", StrandPalette.goldDeepText),
                ("signal", StrandPalette.signalYellow),
            ])
            swatchRow("Titanium", [
                ("top", StrandPalette.titaniumTop),
                ("mid", StrandPalette.titaniumMid),
                ("low", StrandPalette.titaniumLow),
                ("deep", StrandPalette.titaniumDeep),
            ])
            VStack(alignment: .leading, spacing: 8) {
                Text("RECOVERY GRADIENT").font(.caption).foregroundStyle(StrandPalette.textTertiary)
                LinearGradient(gradient: StrandPalette.recoveryGradient, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 36).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("STRAIN RAMP").font(.caption).foregroundStyle(StrandPalette.textTertiary)
                LinearGradient(gradient: StrandPalette.strainGradient, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 36).clipShape(RoundedRectangle(cornerRadius: 8))
            }
            swatchRow("Sleep stages", [
                ("awake", StrandPalette.sleepAwake),
                ("light", StrandPalette.sleepLight),
                ("deep", StrandPalette.sleepDeep),
                ("REM", StrandPalette.sleepREM),
            ])
            swatchRow("HR zones", [
                ("Z1", StrandPalette.zone1), ("Z2", StrandPalette.zone2),
                ("Z3", StrandPalette.zone3), ("Z4", StrandPalette.zone4),
                ("Z5", StrandPalette.zone5),
            ])
        }
        .padding(24)
    }
    .frame(width: 520, height: 760)
    .background(StrandPalette.surfaceBase)
    .preferredColorScheme(.dark)
}

@ViewBuilder
private func swatchRow(_ title: String, _ items: [(String, Color)]) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title.uppercased())
            .font(.caption)
            .foregroundStyle(StrandPalette.textTertiary)
        HStack(spacing: 10) {
            ForEach(items, id: \.0) { name, color in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 64, height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(StrandPalette.hairline, lineWidth: 1))
                    Text(name).font(.system(size: 9)).foregroundStyle(StrandPalette.textSecondary)
                }
            }
        }
    }
}
#endif

import SwiftUI

enum LockInTheme {
    static let surface = Color(red: 0.08, green: 0.09, blue: 0.14)
    static let elevatedSurface = Color(red: 0.12, green: 0.12, blue: 0.19)
    static let ink = Color.white
    static let mutedInk = Color.white.opacity(0.66)
    static let faintInk = Color.white.opacity(0.44)
    static let border = Color.white.opacity(0.12)
    static let strongBorder = Color.white.opacity(0.20)
    static let glass = Color.white.opacity(0.075)
    static let glassStrong = Color.white.opacity(0.12)
    static let blue = Color(red: 0.48, green: 0.68, blue: 0.98)
    static let cyan = Color(red: 0.46, green: 0.86, blue: 0.91)
    static let lavender = Color(red: 0.72, green: 0.64, blue: 0.96)
    static let rose = Color(red: 0.96, green: 0.60, blue: 0.74)
    static let mint = Color(red: 0.55, green: 0.88, blue: 0.73)
    static let amber = Color(red: 0.96, green: 0.74, blue: 0.43)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.06, blue: 0.10),
                Color(red: 0.09, green: 0.09, blue: 0.16),
                Color(red: 0.12, green: 0.09, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.18, green: 0.18, blue: 0.32),
                Color(red: 0.15, green: 0.18, blue: 0.27),
                Color(red: 0.22, green: 0.13, blue: 0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [blue, cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var quietGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.13),
                Color.white.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct LockInLiquidBackground: View {
    enum Density {
        case compact
        case spacious
    }

    var density: Density = .spacious

    @State private var animate = false

    var body: some View {
        ZStack {
            LockInTheme.backgroundGradient

            Circle()
                .fill(LockInTheme.blue.opacity(0.24))
                .frame(width: density == .compact ? 210 : 420, height: density == .compact ? 210 : 420)
                .blur(radius: density == .compact ? 28 : 54)
                .offset(x: animate ? 150 : 82, y: animate ? -120 : -70)

            Circle()
                .fill(LockInTheme.rose.opacity(0.20))
                .frame(width: density == .compact ? 240 : 460, height: density == .compact ? 240 : 460)
                .blur(radius: density == .compact ? 34 : 62)
                .offset(x: animate ? -135 : -72, y: animate ? 160 : 110)

            Circle()
                .fill(LockInTheme.mint.opacity(0.16))
                .frame(width: density == .compact ? 180 : 320, height: density == .compact ? 180 : 320)
                .blur(radius: density == .compact ? 36 : 68)
                .offset(x: animate ? 10 : -24, y: animate ? 36 : -10)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct LockInGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 22
    var opacity: Double = 0.08
    var highlighted: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(highlighted ? opacity + 0.055 : opacity),
                                Color.white.opacity(max(0.025, opacity - 0.025))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(highlighted ? LockInTheme.strongBorder : LockInTheme.border, lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(highlighted ? 0.26 : 0.16),
                radius: highlighted ? 22 : 14,
                y: highlighted ? 12 : 8
            )
    }
}

extension View {
    func lockInGlass(cornerRadius: CGFloat = 22, opacity: Double = 0.08, highlighted: Bool = false) -> some View {
        modifier(LockInGlassModifier(cornerRadius: cornerRadius, opacity: opacity, highlighted: highlighted))
    }
}

struct LockInPrimaryButtonStyle: ButtonStyle {
    var isDisabled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(LockInTheme.primaryGradient, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: LockInTheme.blue.opacity(configuration.isPressed ? 0.12 : 0.24), radius: 14, y: 7)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isDisabled ? 0.48 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct LockInSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(LockInTheme.ink.opacity(0.82))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(LockInTheme.quietGradient, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(LockInTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct LockInIconBadge: View {
    let systemName: String
    var tint: Color = LockInTheme.blue

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

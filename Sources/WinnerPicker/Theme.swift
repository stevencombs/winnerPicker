import AppKit
import SwiftUI

enum Theme {
    static let beige = rgb(0xE8DCC8)
    static let beigeDark = rgb(0xC4B49A)
    static let outline = rgb(0x2A2A2A)
    static let ink = rgb(0x2B2B24)
    static let grey = rgb(0x3D3D36)
    static let orange = rgb(0xF5A623)
    static let yellow = rgb(0xF5E642)
    static let green = rgb(0x7CBA3D)
    static let blue = rgb(0x4AA3D4)
    static let red = rgb(0xC62828)
    static let link = rgb(0x1A4F78)
    static let cream = rgb(0xFFF8EE)
    static let note = rgb(0xFFF3C4)
    static let muted = rgb(0x4A4A3C)

    static let joinURL = "https://www.youtube.com/@retrocombs/join"
    static let joinDisplay = "youtube.com/@retrocombs/join"

    static func press(_ size: CGFloat) -> Font {
        .custom("Press Start 2P", size: size)
    }

    static func mono(_ size: CGFloat) -> Font {
        .custom("VT323", size: size)
    }

    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private static func rgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension View {
    func hardShadow(_ color: Color = .black.opacity(0.55), x: CGFloat = 8, y: CGFloat = 8) -> some View {
        shadow(color: color, radius: 0, x: x, y: y)
    }

    func orangeHeadingShadow() -> some View {
        shadow(color: Theme.orange, radius: 0, x: 3, y: 3)
    }
}

struct StripeBackground: View {
    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Theme.grey)
            )
            let cover = hypot(size.width, size.height)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            // 135° brand band: grey, then orange / yellow / green / blue, then grey.
            context.rotate(by: .degrees(45))
            let bands: [(CGFloat, CGFloat, Color)] = [
                (0.30, 0.38, Theme.orange),
                (0.38, 0.46, Theme.yellow),
                (0.46, 0.54, Theme.green),
                (0.54, 0.62, Theme.blue)
            ]
            for (start, end, color) in bands {
                let y = (start - 0.5) * cover
                let height = (end - start) * cover
                context.fill(
                    Path(CGRect(x: -cover, y: y, width: cover * 2, height: height)),
                    with: .color(color)
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct RainbowPanel<Content: View>: View {
    var padding: CGFloat = 22
    var fillsHeight: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(
                maxWidth: .infinity,
                maxHeight: fillsHeight ? CGFloat.infinity : nil,
                alignment: .topLeading
            )
            .background(Theme.beige)
            .padding(6)
            .background(Theme.outline)
            .padding(4)
            .background(Theme.orange)
            .padding(4)
            .background(Theme.yellow)
            .padding(4)
            .background(Theme.green)
            .padding(4)
            .background(Theme.blue)
            .hardShadow(.black.opacity(0.55), x: 14, y: 14)
    }
}

struct TabLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(Theme.press(15))
            .foregroundStyle(Theme.beige)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.outline)
            .overlay(Rectangle().stroke(Theme.orange, lineWidth: 4))
    }
}

struct PixelButton: View {
    var title: String
    var fill: Color
    var foreground: Color = Theme.ink
    var fontSize: CGFloat = 16
    var action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.press(fontSize))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.outline, lineWidth: 4)
                )
                .hardShadow(Theme.outline, x: 5, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct PrizeTag: View {
    var prize: String
    var fontSize: CGFloat = 36

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text("PRIZE")
                .font(Theme.press(16))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.red)
                .overlay(Rectangle().stroke(Theme.outline, lineWidth: 3))
            Text(prize)
                .font(Theme.mono(fontSize))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
    }
}

struct RuleLine: View {
    var text: String

    var body: some View {
        Text(text)
            .font(Theme.mono(30))
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
            .background(Theme.note)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Theme.outline, style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
            )
    }
}

struct StreamHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.red)
                    .frame(width: 112, height: 112)
                    .offset(x: 6, y: 6)
                BundledImage(name: "retroCombslogo")
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.outline, lineWidth: 5)
                    )
            }
            .frame(width: 124, height: 124, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 10) {
                Text("WINNERPICKER")
                    .font(Theme.press(42))
                    .foregroundStyle(Theme.beige)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .shadow(color: Theme.outline, radius: 0, x: 4, y: 4)
                    .shadow(color: Theme.orange, radius: 0, x: 8, y: 8)
                Text("retroCombs MEMBERS GIVEAWAY  •  THE MODERN 8-BIT USER'S GROUP")
                    .font(Theme.mono(32))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .shadow(color: Theme.outline, radius: 0, x: 3, y: 3)
            }
            Spacer(minLength: 12)
            LiveBadge()
        }
    }
}

struct LiveBadge: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.55)) { context in
            let on = Int(context.date.timeIntervalSinceReferenceDate / 0.55).isMultiple(of: 2)
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .opacity(on ? 1 : 0.35)
                Text("LIVE")
                    .font(Theme.press(16))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.red)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.outline, lineWidth: 4))
            .hardShadow(Theme.outline, x: 5, y: 5)
        }
    }
}

struct StreamTicker: View {
    var lead: String
    var items: [String]

    var body: some View {
        VStack(spacing: 0) {
            Theme.blue.frame(height: 4)
            Theme.green.frame(height: 4)
            Theme.yellow.frame(height: 4)
            Theme.orange.frame(height: 6)
            HStack(spacing: 22) {
                Text(lead)
                    .font(Theme.press(16))
                    .foregroundStyle(Theme.yellow)
                    .lineLimit(1)
                ForEach(items, id: \.self) { item in
                    Text("◆")
                        .font(Theme.mono(32))
                        .foregroundStyle(Theme.orange)
                    Text(item)
                        .font(Theme.mono(32))
                        .foregroundStyle(Theme.beige)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 64)
            .frame(height: 62)
            .frame(maxWidth: .infinity)
            .background(Theme.outline)
        }
    }
}

enum FireworkLevel {
    case off
    case celebrate
    case finale
}

struct BroadcastChrome<Content: View>: View {
    var tickerLead: String
    var tickerItems: [String]
    var fireworks: FireworkLevel = .off
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            StripeBackground()
            switch fireworks {
            case .off:
                EmptyView()
            case .celebrate:
                PixelFireworksView(finale: false)
            case .finale:
                PixelFireworksView(finale: true)
            }
            VStack(spacing: 0) {
                StreamHeader()
                    .padding(.horizontal, 64)
                    .padding(.top, 26)
                content()
                    .padding(.horizontal, 56)
                    .padding(.top, 34)
                    .padding(.bottom, 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                StreamTicker(lead: tickerLead, items: tickerItems)
            }
        }
        .frame(width: 1920, height: 1080)
    }
}

struct Stage16x9<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 1920, geo.size.height / 1080)
            content()
                .frame(width: 1920, height: 1080)
                .scaleEffect(scale, anchor: .center)
                .frame(width: 1920 * scale, height: 1080 * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.grey)
    }
}

enum WindowControls {
    @MainActor
    static func toggleFullScreen() {
        let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first
        window?.toggleFullScreen(nil)
    }
}

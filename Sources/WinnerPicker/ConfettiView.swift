import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let size: CGFloat
    let color: Color
    let rotation: Double
    let drift: CGFloat
    let speed: Double
    let delay: Double
    let isCircle: Bool
    let isRibbon: Bool

    static func burst(count: Int = 180) -> [ConfettiPiece] {
        let palette: [Color] = [
            Theme.gold,
            Theme.goldDeep,
            Color(red: 1.00, green: 0.92, blue: 0.55),
            Color(red: 0.95, green: 0.35, blue: 0.38),
            Color(red: 0.35, green: 0.72, blue: 0.95),
            Color(red: 0.45, green: 0.88, blue: 0.55),
            Color.white
        ]

        return (0..<count).map { _ in
            let kind = Int.random(in: 0...2)
            return ConfettiPiece(
                x: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 14...28),
                color: palette.randomElement() ?? Theme.gold,
                rotation: Double.random(in: 0...360),
                drift: CGFloat.random(in: -70...70),
                speed: Double.random(in: 3.2...6.2),
                delay: Double.random(in: 0...1.8),
                isCircle: kind == 0,
                isRibbon: kind == 2
            )
        }
    }
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = ConfettiPiece.burst()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            Canvas { context, size in
                guard size.width > 1, size.height > 1 else { return }

                let now = timeline.date.timeIntervalSinceReferenceDate

                for piece in pieces {
                    let elapsed = now + piece.delay
                    let progress = elapsed.truncatingRemainder(dividingBy: piece.speed) / piece.speed
                    let y = CGFloat(progress) * (size.height + 80) - 40
                    let x = piece.x * size.width + sin(progress * .pi * 2) * piece.drift
                    let angle = Angle.degrees(piece.rotation + progress * 420)

                    var inner = context
                    inner.translateBy(x: x, y: y)
                    inner.rotate(by: angle)
                    inner.opacity = 0.95

                    let rect: CGRect
                    if piece.isRibbon {
                        rect = CGRect(x: -piece.size / 6, y: -piece.size, width: piece.size / 3, height: piece.size * 1.6)
                    } else if piece.isCircle {
                        rect = CGRect(x: -piece.size / 2, y: -piece.size / 2, width: piece.size, height: piece.size)
                    } else {
                        rect = CGRect(x: -piece.size / 2, y: -piece.size / 3.4, width: piece.size, height: piece.size * 0.55)
                    }

                    let path = piece.isCircle
                        ? Path(ellipseIn: rect)
                        : Path(roundedRect: rect, cornerRadius: 2)

                    inner.fill(path, with: .color(piece.color))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

struct SunburstView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { timeline in
            let turn = timeline.date.timeIntervalSinceReferenceDate * 6

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = hypot(size.width, size.height)
                let rays = 28

                for index in 0..<rays {
                    let start = Angle.degrees(turn + Double(index) * (360 / Double(rays)))
                    let end = Angle.degrees(turn + Double(index) * (360 / Double(rays)) + 6)
                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
                    path.closeSubpath()
                    context.fill(path, with: .color(Theme.gold.opacity(index.isMultiple(of: 2) ? 0.05 : 0.025)))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

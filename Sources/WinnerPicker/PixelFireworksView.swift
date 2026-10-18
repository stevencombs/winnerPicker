import SwiftUI

struct PixelFireworksView: View {
    var finale: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
            Canvas { context, size in
                var context = context
                drawFireworks(
                    context: &context,
                    size: size,
                    time: timeline.date.timeIntervalSinceReferenceDate,
                    finale: finale
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FireworkBurst {
    var x: CGFloat
    var y: CGFloat
    var start: Double
    var rays: Int
    var radius: CGFloat
    var pixel: CGFloat
    var spin: Double
    var shift: Int
}

private let fireworkPalette: [Color] = [
    Theme.orange,
    Theme.yellow,
    Theme.green,
    Theme.blue,
    Theme.red,
    Theme.cream
]

private func drawFireworks(
    context: inout GraphicsContext,
    size: CGSize,
    time: TimeInterval,
    finale: Bool
) {
    guard size.width > 1, size.height > 1 else { return }
    let script = fireworkScript(finale: finale)
    let cycle = time.truncatingRemainder(dividingBy: script.period)

    for burst in script.bursts {
        let age = cycle - burst.start
        guard age > 0, age < 1.9 else { continue }
        drawBurst(burst, age: age, in: &context, size: size)
    }
}

private func drawBurst(
    _ burst: FireworkBurst,
    age: Double,
    in context: inout GraphicsContext,
    size: CGSize
) {
    let origin = CGPoint(x: burst.x * size.width, y: burst.y * size.height)
    let scale = min(size.width, size.height) / 1080

    if age < 0.2 {
        let flash = burst.pixel * scale * 1.8 * CGFloat(1 - age / 0.2)
        fillSquare(
            context: &context,
            center: origin,
            side: flash,
            color: Theme.cream.opacity(0.95)
        )
    }

    let head = CGFloat(min(age / 0.8, 1)) * burst.radius * scale
    let lifeFade = CGFloat(max(0, 1 - max(0, age - 0.35) / 1.35))

    for ray in 0..<burst.rays {
        let angle = burst.spin + (Double(ray) / Double(burst.rays)) * (.pi * 2)
        let dx = CGFloat(cos(angle))
        let dy = CGFloat(sin(angle))
        let steps = finaleSteps(burst.rays)

        for step in 0..<steps {
            let spacing = (burst.radius * scale) / 15
            let dist = head - CGFloat(step) * spacing
            guard dist > 6 else { continue }
            let fade = (1 - CGFloat(step) / CGFloat(steps + 1)) * lifeFade
            guard fade > 0.05 else { continue }
            let drop = CGFloat(age) * 22 * scale + CGFloat(step) * 1.5 * scale
            let center = CGPoint(
                x: origin.x + dx * dist,
                y: origin.y + dy * dist + drop
            )
            let side = max(3, burst.pixel * scale * (1 - CGFloat(step) / CGFloat(steps + 3)))
            let color = fireworkPalette[(step + burst.shift + ray) % fireworkPalette.count]
            fillSquare(context: &context, center: center, side: side, color: color.opacity(Double(fade)))
        }

        if head > 12 {
            let sparkSide = max(2, burst.pixel * scale * 0.42)
            let wobble = CGFloat(sin(angle * 4 + age * 9)) * 7 * scale
            let spark = CGPoint(
                x: origin.x + dx * head + wobble,
                y: origin.y + dy * head + CGFloat(age) * 28 * scale
            )
            let sparkFade = 0.85 * lifeFade
            if sparkFade > 0.05 {
                fillSquare(
                    context: &context,
                    center: spark,
                    side: sparkSide,
                    color: Theme.cream.opacity(Double(sparkFade))
                )
            }
        }
    }
}

private func fillSquare(context: inout GraphicsContext, center: CGPoint, side: CGFloat, color: Color) {
    let rect = CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
    context.fill(Path(rect), with: .color(color))
}

private func finaleSteps(_ rays: Int) -> Int {
    rays > 16 ? 9 : 7
}

private func fireworkScript(finale: Bool) -> (period: Double, bursts: [FireworkBurst]) {
    if finale {
        return (6.4, [
            FireworkBurst(x: 0.08, y: 0.18, start: 0.00, rays: 20, radius: 340, pixel: 20, spin: 0.2, shift: 0),
            FireworkBurst(x: 0.92, y: 0.16, start: 0.10, rays: 18, radius: 320, pixel: 18, spin: 0.5, shift: 2),
            FireworkBurst(x: 0.14, y: 0.78, start: 0.18, rays: 18, radius: 300, pixel: 18, spin: 1.1, shift: 1),
            FireworkBurst(x: 0.88, y: 0.80, start: 0.28, rays: 20, radius: 340, pixel: 20, spin: 0.8, shift: 3),
            FireworkBurst(x: 0.50, y: 0.10, start: 0.40, rays: 16, radius: 260, pixel: 16, spin: 0.3, shift: 4),
            FireworkBurst(x: 0.06, y: 0.48, start: 1.70, rays: 18, radius: 300, pixel: 18, spin: 1.4, shift: 1),
            FireworkBurst(x: 0.94, y: 0.46, start: 1.82, rays: 18, radius: 310, pixel: 18, spin: 0.6, shift: 0),
            FireworkBurst(x: 0.28, y: 0.90, start: 1.95, rays: 16, radius: 280, pixel: 16, spin: 0.9, shift: 2),
            FireworkBurst(x: 0.72, y: 0.92, start: 2.08, rays: 18, radius: 300, pixel: 18, spin: 0.4, shift: 5),
            FireworkBurst(x: 0.18, y: 0.12, start: 3.40, rays: 20, radius: 360, pixel: 22, spin: 0.15, shift: 2),
            FireworkBurst(x: 0.82, y: 0.14, start: 3.52, rays: 20, radius: 360, pixel: 22, spin: 0.7, shift: 0),
            FireworkBurst(x: 0.10, y: 0.86, start: 3.66, rays: 18, radius: 320, pixel: 18, spin: 1.2, shift: 3),
            FireworkBurst(x: 0.90, y: 0.84, start: 3.78, rays: 18, radius: 330, pixel: 20, spin: 0.35, shift: 1),
            FireworkBurst(x: 0.40, y: 0.08, start: 4.90, rays: 16, radius: 240, pixel: 16, spin: 0.55, shift: 4),
            FireworkBurst(x: 0.62, y: 0.93, start: 5.05, rays: 18, radius: 280, pixel: 18, spin: 1.0, shift: 2)
        ])
    }

    return (8.0, [
        FireworkBurst(x: 0.10, y: 0.22, start: 0.00, rays: 14, radius: 220, pixel: 14, spin: 0.4, shift: 0),
        FireworkBurst(x: 0.90, y: 0.20, start: 0.16, rays: 14, radius: 210, pixel: 14, spin: 0.9, shift: 2),
        FireworkBurst(x: 0.12, y: 0.80, start: 0.30, rays: 12, radius: 190, pixel: 13, spin: 1.2, shift: 1),
        FireworkBurst(x: 0.88, y: 0.78, start: 2.50, rays: 14, radius: 220, pixel: 14, spin: 0.2, shift: 3),
        FireworkBurst(x: 0.08, y: 0.48, start: 2.66, rays: 12, radius: 180, pixel: 12, spin: 0.7, shift: 4),
        FireworkBurst(x: 0.93, y: 0.50, start: 2.80, rays: 12, radius: 180, pixel: 12, spin: 1.5, shift: 0),
        FireworkBurst(x: 0.22, y: 0.12, start: 5.10, rays: 14, radius: 200, pixel: 14, spin: 0.3, shift: 5),
        FireworkBurst(x: 0.78, y: 0.90, start: 5.28, rays: 14, radius: 210, pixel: 14, spin: 0.85, shift: 1),
        FireworkBurst(x: 0.50, y: 0.08, start: 5.44, rays: 10, radius: 160, pixel: 12, spin: 0.1, shift: 2)
    ])
}

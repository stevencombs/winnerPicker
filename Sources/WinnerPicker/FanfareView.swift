import SwiftUI

private enum RevealPhase {
    case shuffling
    case announcing
    case revealed
}

struct FanfareView: View {
    @Bindable var model: DrawModel
    @State private var phase: RevealPhase = .shuffling
    @State private var cyclingName = ""
    @State private var nameScale = 0.6
    @State private var nameOpacity = 0.0
    @State private var glow = 0.0
    @State private var shuffleTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            radialGlow
            SunburstView().opacity(phase == .revealed ? 1 : 0.25)
            ConfettiView()
                .opacity(phase == .revealed ? 1 : 0)
                .id(model.drawGeneration)

            VStack(spacing: 22) {
                Spacer()
                stageContent
                Spacer()
                controls
            }
            .padding(40)
        }
        .onAppear(perform: startReveal)
        .onDisappear {
            shuffleTask?.cancel()
            FanfareAudio.shared.stop()
        }
        .onChange(of: model.drawGeneration) { _, _ in
            startReveal()
        }
    }

    private var radialGlow: some View {
        RadialGradient(
            colors: [
                Theme.gold.opacity(phase == .revealed ? 0.28 : 0.10),
                Theme.background
            ],
            center: .center,
            startRadius: 20,
            endRadius: 520
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: phase == .revealed)
    }

    @ViewBuilder
    private var stageContent: some View {
        switch phase {
        case .shuffling:
            VStack(spacing: 16) {
                Text("SHUFFLING THE NAMES")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(Theme.gold)

                Text(cyclingName.isEmpty ? "…" : cyclingName)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: 700)
                    .contentTransition(.opacity)
            }

        case .announcing:
            Text("AND THE WINNER IS")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(6)
                .foregroundStyle(Theme.gold)
                .shadow(color: Theme.gold.opacity(0.4), radius: 16)

        case .revealed:
            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    Image(systemName: "party.popper.fill")
                    Text("AND THE WINNER IS")
                    Image(systemName: "party.popper.fill")
                        .scaleEffect(x: -1, y: 1)
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .tracking(4)
                .foregroundStyle(Theme.gold)

                Text(model.winner)
                    .font(.system(size: 72, weight: .heavy, design: .serif))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.35)
                    .lineLimit(3)
                    .padding(.horizontal, 24)
                    .scaleEffect(nameScale)
                    .opacity(nameOpacity)
                    .shadow(color: Theme.gold.opacity(glow), radius: 30, y: 4)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.gold, Theme.goldDeep],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.top, 8)
                    .opacity(nameOpacity)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button("New Drawing") {
                model.startNewDrawing()
            }
            .buttonStyle(GhostButtonStyle())
            .accessibilityLabel("New Drawing")

            Button("Pick Again") {
                model.pickAgain()
            }
            .buttonStyle(GoldButtonStyle())
            .accessibilityLabel("Pick Again")
        }
        .opacity(phase == .revealed ? 1 : 0)
        .animation(.easeInOut(duration: 0.35), value: phase)
    }

    private func startReveal() {
        shuffleTask?.cancel()
        FanfareAudio.shared.stop()
        phase = .shuffling
        cyclingName = model.shuffledNames.first(where: { $0 != model.winner }) ?? model.winner
        nameScale = 0.6
        nameOpacity = 0
        glow = 0
        FanfareAudio.shared.playDrumroll()

        shuffleTask = Task { @MainActor in
            await runShuffle()
            guard !Task.isCancelled else { return }
            FanfareAudio.shared.stop()
            withAnimation(.easeInOut(duration: 0.35)) {
                phase = .announcing
            }
            try? await Task.sleep(for: .milliseconds(1000))
            guard !Task.isCancelled else { return }
            revealWinner()
        }
    }

    private func runShuffle() async {
        let pool = model.shuffledNames
        guard !pool.isEmpty else { return }

        let duration = 5.0
        var elapsed = 0.0
        var index = pool.count > 1 ? 1 : 0

        while elapsed < duration {
            guard !Task.isCancelled else { return }
            cyclingName = pool[index % pool.count]

            let progress = min(elapsed / duration, 1)
            let eased = progress * progress * progress
            let interval = 0.065 + (eased * 0.42)
            let sleepFor = min(interval, duration - elapsed)
            try? await Task.sleep(for: .seconds(sleepFor))
            elapsed += sleepFor

            if pool.count > 1 {
                index += 1
                if elapsed + interval >= duration, pool[index % pool.count] == model.winner {
                    index += 1
                }
            }
        }
    }

    private func revealWinner() {
        phase = .revealed
        FanfareAudio.shared.playFanfare()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.68)) {
            nameScale = 1
            nameOpacity = 1
            glow = 0.55
        }
    }
}

private struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.12, green: 0.09, blue: 0.04))
            .padding(.horizontal, 26)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Theme.gold, Theme.goldDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.cream)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Theme.elevated.opacity(0.85))
            .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

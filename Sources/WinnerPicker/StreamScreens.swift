import SwiftUI

private let drawTicker = [
    "Subscribe & ring the bell",
    "Members get entered in future giveaways",
    "Scan the QR to join",
    "retrocombs.com"
]

private let winnerTicker = [
    "Members-only giveaways",
    "Join at youtube.com/@retrocombs/join",
    "Sundays live • retrocombs.com"
]

private enum RevealPhase {
    case ready
    case shuffling
    case announcing
}

struct DrawStreamView: View {
    @Bindable var model: DrawModel
    @State private var phase: RevealPhase = .ready
    @State private var cyclingName = ""
    @State private var previousName = ""
    @State private var shuffleTask: Task<Void, Never>?

    var body: some View {
        BroadcastChrome(
            tickerLead: "SUNDAYS LIVE",
            tickerItems: drawTicker
        ) {
            HStack(alignment: .top, spacing: 28) {
                drawPanel
                membersPanel
                    .frame(width: 430)
            }
        }
        .onAppear(perform: consumeShuffle)
        .onChange(of: model.shuffleArmed) { _, armed in
            if armed { consumeShuffle() }
        }
        .onDisappear {
            shuffleTask?.cancel()
            FanfareAudio.shared.stopDrumroll()
        }
    }

    private var drawPanel: some View {
        RainbowPanel(padding: 26, fillsHeight: true) {
            VStack(alignment: .leading, spacing: 14) {
                PrizeTag(prize: currentPrize, fontSize: 34)
                slot
                    .frame(height: 210)
                    .onTapGesture { model.space() }
                HStack(alignment: .firstTextBaseline) {
                    Text("\(model.pool.count)")
                        .font(Theme.press(22))
                        .foregroundStyle(Theme.red)
                    Text(model.pool.count == 1 ? "ENTRANT" : "ENTRANTS")
                        .font(Theme.press(16))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                }
                chips
                VStack(alignment: .leading, spacing: 6) {
                    RuleLine(text: "Must be present in chat to win")
                    RuleLine(text: "US supporters only  •  overseas winners can cover shipping")
                }
                Spacer(minLength: 8)
                keyHints
            }
        }
        .overlay(alignment: .topLeading) {
            TabLabel(text: "▶  NOW DRAWING  •  \(model.slot + 1) OF \(max(model.prizes.count, 1))")
                .padding(.leading, 36)
                .offset(y: -18)
        }
    }

    private var currentPrize: String {
        model.prizes.indices.contains(model.slot) ? model.prizes[model.slot] : "Prize"
    }

    @ViewBuilder
    private var slot: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.blue)
                .offset(x: 8, y: 8)
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.outline)
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.beigeDark)
                .padding(6)
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.outline)
                .padding(12)

            VStack(spacing: 12) {
                switch phase {
                case .ready:
                    Text("READY")
                        .font(Theme.press(18))
                        .foregroundStyle(Theme.orange)
                    Text("PRESS SPACE")
                        .font(Theme.press(36))
                        .foregroundStyle(Theme.cream)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                case .shuffling:
                    Text("SHUFFLING THE NAMES…")
                        .font(Theme.press(16))
                        .foregroundStyle(Theme.orange)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if !previousName.isEmpty {
                        Text(previousName)
                            .font(Theme.press(22))
                            .foregroundStyle(Theme.beige.opacity(0.35))
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                    }
                    Text(cyclingName.isEmpty ? "…" : cyclingName)
                        .font(Theme.press(shuffleSize))
                        .foregroundStyle(Theme.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.35)
                case .announcing:
                    Text("AND THE WINNER IS")
                        .font(Theme.press(28))
                        .foregroundStyle(Theme.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var shuffleSize: CGFloat {
        switch cyclingName.count {
        case ...14: return 48
        case ...20: return 36
        default: return 28
        }
    }

    private var chips: some View {
        let pool = model.pool
        let shown = Array(pool.prefix(15))
        return FlowLayout(spacing: 8) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, name in
                Text(name)
                    .font(Theme.mono(28))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .roundedPlate(fill: Theme.cream, radius: 8, lineWidth: 3, shadowX: 3, shadowY: 3)
            }
            if pool.count > shown.count {
                Text("+\(pool.count - shown.count) MORE")
                    .font(Theme.mono(28))
                    .foregroundStyle(Theme.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 1)
                    .background {
                        RoundedRectangle(cornerRadius: 8).fill(Theme.outline)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keyHints: some View {
        HStack(spacing: 14) {
            Spacer()
            keyHint("SPACE", "draw")
            keyHint("R", "redraw")
            keyHint("N", "new list")
            keyHint("F", "full screen")
        }
    }

    private func keyHint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Text(key)
                .font(Theme.press(11))
                .foregroundStyle(Theme.outline)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .roundedPlate(fill: Theme.cream, radius: 4, lineWidth: 3, shadowX: 2, shadowY: 2)
            Text(label)
                .font(Theme.mono(26))
                .foregroundStyle(Theme.muted)
        }
    }

    private var membersPanel: some View {
        RainbowPanel(padding: 20, fillsHeight: true) {
            VStack(spacing: 12) {
                Text("JOIN TO ENTER\nFUTURE GIVEAWAYS")
                    .font(Theme.press(16))
                    .foregroundStyle(Theme.outline)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                MembershipQR(side: 210)
                Text(Theme.joinDisplay)
                    .font(Theme.mono(28))
                    .foregroundStyle(Theme.link)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text("Members-only giveaways")
                    .font(Theme.mono(26))
                    .foregroundStyle(Theme.ink)
                BadgeRow(side: 52)
                subscribeCard
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .topLeading) {
            TabLabel(text: "▶  MEMBERS")
                .padding(.leading, 28)
                .offset(y: -18)
        }
    }

    private var subscribeCard: some View {
        HStack(spacing: 12) {
            BundledImage(name: "logo-retrocombs")
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.outline, lineWidth: 3))
            VStack(alignment: .leading, spacing: 6) {
                Text("SUBSCRIBE")
                    .font(Theme.press(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Theme.red)
                    .overlay(Rectangle().stroke(Theme.outline, lineWidth: 3))
                Text("@retroCombs")
                    .font(Theme.mono(26))
                    .foregroundStyle(Theme.link)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .roundedPlate(fill: Theme.cream, radius: 14, lineWidth: 4, shadowX: 4, shadowY: 4)
    }

    private func consumeShuffle() {
        guard model.shuffleArmed else { return }
        model.shuffleArmed = false
        let order = model.shuffleOrder
        let winner = model.pendingWinner
        guard !order.isEmpty else { return }

        shuffleTask?.cancel()
        phase = .shuffling
        previousName = ""
        cyclingName = order.first(where: { $0.caseInsensitiveCompare(winner) != .orderedSame }) ?? winner
        FanfareAudio.shared.playDrumroll()

        shuffleTask = Task { @MainActor in
            await runShuffle(order: order, winner: winner)
            guard !Task.isCancelled, model.screen == .drawing else { return }
            FanfareAudio.shared.stopDrumroll()
            phase = .announcing
            try? await Task.sleep(for: .milliseconds(1000))
            guard !Task.isCancelled, model.screen == .drawing else { return }
            model.finishReveal()
        }
    }

    private func runShuffle(order: [String], winner: String) async {
        let duration = 5.0
        var elapsed = 0.0
        var index = order.count > 1 ? 1 : 0

        while elapsed < duration {
            guard !Task.isCancelled else { return }
            let name = order[index % order.count]
            if name != cyclingName {
                previousName = cyclingName
            }
            cyclingName = name

            let progress = min(elapsed / duration, 1)
            let eased = progress * progress * progress
            let interval = 0.065 + (eased * 0.42)
            let sleepFor = min(interval, duration - elapsed)
            try? await Task.sleep(for: .seconds(sleepFor))
            guard !Task.isCancelled else { return }
            elapsed += sleepFor

            if order.count > 1 {
                index += 1
                if elapsed + interval >= duration, order[index % order.count].caseInsensitiveCompare(winner) == .orderedSame {
                    index += 1
                }
            }
        }
    }
}

struct WinnerStreamView: View {
    @Bindable var model: DrawModel
    @State private var started = Date()

    var body: some View {
        BroadcastChrome(
            tickerLead: "CONGRATS!",
            tickerItems: winnerTicker,
            fireworks: .celebrate,
            under: { sideColumns },
            over: { centerColumn }
        )
        .onAppear {
            started = Date()
            FanfareAudio.shared.playFanfare()
        }
        .onDisappear {
            FanfareAudio.shared.stopFanfare()
        }
    }

    private var winnerPanel: some View {
        RainbowPanel(padding: 28, fillsHeight: true) {
            VStack(spacing: 18) {
                Text("★  AND THE WINNER IS  ★")
                    .font(Theme.press(20))
                    .foregroundStyle(Theme.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 8)
                Text(currentName)
                    .font(Theme.press(nameSize))
                    .foregroundStyle(Theme.outline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.35)
                    .padding(.vertical, 8)
                PrizeTag(prize: currentPrize, fontSize: 36)
                    .frame(maxWidth: .infinity)
                RuleLine(text: "US supporters only  •  overseas winners can cover shipping")
                claimRow
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .topLeading) {
            TabLabel(text: "▶  WINNER \(model.slot + 1) OF \(max(model.prizes.count, 1))")
                .padding(.leading, 36)
                .offset(y: -18)
        }
    }

    private var currentName: String {
        guard model.winners.indices.contains(model.slot), let name = model.winners[model.slot] else {
            return model.pendingWinner
        }
        return name
    }

    private var currentPrize: String {
        model.prizes.indices.contains(model.slot) ? model.prizes[model.slot] : "Prize"
    }

    private var nameSize: CGFloat {
        switch currentName.count {
        case ...12: return 64
        case ...16: return 48
        case ...22: return 36
        default: return 28
        }
    }

    private var claimRow: some View {
        TimelineView(.periodic(from: started, by: 0.25)) { context in
            let left = max(0, model.claimDuration - context.date.timeIntervalSince(started))
            let expired = left <= 0
            HStack(spacing: 14) {
                Text("CLAIM IN CHAT WITHIN")
                    .font(Theme.press(14))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(Theme.clock(left))
                    .font(Theme.press(26))
                    .foregroundStyle(expired ? Theme.ink : Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .roundedPlate(
                        fill: expired ? Theme.yellow : Theme.red,
                        radius: 8,
                        lineWidth: 4,
                        shadowX: 4,
                        shadowY: 4
                    )
            }
        }
    }

    private var winnersCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WINNERS TODAY")
                .font(Theme.press(12))
                .foregroundStyle(Theme.red)
                .padding(.bottom, 4)
            ForEach(0..<model.prizes.count, id: \.self) { index in
                winnerRow(index)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxHeight: .infinity, alignment: .top)
        .roundedPlate(fill: Theme.cream, radius: 18, lineWidth: 5, shadowX: 7, shadowY: 7)
    }

    private func winnerRow(_ index: Int) -> some View {
        let name = model.winners.indices.contains(index) ? model.winners[index] : nil
        let isCurrent = index == model.slot && name != nil
        let isFuture = name == nil
        let nameSize: CGFloat = model.prizes.count > 6 ? 24 : 28
        return VStack(alignment: .leading, spacing: 0) {
            Text("\(index + 1).  \(name ?? "???")")
                .font(Theme.mono(nameSize))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(model.prizes[index])
                .font(Theme.mono(nameSize - 4))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .padding(.vertical, 3)
        .padding(.leading, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? Theme.yellow : Color.clear)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isCurrent ? Theme.red : Theme.orange)
                .frame(width: 6)
        }
        .opacity(isFuture ? 0.45 : 1)
    }

    private var membershipCard: some View {
        VStack(spacing: 8) {
            Text("MEMBERS-ONLY\nGIVEAWAYS")
                .font(Theme.press(13))
                .foregroundStyle(Theme.outline)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            MembershipQR(side: 180)
            Text("youtube.com/\n@retrocombs/join")
                .font(Theme.mono(24))
                .foregroundStyle(Theme.link)
                .multilineTextAlignment(.center)
            BadgeRow(side: 36)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxHeight: .infinity)
        .roundedPlate(fill: Theme.cream, radius: 18, lineWidth: 5, shadowX: 7, shadowY: 7)
    }

    /// Left and right cards, under the fireworks. The hidden controls keep the columns the same height as the live row.
    private var sideColumns: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 18) {
                winnersCard
                    .frame(width: 300)
                Color.clear
                membershipCard
                    .frame(width: 280)
            }
            .frame(maxHeight: .infinity)
            controls
                .hidden()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// Winner card and buttons stay above the fireworks so the name stays readable.
    private var centerColumn: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 18) {
                Color.clear
                    .frame(width: 300)
                    .allowsHitTesting(false)
                winnerPanel
                Color.clear
                    .frame(width: 280)
                    .allowsHitTesting(false)
            }
            .frame(maxHeight: .infinity)
            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var controls: some View {
        HStack(spacing: 18) {
            PixelButton(title: "◄  NEW LIST", fill: Theme.cream, action: model.newList)
            PixelButton(title: "DRAW AGAIN", fill: Theme.orange, action: model.redraw)
            PixelButton(title: "NEXT PRIZE  ►", fill: Theme.green, action: model.advance)
        }
    }
}

struct RecapStreamView: View {
    @Bindable var model: DrawModel

    private var columns: Int {
        model.prizes.count > 5 ? 2 : 1
    }

    var body: some View {
        BroadcastChrome(
            tickerLead: "TODAY'S WINNERS",
            tickerItems: winnerTicker,
            fireworks: .finale,
            under: { EmptyView() },
            over: {
                recapColumn
            }
        )
    }

    private var recapColumn: some View {
        VStack(spacing: 18) {
            RainbowPanel(padding: 32, fillsHeight: true) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Every winner from this stream")
                        .font(Theme.mono(32))
                        .foregroundStyle(Theme.muted)
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: columns),
                        alignment: .leading,
                        spacing: 14
                    ) {
                        ForEach(0..<model.prizes.count, id: \.self) { index in
                            recapRow(index)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            .overlay(alignment: .topLeading) {
                TabLabel(text: "▶  TODAY'S WINNERS")
                    .padding(.leading, 36)
                    .offset(y: -18)
            }
            .frame(maxWidth: 1280)
            PixelButton(title: "◄  NEW LIST", fill: Theme.cream, fontSize: 16, action: model.newList)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func recapRow(_ index: Int) -> some View {
        let name = (model.winners.indices.contains(index) ? model.winners[index] : nil) ?? "???"
        let prize = model.prizes[index]
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(String(format: "%02d", index + 1))
                .font(Theme.press(14))
                .foregroundStyle(Theme.red)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(Theme.press(name.count > 16 ? 14 : 18))
                    .foregroundStyle(Theme.outline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                Text(prize)
                    .font(Theme.mono(28))
                    .foregroundStyle(Theme.link)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.vertical, 4)
        .padding(.leading, 8)
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.orange).frame(width: 6)
        }
    }
}

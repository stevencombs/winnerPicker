import SwiftUI

struct SetupView: View {
    @Bindable var model: DrawModel
    @FocusState private var editorFocused: Bool

    var body: some View {
        ZStack {
            StripeBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    RainbowPanel(padding: 26) {
                        VStack(alignment: .leading, spacing: 18) {
                            namesBlock
                            winnersBlock
                            prizeBlock
                            timerBlock
                            goLive
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        TabLabel(text: "▶  SETUP")
                            .offset(x: 28, y: -16)
                    }
                    .padding(.top, 18)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 28)
                .frame(maxWidth: 980)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { editorFocused = true }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            BundledImage(name: "retroCombslogo")
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.outline, lineWidth: 4))
                .hardShadow(Theme.red, x: 4, y: 4)
            VStack(alignment: .leading, spacing: 6) {
                Text("WINNERPICKER")
                    .font(Theme.press(22))
                    .foregroundStyle(Theme.beige)
                    .shadow(color: Theme.outline, radius: 0, x: 3, y: 3)
                    .shadow(color: Theme.orange, radius: 0, x: 6, y: 6)
                Text("Operator setup  •  this screen stays off air")
                    .font(Theme.mono(28))
                    .foregroundStyle(Theme.cream)
                    .shadow(color: Theme.outline, radius: 0, x: 2, y: 2)
            }
            Spacer()
        }
    }

    private var namesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ENTRANTS")
                .font(Theme.press(12))
                .foregroundStyle(Theme.ink)
                .orangeHeadingShadow()
            ZStack(alignment: .topLeading) {
                if model.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("PixelPete64, SIDChipSally, ByteBandit")
                        .font(Theme.mono(30))
                        .foregroundStyle(Theme.muted.opacity(0.7))
                        .padding(14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $model.rawInput)
                    .font(Theme.mono(30))
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .focused($editorFocused)
                    .padding(8)
            }
            .frame(minHeight: 160)
            .background(Theme.cream)
            .overlay(Rectangle().stroke(Theme.outline, lineWidth: 3))
            HStack {
                Text("\(model.names.count)")
                    .font(Theme.press(18))
                    .foregroundStyle(model.names.isEmpty ? Theme.muted : Theme.red)
                Text(model.names.count == 1 ? "ENTRANT" : "ENTRANTS")
                    .font(Theme.press(12))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("Commas or new lines. Members-only list. Duplicates are skipped.")
                    .font(Theme.mono(22))
                    .foregroundStyle(Theme.muted)
            }
        }
    }

    private var winnersBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NUMBER OF WINNERS")
                .font(Theme.press(12))
                .foregroundStyle(Theme.ink)
                .orangeHeadingShadow()
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { count in
                    Button {
                        model.winnerCount = count
                    } label: {
                        Text("\(count)")
                            .font(Theme.press(12))
                            .foregroundStyle(model.winnerCount == count ? Theme.ink : Theme.beige)
                            .frame(width: 36, height: 36)
                            .background(model.winnerCount == count ? Theme.orange : Theme.outline)
                            .overlay(Rectangle().stroke(Theme.outline, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(count) winners")
                }
            }
        }
    }

    private var prizeBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PRIZES")
                    .font(Theme.press(12))
                    .foregroundStyle(Theme.ink)
                    .orangeHeadingShadow()
                Spacer()
                Toggle("Same prize for all", isOn: $model.samePrizeForAll)
                    .font(Theme.mono(26))
                    .foregroundStyle(Theme.ink)
                    .onChange(of: model.samePrizeForAll) { _, same in
                        guard !same else { return }
                        for index in model.individualPrizes.indices
                        where model.individualPrizes[index]
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty {
                            model.individualPrizes[index] = model.sharedPrize
                        }
                    }
            }
            if model.samePrizeForAll {
                prizeField(text: $model.sharedPrize, prompt: "Mystery Retro Box")
            } else {
                ForEach(0..<model.winnerCount, id: \.self) { index in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(Theme.press(12))
                            .foregroundStyle(Theme.red)
                            .frame(width: 28)
                        prizeField(text: $model.individualPrizes[index], prompt: "Prize \(index + 1)")
                    }
                }
            }
        }
    }

    private func prizeField(text: Binding<String>, prompt: String) -> some View {
        TextField("", text: text, prompt: Text(prompt))
            .textFieldStyle(.plain)
            .font(Theme.mono(30))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.cream)
            .overlay(Rectangle().stroke(Theme.outline, lineWidth: 3))
    }

    private var timerBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CLAIM TIMER")
                .font(Theme.press(12))
                .foregroundStyle(Theme.ink)
                .orangeHeadingShadow()
            HStack(spacing: 18) {
                Stepper(value: $model.claimMinutes, in: 0...30) {
                    Text("\(model.claimMinutes) min")
                        .font(Theme.mono(28))
                        .foregroundStyle(Theme.ink)
                }
                Stepper(value: $model.claimSeconds, in: 0...59) {
                    Text(String(format: "%02d sec", model.claimSeconds))
                        .font(Theme.mono(28))
                        .foregroundStyle(Theme.ink)
                }
                Text(model.claimClock)
                    .font(Theme.press(18))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Theme.red)
                    .overlay(Rectangle().stroke(Theme.outline, lineWidth: 3))
                Spacer()
            }
        }
    }

    private var goLive: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !model.names.isEmpty, model.names.count < model.winnerCount {
                Text("Need at least \(model.winnerCount) entrants for \(model.winnerCount) winners.")
                    .font(Theme.mono(26))
                    .foregroundStyle(Theme.red)
            }
            HStack {
                PixelButton(
                    title: "GO LIVE",
                    fill: Theme.red,
                    foreground: .white,
                    fontSize: 18,
                    action: model.goLive
                )
                .disabled(!canGoLive)
                .opacity(canGoLive ? 1 : 0.45)
                Spacer()
                Text("F full screen")
                    .font(Theme.mono(24))
                    .foregroundStyle(Theme.muted)
            }
            Text("Go Live hides the name editor. Space draws. R redraws a no-show. N or Esc comes back here.")
                .font(Theme.mono(24))
                .foregroundStyle(Theme.muted)
        }
        .padding(.top, 6)
    }

    private var canGoLive: Bool {
        model.names.count >= model.winnerCount && model.winnerCount >= 1
    }
}

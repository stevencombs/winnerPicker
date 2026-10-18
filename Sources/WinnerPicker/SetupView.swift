import SwiftUI

private struct SetupHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private enum SetupField: Hashable {
    case names
    case sharedPrize
    case prize(Int)
}

struct SetupView: View {
    @Bindable var model: DrawModel
    @FocusState private var focusedField: SetupField?
    @State private var contentHeight: CGFloat = 820

    private let columnWidth: CGFloat = 1180

    var body: some View {
        GeometryReader { geo in
            let scale = min(
                geo.size.width / columnWidth,
                geo.size.height / max(contentHeight, 1)
            )
            ZStack {
                StripeBackground()
                column
                    .frame(width: columnWidth)
                    .overlay {
                        GeometryReader { proxy in
                            Color.clear.preference(key: SetupHeightKey.self, value: proxy.size.height)
                        }
                        .allowsHitTesting(false)
                    }
                    .scaleEffect(scale, anchor: .center)
                    .frame(width: columnWidth * scale, height: contentHeight * scale)
            }
        }
        .onPreferenceChange(SetupHeightKey.self) { height in
            guard height > 1, abs(height - contentHeight) > 0.5 else { return }
            contentHeight = height
        }
        .onAppear { focusedField = .names }
        .onDisappear { WindowControls.resignKeyFocus() }
        .onReceive(NotificationCenter.default.publisher(for: WindowControls.endTextEditingNotification)) { _ in
            focusedField = nil
        }
    }

    private func releaseTyping() {
        focusedField = nil
        WindowControls.endTextEditing()
    }

    private var column: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            RainbowPanel(padding: 22) {
                VStack(alignment: .leading, spacing: 14) {
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
            .padding(.top, 16)
            .padding(.trailing, 18)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            BundledImage(name: "retroCombslogo")
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.outline, lineWidth: 4))
                .hardShadow(Theme.red, x: 4, y: 4, radius: 10)
            VStack(alignment: .leading, spacing: 6) {
                Text("WINNERPICKER")
                    .font(Theme.press(22))
                    .foregroundStyle(Theme.beige)
                Text("Operator setup  •  this screen stays off air")
                    .font(Theme.mono(28))
                    .foregroundStyle(Theme.cream)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { releaseTyping() }
    }

    private var namesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ENTRANTS")
                .font(Theme.press(12))
                .foregroundStyle(Theme.ink)
            ZStack(alignment: .topLeading) {
                if model.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("PixelPete64, SIDChipSally, ByteBandit")
                        .font(Theme.mono(30))
                        .foregroundStyle(Theme.muted)
                        .padding(14)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $model.rawInput)
                    .font(Theme.mono(30))
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .names)
                    .padding(8)
            }
            .frame(height: 148)
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
                prizeField(text: $model.sharedPrize, prompt: "Mystery Retro Box", field: .sharedPrize)
            } else {
                ForEach(0..<model.winnerCount, id: \.self) { index in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(Theme.press(12))
                            .foregroundStyle(Theme.red)
                            .frame(width: 28)
                        prizeField(
                            text: $model.individualPrizes[index],
                            prompt: "Prize \(index + 1)",
                            field: .prize(index)
                        )
                    }
                }
            }
        }
    }

    private func prizeField(text: Binding<String>, prompt: String, field: SetupField) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(prompt)
                    .font(Theme.mono(30))
                    .foregroundStyle(Theme.muted)
                    .allowsHitTesting(false)
            }
            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(Theme.mono(30))
                .foregroundStyle(Theme.ink)
                .focused($focusedField, equals: field)
        }
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
                    action: {
                        releaseTyping()
                        model.goLive()
                    }
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

import SwiftUI

struct EntryView: View {
    @Bindable var model: DrawModel
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            editor
            preview
            winnerButton
        }
        .padding(.horizontal, 40)
        .padding(.top, 36)
        .padding(.bottom, 32)
        .onAppear { editorFocused = true }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.gold, Theme.goldDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Theme.gold.opacity(0.35), radius: 16, y: 4)

            Text("retroCombs winnerPicker")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.cream)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text("Type or paste names separated by commas, then pick a winner.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.muted)
        }
        .padding(.bottom, 28)
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.elevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )

            if model.rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Ada Lovelace, Grace Hopper, Alan Turing, Katherine Johnson")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.muted.opacity(0.55))
                    .padding(20)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $model.rawInput)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.cream)
                .lineSpacing(6)
                .scrollContentBackground(.hidden)
                .focused($editorFocused)
                .padding(14)
        }
        .frame(minHeight: 240)
    }

    @ViewBuilder
    private var preview: some View {
        let names = model.names

        HStack {
            Text(names.isEmpty ? "No names yet" : "\(names.count) \(names.count == 1 ? "name" : "names") ready")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(names.isEmpty ? Theme.muted : Theme.gold)

            Spacer()
        }
        .padding(.top, 14)
        .padding(.bottom, names.isEmpty ? 28 : 10)

        if !names.isEmpty {
            FlowLayout(spacing: 8) {
                ForEach(Array(names.prefix(16).enumerated()), id: \.offset) { _, name in
                    Text(name)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.cream)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.elevated)
                        .overlay(
                            Capsule().stroke(Theme.stroke, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }

                if names.count > 16 {
                    Text("+\(names.count - 16) more")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 28)
        }
    }

    private var winnerButton: some View {
        Button(action: model.pickWinner) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text("Winner")
            }
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(Color(red: 0.12, green: 0.09, blue: 0.04))
            .frame(maxWidth: 360)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Theme.gold, Theme.goldDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.gold.opacity(0.35), radius: 20, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Winner")
        .keyboardShortcut(.defaultAction)
        .disabled(model.names.isEmpty)
        .opacity(model.names.isEmpty ? 0.45 : 1)
    }
}

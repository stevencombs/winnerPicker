import SwiftUI

struct ContentView: View {
    @Bindable var model: DrawModel

    var body: some View {
        ZStack {
            Theme.grey.ignoresSafeArea()
            switch model.screen {
            case .setup:
                SetupView(model: model)
                    .transition(.opacity)
            case .drawing:
                Stage16x9 {
                    DrawStreamView(model: model)
                }
                .transition(.opacity)
            case .winner:
                Stage16x9 {
                    WinnerStreamView(model: model)
                        .id(model.revealID)
                }
                .transition(.opacity)
            case .recap:
                Stage16x9 {
                    RecapStreamView(model: model)
                }
                .transition(.opacity)
            }
        }
        .frame(minWidth: 1100, minHeight: 680)
        .animation(.easeInOut(duration: 0.28), value: model.screen)
        .onAppear {
            KeyBridge.shared.handle = { @MainActor stroke in
                model.consumeKey(stroke)
            }
        }
        .alert("Add some names first", isPresented: $model.showEmptyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Paste entrant names separated by commas or new lines, then go live.")
        }
        .alert("Not enough entrants", isPresented: $model.showCountAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This giveaway needs \(model.winnerCount) winners, and the list has \(model.names.count).")
        }
        .alert("No one left to draw", isPresented: $model.showPoolAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Everyone else has already won or been skipped. Start a new list to add more names.")
        }
    }
}

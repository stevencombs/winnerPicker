import SwiftUI

struct ContentView: View {
    @State private var model = DrawModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch model.screen {
            case .entry:
                EntryView(model: model)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .fanfare:
                FanfareView(model: model)
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
            }
        }
        .animation(.easeInOut(duration: 0.45), value: model.screen)
        .frame(minWidth: 760, minHeight: 560)
        .alert("Add some names first", isPresented: $model.showEmptyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Paste a list of names separated by commas, then click Winner.")
        }
    }
}

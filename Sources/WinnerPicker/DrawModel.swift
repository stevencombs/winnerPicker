import Foundation

enum AppScreen: Equatable {
    case entry
    case fanfare
}

@MainActor
@Observable
final class DrawModel {
    var rawInput = ""
    var screen: AppScreen = .entry
    var shuffledNames: [String] = []
    var winner = ""
    var drawGeneration = 0
    var showEmptyAlert = false

    var names: [String] {
        Self.parseNames(rawInput)
    }

    static func parseNames(_ text: String) -> [String] {
        text
            .split { $0 == "," || $0.isNewline }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func pickWinner() {
        let entries = names
        guard !entries.isEmpty else {
            showEmptyAlert = true
            return
        }

        shuffledNames = entries.shuffled()
        winner = shuffledNames[0]
        drawGeneration += 1
        screen = .fanfare
    }

    func pickAgain() {
        pickWinner()
    }

    func startNewDrawing() {
        screen = .entry
        winner = ""
        shuffledNames = []
    }
}

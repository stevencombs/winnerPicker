import AppKit
import Foundation

enum AppScreen: Equatable {
    case setup
    case drawing
    case winner
    case recap
}

@MainActor
@Observable
final class DrawModel {
    var rawInput = ""
    var winnerCount = 1
    var samePrizeForAll = true
    var sharedPrize = ""
    var individualPrizes = Array(repeating: "", count: 10)
    var claimMinutes = 2
    var claimSeconds = 0

    var screen: AppScreen = .setup
    var showEmptyAlert = false
    var showCountAlert = false
    var showPoolAlert = false

    private(set) var entrants: [String] = []
    private(set) var prizes: [String] = []
    private(set) var claimDuration: TimeInterval = 120
    private(set) var slot = 0
    private(set) var winners: [String?] = []
    private(set) var removed: Set<String> = []
    private(set) var pendingWinner = ""
    private(set) var shuffleOrder: [String] = []
    private(set) var isShuffling = false
    var shuffleArmed = false
    private(set) var revealID = 0

    var names: [String] {
        Self.parseNames(rawInput)
    }

    var pool: [String] {
        availablePool()
    }

    var claimClock: String {
        Theme.clock(TimeInterval(claimMinutes * 60 + claimSeconds))
    }

    static func parseNames(_ text: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for part in text.split(whereSeparator: { $0 == "," || $0.isNewline }) {
            let name = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let key = name.lowercased()
            guard seen.insert(key).inserted else { continue }
            result.append(name)
        }
        return result
    }

    func prizeText(for index: Int) -> String {
        let raw = samePrizeForAll
            ? sharedPrize
            : (individualPrizes.indices.contains(index) ? individualPrizes[index] : "")
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return samePrizeForAll ? "Prize" : "Prize \(index + 1)"
    }

    func goLive() {
        WindowControls.endTextEditing()
        let parsed = names
        guard !parsed.isEmpty else {
            showEmptyAlert = true
            return
        }
        guard parsed.count >= winnerCount else {
            showCountAlert = true
            return
        }

        entrants = parsed
        prizes = (0..<winnerCount).map { prizeText(for: $0) }
        claimDuration = TimeInterval(max(0, claimMinutes) * 60 + min(59, max(0, claimSeconds)))
        slot = 0
        winners = Array(repeating: nil, count: winnerCount)
        removed = []
        pendingWinner = ""
        shuffleOrder = []
        isShuffling = false
        shuffleArmed = false
        screen = .drawing
    }

    func space() {
        switch screen {
        case .drawing:
            guard !isShuffling else { return }
            beginShuffle(pool: availablePool())
        case .winner:
            advance()
        case .setup, .recap:
            break
        }
    }

    func redraw() {
        switch screen {
        case .winner:
            drawAgain()
        case .drawing where isShuffling:
            var nextPool = availablePool()
            if nextPool.count > 1 {
                nextPool.removeAll { $0.caseInsensitiveCompare(pendingWinner) == .orderedSame }
            }
            beginShuffle(pool: nextPool)
        default:
            break
        }
    }

    func advance() {
        guard screen == .winner else { return }
        if slot + 1 >= prizes.count {
            isShuffling = false
            screen = .recap
        } else {
            slot += 1
            pendingWinner = ""
            shuffleOrder = []
            isShuffling = false
            shuffleArmed = false
            screen = .drawing
        }
    }

    func newList() {
        guard screen != .setup else { return }
        isShuffling = false
        shuffleArmed = false
        FanfareAudio.shared.stop()
        screen = .setup
    }

    func finishReveal() {
        let name = pendingWinner
        guard !name.isEmpty else { return }
        isShuffling = false
        shuffleArmed = false
        removed.insert(name.lowercased())
        if winners.count != prizes.count {
            winners = Array(repeating: nil, count: prizes.count)
        }
        if winners.indices.contains(slot) {
            winners[slot] = name
        }
        revealID += 1
        screen = .winner
    }

    /// `true` means the key was handled and the event monitor should swallow it.
    func consumeKey(_ stroke: KeyStroke) -> Bool {
        // Typing in setup (or any field editor) must receive the key unchanged.
        if WindowControls.textInputIsFirstResponder() {
            return false
        }

        let mods = NSEvent.ModifierFlags(rawValue: stroke.modifierFlags)
            .intersection(.deviceIndependentFlagsMask)
        if mods.contains(.command) || mods.contains(.control) || mods.contains(.option) {
            return false
        }

        let chars = stroke.characters.lowercased()
        let keyCode = stroke.keyCode
        let isSpace = chars == " " || keyCode == 49
        let isEscape = keyCode == 53

        // Setup: F toggles full screen only when nothing is being edited.
        // Space, R, N, and Esc are live-screen controls.
        if screen == .setup {
            if chars == "f", !stroke.isRepeat {
                WindowControls.toggleFullScreen()
                return true
            }
            return false
        }

        let handled = isSpace || chars == "r" || chars == "n" || chars == "f" || isEscape
        if stroke.isRepeat {
            return handled
        }

        if isSpace {
            space()
            return true
        }
        switch chars {
        case "r":
            redraw()
            return true
        case "n":
            newList()
            return true
        case "f":
            WindowControls.toggleFullScreen()
            return true
        default:
            break
        }
        if isEscape {
            newList()
            return true
        }
        return false
    }

    private func drawAgain() {
        let current = winners.indices.contains(slot) ? winners[slot] : nil
        var blocked = removed
        if let current {
            blocked.insert(current.lowercased())
        }
        let nextPool = entrants.filter { !blocked.contains($0.lowercased()) }
        guard !nextPool.isEmpty else {
            showPoolAlert = true
            return
        }
        if let current {
            removed.insert(current.lowercased())
        }
        if winners.indices.contains(slot) {
            winners[slot] = nil
        }
        beginShuffle(pool: nextPool)
    }

    private func availablePool() -> [String] {
        entrants.filter { !removed.contains($0.lowercased()) }
    }

    private func beginShuffle(pool: [String]) {
        guard !pool.isEmpty else {
            showPoolAlert = true
            return
        }
        let order = pool.shuffled()
        pendingWinner = order[0]
        shuffleOrder = order
        isShuffling = true
        shuffleArmed = true
        screen = .drawing
    }
}

import AVFoundation
import Foundation

@MainActor
final class FanfareAudio {
    static let shared = FanfareAudio()

    private var player: AVAudioPlayer?

    func playDrumroll() {
        play(resource: "drumroll")
    }

    func playFanfare() {
        play(resource: "fanfare")
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func play(resource: String) {
        stop()
        guard let url = Self.url(for: resource) else { return }
        do {
            let next = try AVAudioPlayer(contentsOf: url)
            next.volume = 1.0
            next.prepareToPlay()
            next.play()
            player = next
        } catch {
            player = nil
        }
    }

    private static func url(for name: String) -> URL? {
        let candidates: [URL?] = [
            Bundle.main.url(forResource: name, withExtension: "wav"),
            Bundle.main.resourceURL?.appendingPathComponent("\(name).wav"),
            Bundle.main.bundleURL.appendingPathComponent("\(name).wav"),
            Bundle.main.bundleURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/\(name).wav")
        ]

        return candidates.compactMap { $0 }.first {
            FileManager.default.fileExists(atPath: $0.path)
        }
    }
}

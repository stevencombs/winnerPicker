import AVFoundation
import Foundation

@MainActor
final class FanfareAudio {
    static let shared = FanfareAudio()

    private var player: AVAudioPlayer?
    private var clip: Clip?

    private enum Clip {
        case drumroll
        case fanfare
    }

    func playDrumroll() {
        play(resource: "drumroll", clip: .drumroll)
    }

    func playFanfare() {
        play(resource: "fanfare", clip: .fanfare)
    }

    /// Stops one clip without cutting the other if a screen change overlaps them.
    func stopDrumroll() {
        guard clip == .drumroll else { return }
        stop()
    }

    func stopFanfare() {
        guard clip == .fanfare else { return }
        stop()
    }

    func stop() {
        player?.stop()
        player = nil
        clip = nil
    }

    private func play(resource: String, clip: Clip) {
        stop()
        guard let url = BrandAssets.url(named: resource, ext: "wav") else { return }
        do {
            let next = try AVAudioPlayer(contentsOf: url)
            next.volume = 1
            next.prepareToPlay()
            next.play()
            player = next
            self.clip = clip
        } catch {
            player = nil
            self.clip = nil
        }
    }
}

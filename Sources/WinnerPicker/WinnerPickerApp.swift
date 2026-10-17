@preconcurrency import AppKit
import SwiftUI

@main
struct WinnerPickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = DrawModel()

    init() {
        BrandAssets.registerFonts()
    }

    var body: some Scene {
        WindowGroup("retroCombs winnerPicker") {
            ContentView(model: model)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1440, height: 810)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Giveaway") {
                Button("Draw or Next") { model.space() }
                    .disabled(model.screen == .setup || model.screen == .recap)
                Button("Draw Again") { model.redraw() }
                    .disabled(model.screen != .winner && !(model.screen == .drawing && model.isShuffling))
                Button("New List") { model.newList() }
                    .disabled(model.screen == .setup)
                Divider()
                Button("Full Screen") { WindowControls.toggleFullScreen() }
                Button("Back to Setup") { model.newList() }
                    .disabled(model.screen == .setup)
            }
        }
    }
}

/// Sendable snapshot of a key down. `NSEvent` is not `Sendable`, and
/// `MainActor.assumeIsolated` can only return a `Sendable` value.
struct KeyStroke: Sendable {
    var characters: String
    var keyCode: UInt16
    var modifierFlags: UInt
    var isRepeat: Bool
}

@MainActor
final class KeyBridge {
    static let shared = KeyBridge()
    /// `true` swallows the event.
    var handle: (@MainActor (KeyStroke) -> Bool)?
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let stroke = KeyStroke(
                characters: event.charactersIgnoringModifiers ?? "",
                keyCode: event.keyCode,
                modifierFlags: event.modifierFlags.rawValue,
                isRepeat: event.isARepeat
            )
            let swallow = MainActor.assumeIsolated { () -> Bool in
                KeyBridge.shared.handle?(stroke) ?? false
            }
            return swallow ? nil : event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

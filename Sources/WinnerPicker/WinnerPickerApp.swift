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
                // A field editor is typing. Do not treat the key as a hotkey.
                // Esc ends editing here and is still delivered, so it does not
                // return to setup.
                if WindowControls.textInputIsFirstResponder() {
                    if stroke.keyCode == 53 {
                        WindowControls.endTextEditing()
                    }
                    return false
                }
                return KeyBridge.shared.handle?(stroke) ?? false
            }
            return swallow ? nil : event
        }
        // mouseUp so a click can finish (Go Live, winner count) before focus drops.
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { event in
            let windowNumber = event.windowNumber
            let x = event.locationInWindow.x
            let y = event.locationInWindow.y
            let shouldEndEditing = MainActor.assumeIsolated { () -> Bool in
                guard WindowControls.textInputIsFirstResponder() else { return false }
                return !WindowControls.hitIsTextInput(windowNumber: windowNumber, x: x, y: y)
            }
            if shouldEndEditing {
                Task { @MainActor in
                    WindowControls.endTextEditing(windowNumber: windowNumber)
                }
            }
            return event
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

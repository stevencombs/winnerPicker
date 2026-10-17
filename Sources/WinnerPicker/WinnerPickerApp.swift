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

@MainActor
final class KeyBridge {
    static let shared = KeyBridge()
    var handle: (@MainActor (NSEvent) -> NSEvent?)?
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            MainActor.assumeIsolated {
                KeyBridge.shared.handle?(event) ?? event
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

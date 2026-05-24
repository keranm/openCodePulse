import SwiftUI

@main
struct OpenCodePulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(settings: appDelegate.settings)
        }
    }
}

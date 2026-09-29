import SwiftUI

@main
struct CursorVibeApp: App {
    @StateObject private var engine = CursorEngine.shared
    @StateObject private var store = StoreManager.shared

    var body: some Scene {
        MenuBarExtra("CursorVibe", systemImage: "cursorarrow.motionlines") {
            MenuBarView()
                .environmentObject(engine)
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)

        Window("CursorVibe Settings", id: "settings") {
            SettingsView()
                .environmentObject(engine)
                .environmentObject(store)
                .frame(minWidth: 520, minHeight: 380)
        }
        .defaultSize(width: 520, height: 380)

        Window("Cursor Store", id: "store") {
            StoreView()
                .environmentObject(engine)
                .environmentObject(store)
                .frame(minWidth: 800, minHeight: 550)
        }
        .defaultSize(width: 900, height: 600)
    }
}

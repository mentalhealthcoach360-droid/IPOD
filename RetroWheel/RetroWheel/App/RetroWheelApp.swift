import SwiftUI
import MusicKit

@main
struct RetroWheelApp: App {
    @StateObject private var playerVM = MusicPlayerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerVM)
                .preferredColorScheme(.dark)
        }
    }
}

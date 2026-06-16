import SwiftUI
import MusicKit

@main
struct RetroWheelApp: App {
    @StateObject private var playerVM       = MusicPlayerViewModel()
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerVM)
                .environmentObject(purchaseManager)
                .preferredColorScheme(.dark)
        }
    }
}

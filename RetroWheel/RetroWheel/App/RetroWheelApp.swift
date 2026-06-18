import SwiftUI

@main
struct RetroWheelApp: App {
    @StateObject private var playerVM        = MusicPlayerViewModel()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var appSettings     = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerVM)
                .environmentObject(purchaseManager)
                .environmentObject(appSettings)
                .preferredColorScheme(.dark)
        }
    }
}

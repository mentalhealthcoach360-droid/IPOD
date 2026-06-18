import SwiftUI

/// Root view — the entire screen is the RetroWheel experience.
/// Environment objects (playerVM, purchaseManager, appSettings) are injected
/// at the app level and propagate automatically to all child views.
struct ContentView: View {
    var body: some View {
        RetroShellView()
    }
}

#Preview {
    ContentView()
        .environmentObject(MusicPlayerViewModel())
        .environmentObject(PurchaseManager())
        .environmentObject(AppSettings())
}

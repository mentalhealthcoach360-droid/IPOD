import SwiftUI

/// Root view — the entire screen is the RetroWheel experience.
struct ContentView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var appSettings: AppSettings

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

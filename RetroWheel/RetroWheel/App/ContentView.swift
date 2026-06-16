import SwiftUI

/// Root view: places the RetroWheel shell centred on a dark background.
struct ContentView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            RetroShellView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MusicPlayerViewModel())
        .environmentObject(PurchaseManager())
}


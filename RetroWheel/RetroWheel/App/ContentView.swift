import SwiftUI

/// Root view: places the RetroWheel shell centred on a dark background.
struct ContentView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel

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
}


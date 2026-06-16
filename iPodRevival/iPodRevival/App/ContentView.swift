import SwiftUI

/// Root view: places the iPod shell centred on a dark linen background.
struct ContentView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            iPodShellView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MusicPlayerViewModel())
}

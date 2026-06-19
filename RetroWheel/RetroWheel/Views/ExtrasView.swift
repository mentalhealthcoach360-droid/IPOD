import SwiftUI

/// Extras screen — games and bonus features.
struct ExtrasView: View {
    @State private var showBrickBounce = false
    @State private var showTrail       = false

    private let games: [GameEntry] = [
        GameEntry(
            id: "brick_bounce",
            name: "Brick Bounce",
            description: "Classic ball-and-paddle. Clear all the bricks!",
            icon: "squareshape.split.3x3",
            color: Color(red: 0.2, green: 0.55, blue: 0.95)
        ),
        GameEntry(
            id: "trail",
            name: "Trail",
            description: "Guide the trail. Don't cross your own path!",
            icon: "arrow.turn.up.right",
            color: Color(red: 0.2, green: 0.75, blue: 0.45)
        )
    ]

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                sectionHeader

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(games) { game in
                            gameCard(game)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
        }
        .navigationTitle("Extras")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showBrickBounce) {
            BrickBounceView()
        }
        .fullScreenCover(isPresented: $showTrail) {
            TrailView()
        }
    }

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "gamecontroller.fill")
                .foregroundStyle(Color.white.opacity(0.5))
            Text("Mini Games")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
    }

    private func gameCard(_ game: GameEntry) -> some View {
        Button {
            if game.id == "brick_bounce" { showBrickBounce = true }
            if game.id == "trail"        { showTrail = true }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(game.color.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: game.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(game.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text(game.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(14)
            .background(Color.white.opacity(0.07))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

private struct GameEntry: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
}

#Preview {
    NavigationStack {
        ExtrasView()
    }
}

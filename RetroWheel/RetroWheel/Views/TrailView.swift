import SwiftUI
import Combine

// MARK: - Game model

private struct TrailGame {
    static let gridSize = 18   // 18×18 cells

    enum Direction { case up, down, left, right
        var opposite: Direction {
            switch self {
            case .up: return .down;  case .down: return .up
            case .left: return .right; case .right: return .left
            }
        }
    }

    struct Point: Equatable {
        var x: Int
        var y: Int
    }

    enum Phase { case waiting, playing, paused, over }

    var segments:  [Point] = [Point(x: 9, y: 9)]
    var direction: Direction = .right
    var nextDir:   Direction = .right
    var food:      Point = Point(x: 14, y: 9)
    var score:     Int = 0
    var phase:     Phase = .waiting
    var highScore: Int = UserDefaults.standard.integer(forKey: "trail_high_score")

    mutating func changeDirection(_ d: Direction) {
        guard d != direction.opposite else { return }
        nextDir = d
    }

    mutating func tick() {
        guard phase == .playing else { return }
        direction = nextDir

        let head = segments[0]
        let next: Point
        switch direction {
        case .up:    next = Point(x: head.x, y: head.y - 1)
        case .down:  next = Point(x: head.x, y: head.y + 1)
        case .left:  next = Point(x: head.x - 1, y: head.y)
        case .right: next = Point(x: head.x + 1, y: head.y)
        }

        let g = TrailGame.gridSize

        // Wall collision
        if next.x < 0 || next.x >= g || next.y < 0 || next.y >= g {
            endGame(); return
        }
        // Self collision (skip tail since it moves)
        if segments.dropLast().contains(next) {
            endGame(); return
        }

        segments.insert(next, at: 0)

        if next == food {
            score += 1
            placeFood()
        } else {
            segments.removeLast()
        }
    }

    mutating func placeFood() {
        let g = TrailGame.gridSize
        var candidate: Point
        repeat {
            candidate = Point(x: Int.random(in: 0..<g), y: Int.random(in: 0..<g))
        } while segments.contains(candidate)
        food = candidate
    }

    mutating func endGame() {
        phase = .over
        if score > highScore {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "trail_high_score")
        }
    }

    mutating func reset() {
        let saved = highScore
        self = TrailGame()
        highScore = saved
    }
}

// MARK: - View

struct TrailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var game = TrailGame()
    @State private var tickInterval: Double = 0.16   // seconds per move

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                hud
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                GeometryReader { geo in
                    grid(size: min(geo.size.width, geo.size.height))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                directionPad
                    .padding(.vertical, 14)

                HStack(spacing: 20) {
                    if game.phase == .playing {
                        actionButton("Pause", icon: "pause.fill") {
                            game.phase = .paused
                        }
                    } else if game.phase == .paused {
                        actionButton("Resume", icon: "play.fill") {
                            game.phase = .playing
                        }
                    }
                    actionButton("Restart", icon: "arrow.counterclockwise") { game.reset() }
                    actionButton("Close",   icon: "xmark.circle")           { dismiss() }
                }
                .padding(.bottom, 16)
            }
        }
        .onReceive(
            Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
            // Speed up as score increases
            tickInterval = max(0.08, 0.16 - Double(game.score) * 0.004)
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    if abs(dx) > abs(dy) {
                        game.changeDirection(dx > 0 ? .right : .left)
                    } else {
                        game.changeDirection(dy > 0 ? .down : .up)
                    }
                    if game.phase == .waiting || game.phase == .over {
                        if game.phase == .over { game.reset() }
                        game.phase = .playing
                    }
                }
        )
    }

    // MARK: - Grid

    private func grid(size: CGFloat) -> some View {
        let cell = size / CGFloat(TrailGame.gridSize)

        return Canvas { ctx, _ in
            let g = TrailGame.gridSize

            // Background cells
            for x in 0..<g {
                for y in 0..<g {
                    let r = CGRect(x: CGFloat(x) * cell + 1,
                                   y: CGFloat(y) * cell + 1,
                                   width: cell - 2,
                                   height: cell - 2)
                    ctx.fill(Path(roundedRect: r, cornerRadius: 2),
                             with: .color(Color(white: 0.10)))
                }
            }

            // Snake body
            for (idx, seg) in game.segments.enumerated() {
                let brightness = max(0.35, 1.0 - Double(idx) / Double(game.segments.count + 1))
                let r = CGRect(x: CGFloat(seg.x) * cell + 1,
                               y: CGFloat(seg.y) * cell + 1,
                               width: cell - 2,
                               height: cell - 2)
                let segColor = Color(red: 0.2, green: brightness * 0.85, blue: 0.4)
                ctx.fill(Path(roundedRect: r, cornerRadius: 3), with: .color(segColor))
            }

            // Head highlight
            if let head = game.segments.first {
                let r = CGRect(x: CGFloat(head.x) * cell + 1,
                               y: CGFloat(head.y) * cell + 1,
                               width: cell - 2,
                               height: cell - 2)
                ctx.fill(Path(roundedRect: r, cornerRadius: 3),
                         with: .color(Color(red: 0.4, green: 1.0, blue: 0.5)))
            }

            // Food
            let fr = CGRect(x: CGFloat(game.food.x) * cell + 2,
                            y: CGFloat(game.food.y) * cell + 2,
                            width: cell - 4,
                            height: cell - 4)
            ctx.fill(Path(ellipseIn: fr), with: .color(Color(red: 1.0, green: 0.3, blue: 0.3)))
        }
        .frame(width: size, height: size)
        .background(Color(white: 0.07))
        .cornerRadius(12)
        .overlay(overlayContent)
        .onTapGesture {
            switch game.phase {
            case .waiting:           game.phase = .playing
            case .over:              game.reset(); game.phase = .playing
            case .paused:            game.phase = .playing
            default: break
            }
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch game.phase {
        case .waiting:
            overlay("Trail", subtitle: "Swipe or tap arrows to start")
        case .over:
            overlay("Game Over", subtitle: "Score: \(game.score)  •  Best: \(game.highScore)")
        case .paused:
            overlay("Paused", subtitle: "Tap to resume")
        default:
            EmptyView()
        }
    }

    private func overlay(_ title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.55))
        .cornerRadius(12)
    }

    // MARK: - HUD

    private var hud: some View {
        HStack {
            Label("\(game.score)", systemImage: "square.fill")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.4, green: 1.0, blue: 0.5))
            Spacer()
            Label("Best: \(game.highScore)", systemImage: "trophy.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.yellow)
        }
    }

    // MARK: - Direction pad

    private var directionPad: some View {
        VStack(spacing: 6) {
            dirButton(direction: .up,    icon: "chevron.up")
            HStack(spacing: 16) {
                dirButton(direction: .left,  icon: "chevron.left")
                Color.clear.frame(width: 48, height: 48)
                dirButton(direction: .right, icon: "chevron.right")
            }
            dirButton(direction: .down,  icon: "chevron.down")
        }
    }

    private func dirButton(direction: TrailGame.Direction, icon: String) -> some View {
        Button {
            game.changeDirection(direction)
            if game.phase == .waiting || game.phase == .over {
                if game.phase == .over { game.reset() }
                game.phase = .playing
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.10))
                .cornerRadius(12)
        }
    }

    private func actionButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.12))
                .cornerRadius(18)
        }
    }
}

#Preview { TrailView() }

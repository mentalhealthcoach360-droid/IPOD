import SwiftUI
import Combine

// MARK: - Game model

private struct BrickBounceGame {
    // Canvas is defined at layout time; we work in normalised coords (0–1)
    // and scale at render time so the game is device-independent.

    struct Brick: Identifiable {
        let id: Int
        var alive: Bool
        let row: Int
        let col: Int
        let color: Color
        let points: Int
    }

    static let cols     = 7
    static let rows     = 5
    static let ballR    = 0.020       // radius as fraction of canvas width
    static let paddleW  = 0.22
    static let paddleH  = 0.022
    static let paddleY  = 0.88        // paddle top edge Y

    var ballX: Double = 0.50
    var ballY: Double = 0.70
    var velX:  Double = 0.0030
    var velY:  Double = -0.0040

    var paddleX: Double = 0.50 - paddleW / 2   // left edge

    var bricks: [Brick] = Self.makeBricks()
    var score:  Int  = 0
    var lives:  Int  = 3
    var phase:  Phase = .waiting

    enum Phase { case waiting, playing, lost, won }

    // Brick layout helpers
    static func makeBricks() -> [Brick] {
        let colors: [Color] = [
            Color(red: 0.95, green: 0.30, blue: 0.30),
            Color(red: 0.95, green: 0.60, blue: 0.20),
            Color(red: 0.95, green: 0.90, blue: 0.20),
            Color(red: 0.35, green: 0.80, blue: 0.35),
            Color(red: 0.30, green: 0.60, blue: 0.95)
        ]
        var out: [Brick] = []
        var id = 0
        for r in 0..<rows {
            for c in 0..<cols {
                out.append(Brick(id: id,
                                 alive: true,
                                 row: r, col: c,
                                 color: colors[r % colors.count],
                                 points: (rows - r) * 10))
                id += 1
            }
        }
        return out
    }

    mutating func tick() {
        guard phase == .playing else { return }

        ballX += velX
        ballY += velY

        // Wall collisions
        if ballX - Self.ballR < 0 { ballX = Self.ballR; velX = abs(velX) }
        if ballX + Self.ballR > 1 { ballX = 1 - Self.ballR; velX = -abs(velX) }
        if ballY - Self.ballR < 0 { ballY = Self.ballR; velY = abs(velY) }

        // Paddle collision
        let padLeft  = paddleX
        let padRight = paddleX + Self.paddleW
        let padTop   = Self.paddleY

        if ballY + Self.ballR >= padTop &&
           ballY + Self.ballR <= padTop + Self.paddleH + Self.ballR &&
           ballX >= padLeft - Self.ballR &&
           ballX <= padRight + Self.ballR &&
           velY > 0
        {
            velY = -abs(velY)
            // Add slight angle based on where on paddle ball hits
            let hitPos = (ballX - (paddleX + Self.paddleW / 2)) / (Self.paddleW / 2)
            velX = hitPos * 0.006
        }

        // Ball falls below paddle
        if ballY - ballR > 1.0 {
            lives -= 1
            if lives <= 0 {
                phase = .lost
            } else {
                resetBall()
            }
        }

        // Brick collisions
        let brickW = 1.0 / Double(BrickBounceGame.cols)
        let brickH = 0.10
        let brickTop = 0.06

        for i in bricks.indices where bricks[i].alive {
            let b = bricks[i]
            let bx = Double(b.col) * brickW
            let by = brickTop + Double(b.row) * brickH

            if ballX + ballR > bx && ballX - ballR < bx + brickW &&
               ballY + ballR > by && ballY - ballR < by + brickH
            {
                bricks[i].alive = false
                score += b.points

                // Reflect based on which face was hit
                let overlapL = (ballX + ballR) - bx
                let overlapR = (bx + brickW) - (ballX - ballR)
                let overlapT = (ballY + ballR) - by
                let overlapB = (by + brickH) - (ballY - ballR)
                let minH = min(overlapL, overlapR)
                let minV = min(overlapT, overlapB)
                if minH < minV { velX = -velX } else { velY = -velY }
                break
            }
        }

        if bricks.allSatisfy({ !$0.alive }) { phase = .won }
    }

    mutating func resetBall() {
        ballX = paddleX + Self.paddleW / 2
        ballY = Self.paddleY - 0.08
        velX  = Double.random(in: -0.004...0.004)
        velY  = -0.0045
        phase = .waiting
    }

    mutating func reset() {
        self = BrickBounceGame()
    }
}

// MARK: - View

struct BrickBounceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var game = BrickBounceGame()
    @State private var lastTick = Date()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // HUD
                hud
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // Game canvas
                GeometryReader { geo in
                    canvas(size: geo.size)
                }
                .aspectRatio(0.65, contentMode: .fit)
                .padding(.horizontal, 16)

                // Controls hint
                Text(controlsHint)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .padding(.top, 8)

                // Restart / close
                HStack(spacing: 24) {
                    actionButton("Restart", icon: "arrow.counterclockwise") { game.reset() }
                    actionButton("Close", icon: "xmark.circle") { dismiss() }
                }
                .padding(.vertical, 16)
            }
        }
        // Game loop
        .onReceive(
            Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }

    // MARK: - Canvas

    private func canvas(size: CGSize) -> some View {
        // All layout values are explicitly CGFloat to avoid any type-inference ambiguity
        let w: CGFloat = size.width
        let h: CGFloat = size.height
        let cols: CGFloat = CGFloat(BrickBounceGame.cols)
        let brickW: CGFloat = w / cols
        let brickH: CGFloat = h * 0.10
        let brickTop: CGFloat = h * 0.06

        return ZStack(alignment: .topLeading) {
            // Background grid lines
            Path { p in
                for c in 0...BrickBounceGame.cols {
                    let x: CGFloat = CGFloat(c) * brickW
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: h))
                }
            }
            .stroke(Color.white.opacity(0.04), lineWidth: 0.5)

            // Bricks
            ForEach(game.bricks) { brick in
                if brick.alive {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(brick.color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black.opacity(0.25), lineWidth: 1)
                        )
                        .frame(width: brickW - 3, height: brickH - 3)
                        .offset(
                            x: CGFloat(brick.col) * brickW + 1.5,
                            y: brickTop + CGFloat(brick.row) * brickH + 1.5
                        )
                }
            }

            // Paddle
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: w * CGFloat(BrickBounceGame.paddleW),
                       height: h * CGFloat(BrickBounceGame.paddleH))
                .offset(x: CGFloat(game.paddleX) * w,
                        y: h * CGFloat(BrickBounceGame.paddleY))

            // Ball
            Circle()
                .fill(Color.white)
                .shadow(color: Color.white.opacity(0.6), radius: 4)
                .frame(width: w * CGFloat(BrickBounceGame.ballR) * 2,
                       height: w * CGFloat(BrickBounceGame.ballR) * 2)
                .offset(x: CGFloat(game.ballX) * w - w * CGFloat(BrickBounceGame.ballR),
                        y: CGFloat(game.ballY) * h - w * CGFloat(BrickBounceGame.ballR))

            // Overlay messages
            if game.phase == .waiting {
                overlayMessage("Tap to launch", icon: "hand.tap")
            } else if game.phase == .lost {
                overlayMessage("Game Over", icon: "xmark.circle", subtitle: "Score: \(game.score)")
            } else if game.phase == .won {
                overlayMessage("You Win! 🎉", icon: "star.fill", subtitle: "Score: \(game.score)")
            }
        }
        .frame(width: w, height: h)
        .background(Color(white: 0.07))
        .cornerRadius(12)
        // Drag gesture to move paddle
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Explicit Double cast avoids CGFloat/Double min/max generic ambiguity
                    let pct = Double(value.location.x / w)
                    game.paddleX = max(0, min(1 - BrickBounceGame.paddleW,
                                             pct - BrickBounceGame.paddleW / 2))
                    if game.phase == .waiting { game.phase = .playing }
                }
        )
        // Tap to launch
        .onTapGesture {
            if game.phase == .waiting  { game.phase = .playing }
            if game.phase == .lost || game.phase == .won { game.reset() }
        }
    }

    // MARK: - HUD

    private var hud: some View {
        HStack {
            Label("\(game.score)", systemImage: "star.fill")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.yellow)
            Spacer()
            Label("\(game.lives)", systemImage: "heart.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.red)
        }
    }

    private var controlsHint: String {
        switch game.phase {
        case .waiting: return "Drag to move paddle · Tap to launch"
        case .playing: return "Drag paddle to bounce the ball"
        case .lost:    return "Tap the field to restart"
        case .won:     return "Tap the field to play again"
        }
    }

    private func overlayMessage(_ title: String, icon: String, subtitle: String? = nil) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Color.white)
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.55))
    }

    private func actionButton(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12))
                .cornerRadius(20)
        }
    }
}

struct BrickBounceView_Previews: PreviewProvider {
    static var previews: some View {
        BrickBounceView()
    }
}

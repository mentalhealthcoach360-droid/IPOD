import SwiftUI

/// The five colour options for the RetroWheel device shell.
enum ShellColor: String, CaseIterable, Identifiable {
    case black   = "Black"
    case white   = "White"
    case pink    = "Pink"
    case yellow  = "Yellow"
    case blue    = "Blue"

    var id: String { rawValue }

    var bodyGradient: [Color] {
        switch self {
        case .black:
            return [Color(white: 0.18), Color(white: 0.08)]
        case .white:
            return [Color(white: 0.97), Color(white: 0.88)]
        case .pink:
            return [Color(red: 0.96, green: 0.44, blue: 0.63), Color(red: 0.85, green: 0.27, blue: 0.50)]
        case .yellow:
            return [Color(red: 1.00, green: 0.86, blue: 0.00), Color(red: 0.92, green: 0.74, blue: 0.00)]
        case .blue:
            return [Color(red: 0.20, green: 0.60, blue: 0.90), Color(red: 0.10, green: 0.45, blue: 0.78)]
        }
    }

    var homeButtonColor: Color {
        switch self {
        case .black:  return Color(white: 0.12)
        case .white:  return Color(white: 0.90)
        default:      return bodyGradient[0].opacity(0.8)
        }
    }

    var isLight: Bool {
        self == .white || self == .yellow
    }
}

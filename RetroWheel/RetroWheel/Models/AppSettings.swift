import Foundation
import Combine

/// Persists user preferences for the RetroWheel experience.
/// All values are stored in UserDefaults and persist between app launches and updates.
/// Note: UserDefaults is cleared if the user deletes and reinstalls the app.
@MainActor
final class AppSettings: ObservableObject {

    // MARK: - Shell appearance
    @Published var shellColorName: String {
        didSet { UserDefaults.standard.set(shellColorName, forKey: Keys.shellColor) }
    }

    var shellColor: ShellColor {
        get { ShellColor(rawValue: shellColorName) ?? .black }
        set { shellColorName = newValue.rawValue }
    }

    // MARK: - Interaction
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @Published var clickSoundsEnabled: Bool {
        didSet { UserDefaults.standard.set(clickSoundsEnabled, forKey: Keys.clickSounds) }
    }

    /// 0.5 = slow, 1.0 = default, 2.0 = fast
    @Published var wheelSensitivity: Double {
        didSet { UserDefaults.standard.set(wheelSensitivity, forKey: Keys.sensitivity) }
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        shellColorName  = defaults.string(forKey: Keys.shellColor) ?? ShellColor.black.rawValue
        hapticsEnabled  = defaults.object(forKey: Keys.haptics)    as? Bool ?? true
        clickSoundsEnabled = defaults.object(forKey: Keys.clickSounds) as? Bool ?? true
        wheelSensitivity = defaults.object(forKey: Keys.sensitivity) as? Double ?? 1.0
    }

    // MARK: - Keys

    private enum Keys {
        static let shellColor  = "retro_shell_color"
        static let haptics     = "retro_haptics_enabled"
        static let clickSounds = "retro_click_sounds_enabled"
        static let sensitivity = "retro_wheel_sensitivity"
    }
}

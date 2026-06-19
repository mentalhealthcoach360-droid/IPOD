import Foundation
import Security

/// Minimal Keychain wrapper for storing the trial start date.
///
/// Why Keychain instead of UserDefaults?
/// UserDefaults is wiped when the user deletes and reinstalls the app.
/// The Keychain entry with `kSecAttrAccessibleAfterFirstUnlock` survives
/// app deletion and reinstalls on the same device, so the trial start
/// date is preserved. It is cleared only on a full device erase/restore,
/// which is the correct, App Store-friendly trade-off — no server or
/// login required.
enum KeychainHelper {

    private static let service = "com.marcustrise.retrowheel"

    // MARK: - Date read / write

    static func saveDate(_ date: Date, forKey key: String) {
        let interval = date.timeIntervalSince1970
        let data = withUnsafeBytes(of: interval) { Data($0) }

        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecValueData:        data,
            // Persists across reinstalls; requires device to have been
            // unlocked at least once after boot before it is accessible.
            kSecAttrAccessible:   kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete any existing entry first, then add the new one.
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("KeychainHelper: write failed for '\(key)' — OSStatus \(status)")
        }
    }

    static func loadDate(forKey key: String) -> Date? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              data.count == MemoryLayout<Double>.size
        else { return nil }

        let interval = data.withUnsafeBytes { $0.load(as: Double.self) }
        return Date(timeIntervalSince1970: interval)
    }

    static func deleteDate(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

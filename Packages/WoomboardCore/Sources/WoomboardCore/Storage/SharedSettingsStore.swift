import Foundation

/// Gerencia a persistência de configurações compartilhadas via App Group.
public final class SharedSettingsStore: @unchecked Sendable {
    public static let defaultAppGroupID = "group.com.woomboard.shared"
    private static let settingsKey = "woomboard.keyboard.settings.v1"

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(suiteName: String = SharedSettingsStore.defaultAppGroupID) {
        self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    public func loadSettings() -> KeyboardSettings {
        guard let data = userDefaults.data(forKey: Self.settingsKey),
              let settings = try? decoder.decode(KeyboardSettings.self, from: data) else {
            return KeyboardSettings()
        }
        return settings
    }

    public func saveSettings(_ settings: KeyboardSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: Self.settingsKey)
    }
}

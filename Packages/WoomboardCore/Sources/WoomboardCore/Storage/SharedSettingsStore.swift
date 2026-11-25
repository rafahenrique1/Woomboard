import Foundation

/// Gerencia a persistência de configurações compartilhadas via App Group.
/// Detecta automaticamente o App Group presente no `embedded.mobileprovision` (compatível com KravaSign/Xcode),
/// com fallback seguro para o grupo padrão ou `UserDefaults.standard`.
public final class SharedSettingsStore: @unchecked Sendable {
    public static let defaultAppGroupID = "group.com.woomboard.shared"
    private static let settingsKey = "woomboard.keyboard.settings.v1"

    public let resolvedAppGroupID: String?
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(suiteName: String? = nil) {
        let detectedGroup = suiteName ?? Self.detectProvisionedAppGroup() ?? Self.defaultAppGroupID
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: detectedGroup),
           !containerURL.path.isEmpty,
           let shared = UserDefaults(suiteName: detectedGroup) {
            self.resolvedAppGroupID = detectedGroup
            self.userDefaults = shared
        } else {
            self.resolvedAppGroupID = nil
            self.userDefaults = .standard
        }
    }

    public func loadSettings() -> KeyboardSettings {
        userDefaults.synchronize()
        guard let data = userDefaults.data(forKey: Self.settingsKey),
              let settings = try? decoder.decode(KeyboardSettings.self, from: data) else {
            return KeyboardSettings()
        }
        return settings
    }

    public func saveSettings(_ settings: KeyboardSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: Self.settingsKey)
        userDefaults.synchronize()
    }

    /// Extrai o primeiro App Group listado no `embedded.mobileprovision` do app ou da extensão.
    private static func detectProvisionedAppGroup() -> String? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let rawData = try? Data(contentsOf: url),
              let rawString = String(data: rawData, encoding: .isoLatin1),
              let plistStart = rawString.range(of: "<?xml"),
              let plistEnd = rawString.range(of: "</plist>") else {
            return nil
        }

        let xmlString = String(rawString[plistStart.lowerBound..<plistEnd.upperBound])
        guard let xmlData = xmlString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: xmlData, options: [], format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any],
              let groups = entitlements["com.apple.security.application-groups"] as? [String] else {
            return nil
        }

        // Prefere o grupo do Woomboard se existir; caso contrário usa o primeiro grupo provisionado (ex.: KravaSign)
        if let exact = groups.first(where: { $0 == defaultAppGroupID }) {
            return exact
        }
        return groups.first
    }
}

import Foundation

/// Representa um tema visual do Woomboard, serializável para compartilhamento via App Groups.
public struct KeyboardTheme: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var backgroundHex: String
    public var keyBackgroundHex: String
    public var specialKeyBackgroundHex: String
    public var accentHex: String
    public var textHex: String
    public var secondaryTextHex: String
    public var keyCornerRadius: Double
    public var showKeyShadow: Bool

    public init(
        id: String,
        name: String,
        backgroundHex: String,
        keyBackgroundHex: String,
        specialKeyBackgroundHex: String,
        accentHex: String,
        textHex: String,
        secondaryTextHex: String,
        keyCornerRadius: Double = 8.0,
        showKeyShadow: Bool = true
    ) {
        self.id = id
        self.name = name
        self.backgroundHex = backgroundHex
        self.keyBackgroundHex = keyBackgroundHex
        self.specialKeyBackgroundHex = specialKeyBackgroundHex
        self.accentHex = accentHex
        self.textHex = textHex
        self.secondaryTextHex = secondaryTextHex
        self.keyCornerRadius = keyCornerRadius
        self.showKeyShadow = showKeyShadow
    }
}

import Foundation

/// Presets de temas embutidos no Woomboard com estética nativa Apple (funcionam mesmo sem Full Access).
public enum DefaultThemes {
    /// Estilo nativo Claro do iOS (SF Pro, teclas brancas com sombra 1pt, acento System Blue).
    public static let woomLight = KeyboardTheme(
        id: "woom-light",
        name: "Apple Light",
        backgroundHex: "#D1D3D9",
        keyBackgroundHex: "#FFFFFF",
        specialKeyBackgroundHex: "#AEB3BE",
        accentHex: "#007AFF",
        textHex: "#000000",
        secondaryTextHex: "#6E737D",
        keyCornerRadius: 5.0,
        showKeyShadow: true
    )

    /// Estilo nativo Escuro do iOS (grafite suave, teclas elevadas translúcidas, acento System Blue Dark).
    public static let woomDark = KeyboardTheme(
        id: "woom-dark",
        name: "Apple Dark",
        backgroundHex: "#1C1C1E",
        keyBackgroundHex: "#4A4A4C",
        specialKeyBackgroundHex: "#2C2C2E",
        accentHex: "#0A84FF",
        textHex: "#FFFFFF",
        secondaryTextHex: "#AEAEB2",
        keyCornerRadius: 5.0,
        showKeyShadow: true
    )

    /// Preto absoluto para telas OLED com contraste elevado e acabamento minimalista.
    public static let midnightOLED = KeyboardTheme(
        id: "midnight-oled",
        name: "Midnight OLED",
        backgroundHex: "#000000",
        keyBackgroundHex: "#1C1C1E",
        specialKeyBackgroundHex: "#111113",
        accentHex: "#0A84FF",
        textHex: "#FFFFFF",
        secondaryTextHex: "#8E8E93",
        keyCornerRadius: 6.0,
        showKeyShadow: false
    )

    /// Paleta suave inspirada em acabamentos naturais da Apple.
    public static let matchaSoft = KeyboardTheme(
        id: "matcha-soft",
        name: "Matcha Soft",
        backgroundHex: "#E5ECE4",
        keyBackgroundHex: "#FAFCFA",
        specialKeyBackgroundHex: "#CCD9CA",
        accentHex: "#2F6F4E",
        textHex: "#1C2B21",
        secondaryTextHex: "#5B7062",
        keyCornerRadius: 7.0,
        showKeyShadow: true
    )

    public static let all: [KeyboardTheme] = [
        woomLight,
        woomDark,
        midnightOLED,
        matchaSoft
    ]

    public static func theme(for id: String) -> KeyboardTheme {
        all.first { $0.id == id } ?? woomLight
    }
}

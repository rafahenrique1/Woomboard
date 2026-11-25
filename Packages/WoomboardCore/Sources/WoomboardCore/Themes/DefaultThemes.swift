import Foundation

/// Presets de temas embutidos no Woomboard com estética nativa Apple iOS 26 + One UI moderno.
public enum DefaultThemes {
    /// Estilo nativo Claro do iOS 26 (fundo translúcido, teclas brancas arredondadas e acento System Blue).
    public static let woomLight = KeyboardTheme(
        id: "woom-light",
        name: "Apple Light",
        backgroundHex: "#D1D5DB",
        keyBackgroundHex: "#FFFFFF",
        specialKeyBackgroundHex: "#B8BFC9",
        accentHex: "#007AFF",
        textHex: "#000000",
        secondaryTextHex: "#7A818C",
        keyCornerRadius: 8.5,
        showKeyShadow: true
    )

    /// Estilo nativo Escuro do iOS 26 (teclas elevadas translúcidas, contraste confortável e acento System Blue Dark).
    public static let woomDark = KeyboardTheme(
        id: "woom-dark",
        name: "Apple Dark",
        backgroundHex: "#1C1C1E",
        keyBackgroundHex: "#48484A",
        specialKeyBackgroundHex: "#2C2C2E",
        accentHex: "#0A84FF",
        textHex: "#FFFFFF",
        secondaryTextHex: "#98989D",
        keyCornerRadius: 8.5,
        showKeyShadow: true
    )

    /// Preto absoluto para telas OLED com contraste elevado e acabamento minimalista.
    public static let midnightOLED = KeyboardTheme(
        id: "midnight-oled",
        name: "Midnight OLED",
        backgroundHex: "#000000",
        keyBackgroundHex: "#1C1C1E",
        specialKeyBackgroundHex: "#121214",
        accentHex: "#0A84FF",
        textHex: "#FFFFFF",
        secondaryTextHex: "#8E8E93",
        keyCornerRadius: 9.0,
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
        keyCornerRadius: 9.0,
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

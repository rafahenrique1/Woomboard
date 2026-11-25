import CoreGraphics
import Foundation
import WoomboardCore

/// Camada ativa do teclado.
enum KeyboardLayer: Equatable {
    case letters
    case numbers
    case symbols
}

/// Estado do Shift (desligado, uma letra maiúscula ou Caps Lock).
enum ShiftState: Equatable {
    case lower
    case upper
    case capsLock

    var isUppercase: Bool {
        self != .lower
    }
}

/// Especificação visual e funcional de cada tecla (com suporte a SF Symbols nativos da Apple).
struct KeySpec: Equatable {
    let title: String
    let systemImage: String?
    let secondaryTitle: String?
    let action: KeyAction
    let secondaryAction: KeyAction?
    let accentOptions: [String]
    let isSpecial: Bool
    let isAccent: Bool
    let isHighlighted: Bool
    let isNumberRow: Bool
    let widthMultiplier: CGFloat
    let accessibilityLabel: String

    init(
        title: String,
        systemImage: String? = nil,
        secondaryTitle: String? = nil,
        action: KeyAction,
        secondaryAction: KeyAction? = nil,
        accentOptions: [String] = [],
        isSpecial: Bool = false,
        isAccent: Bool = false,
        isHighlighted: Bool = false,
        isNumberRow: Bool = false,
        widthMultiplier: CGFloat = 1.0,
        accessibilityLabel: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.secondaryTitle = secondaryTitle
        self.action = action
        self.secondaryAction = secondaryAction
        self.accentOptions = accentOptions
        self.isSpecial = isSpecial
        self.isAccent = isAccent
        self.isHighlighted = isHighlighted
        self.isNumberRow = isNumberRow
        self.widthMultiplier = widthMultiplier
        self.accessibilityLabel = accessibilityLabel ?? title
    }

    /// Opções exibidas no popup de toque longo (acentos + símbolo secundário quando existir).
    var longPressOptions: [String] {
        var options = accentOptions
        if let secondary = secondaryTitle, !options.contains(secondary) {
            options.append(secondary)
        }
        return options
    }
}

/// Motor responsável por gerar as fileiras e teclas para os layouts Samsung One UI moderno e Apple iOS 26.
final class KeyboardLayoutEngine {
    /// Mapeamento de acentos para PT-BR / EN-US (toque longo).
    private static let accentMap: [String: [String]] = [
        "a": ["á", "à", "â", "ã", "ä", "ª"],
        "e": ["é", "ê", "è", "ë"],
        "i": ["í", "î", "ì", "ï"],
        "o": ["ó", "ô", "õ", "ò", "ö", "º"],
        "u": ["ú", "ü", "û", "ù"],
        "c": ["ç"],
        "n": ["ñ"],
        ".": [".", ",", "?", "!", "@", ".com"]
    ]

    /// Símbolos secundários estilo Samsung One UI moderno exibidos no canto superior direito das letras.
    private static let samsungSecondarySymbols: [String: String] = [
        "q": "+", "w": "×", "e": "÷", "r": "=", "t": "/",
        "y": "_", "u": "<", "i": ">", "o": "[", "p": "]",
        "a": "!", "s": "@", "d": "#", "f": "$", "g": "%",
        "h": "&", "j": "*", "k": "(", "l": ")",
        "z": "-", "x": "'", "c": "\"", "v": ":", "b": ";",
        "n": ",", "m": "?"
    ]

    func rows(
        layer: KeyboardLayer,
        shiftState: ShiftState,
        settings: KeyboardSettings,
        includeGlobeKey: Bool,
        returnKeySymbol: String = "return",
        returnKeyLabel: String? = nil
    ) -> [[KeySpec]] {
        switch layer {
        case .letters:
            return letterRows(
                shiftState: shiftState,
                settings: settings,
                includeGlobeKey: includeGlobeKey,
                returnKeySymbol: returnKeySymbol,
                returnKeyLabel: returnKeyLabel
            )
        case .numbers:
            return numberRows(
                settings: settings,
                includeGlobeKey: includeGlobeKey,
                returnKeySymbol: returnKeySymbol,
                returnKeyLabel: returnKeyLabel
            )
        case .symbols:
            return symbolRows(
                settings: settings,
                includeGlobeKey: includeGlobeKey,
                returnKeySymbol: returnKeySymbol,
                returnKeyLabel: returnKeyLabel
            )
        }
    }

    // MARK: - Letters Layer

    private func letterRows(
        shiftState: ShiftState,
        settings: KeyboardSettings,
        includeGlobeKey: Bool,
        returnKeySymbol: String,
        returnKeyLabel: String?
    ) -> [[KeySpec]] {
        let isUpper = shiftState.isUppercase
        var result: [[KeySpec]] = []

        if settings.showNumberRow {
            let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
            result.append(digits.map { digit in
                KeySpec(title: digit, action: .character(digit), isNumberRow: true, widthMultiplier: 1.0)
            })
        }

        let row1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        var row2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
        if settings.language == .ptBR && settings.showDedicatedCedilla {
            row2.append("ç")
        }
        let row3 = ["z", "x", "c", "v", "b", "n", "m"]

        result.append(mapLetterRow(row1, uppercase: isUpper, showSecondary: settings.showSecondarySymbols))
        result.append(mapLetterRow(row2, uppercase: isUpper, showSecondary: settings.showSecondarySymbols))

        let shiftIcon: String
        switch shiftState {
        case .lower: shiftIcon = "shift"
        case .upper: shiftIcon = "shift.fill"
        case .capsLock: shiftIcon = "capslock.fill"
        }

        var thirdRow: [KeySpec] = [
            KeySpec(
                title: "",
                systemImage: shiftIcon,
                action: .shift,
                isSpecial: true,
                isHighlighted: shiftState != .lower,
                widthMultiplier: 1.48,
                accessibilityLabel: shiftState == .capsLock ? "Caps Lock" : "Shift"
            )
        ]
        thirdRow.append(contentsOf: mapLetterRow(row3, uppercase: isUpper, showSecondary: settings.showSecondarySymbols))
        thirdRow.append(
            KeySpec(
                title: "",
                systemImage: "delete.left",
                action: .backspace,
                isSpecial: true,
                widthMultiplier: 1.48,
                accessibilityLabel: "Apagar"
            )
        )
        result.append(thirdRow)

        result.append(
            bottomRow(
                modeKeyTitle: settings.layoutStyle == .samsung ? "!#1" : "123",
                modeKeyAction: .switchToNumbers,
                settings: settings,
                includeGlobeKey: includeGlobeKey,
                returnKeySymbol: returnKeySymbol,
                returnKeyLabel: returnKeyLabel
            )
        )

        return result
    }

    // MARK: - Numbers Layer

    private func numberRows(
        settings: KeyboardSettings,
        includeGlobeKey: Bool,
        returnKeySymbol: String,
        returnKeyLabel: String?
    ) -> [[KeySpec]] {
        let row1 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map {
            KeySpec(title: $0, action: .character($0))
        }
        let row2 = ["-", "/", ":", ";", "(", ")", "R$", "&", "@", "\""].map {
            KeySpec(title: $0, action: .character($0))
        }

        var row3: [KeySpec] = [
            KeySpec(title: "#+=", action: .switchToSymbols, isSpecial: true, widthMultiplier: 1.48, accessibilityLabel: "Mais símbolos")
        ]
        row3.append(contentsOf: [".", ",", "?", "!", "'"].map {
            KeySpec(title: $0, action: .character($0), widthMultiplier: 1.4)
        })
        row3.append(
            KeySpec(title: "", systemImage: "delete.left", action: .backspace, isSpecial: true, widthMultiplier: 1.48, accessibilityLabel: "Apagar")
        )

        let row4 = bottomRow(
            modeKeyTitle: "ABC",
            modeKeyAction: .switchToLetters,
            settings: settings,
            includeGlobeKey: includeGlobeKey,
            returnKeySymbol: returnKeySymbol,
            returnKeyLabel: returnKeyLabel
        )

        return [row1, row2, row3, row4]
    }

    // MARK: - Symbols Layer

    private func symbolRows(
        settings: KeyboardSettings,
        includeGlobeKey: Bool,
        returnKeySymbol: String,
        returnKeyLabel: String?
    ) -> [[KeySpec]] {
        let row1 = ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="].map {
            KeySpec(title: $0, action: .character($0))
        }
        let row2 = ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"].map {
            KeySpec(title: $0, action: .character($0))
        }

        var row3: [KeySpec] = [
            KeySpec(title: "123", action: .switchToNumbers, isSpecial: true, widthMultiplier: 1.48, accessibilityLabel: "Números")
        ]
        row3.append(contentsOf: [".", ",", "?", "!", "'"].map {
            KeySpec(title: $0, action: .character($0), widthMultiplier: 1.4)
        })
        row3.append(
            KeySpec(title: "", systemImage: "delete.left", action: .backspace, isSpecial: true, widthMultiplier: 1.48, accessibilityLabel: "Apagar")
        )

        let row4 = bottomRow(
            modeKeyTitle: "ABC",
            modeKeyAction: .switchToLetters,
            settings: settings,
            includeGlobeKey: includeGlobeKey,
            returnKeySymbol: returnKeySymbol,
            returnKeyLabel: returnKeyLabel
        )

        return [row1, row2, row3, row4]
    }

    // MARK: - Bottom Row (One UI 9 vs. Apple iOS 26)

    private func bottomRow(
        modeKeyTitle: String,
        modeKeyAction: KeyAction,
        settings: KeyboardSettings,
        includeGlobeKey: Bool,
        returnKeySymbol: String,
        returnKeyLabel: String?
    ) -> [KeySpec] {
        let returnAccessibility = returnKeyLabel ?? settings.language.returnLabel
        let spaceTitle = settings.layoutStyle == .samsung
            ? (settings.language == .ptBR ? "Português" : "English")
            : settings.language.spacebarLabel

        var row: [KeySpec] = [
            KeySpec(
                title: modeKeyTitle,
                action: modeKeyAction,
                isSpecial: true,
                widthMultiplier: settings.layoutStyle == .samsung ? 1.4 : 1.7
            )
        ]

        if includeGlobeKey {
            row.append(
                KeySpec(
                    title: "",
                    systemImage: "globe",
                    action: .nextKeyboard,
                    isSpecial: true,
                    widthMultiplier: settings.layoutStyle == .samsung ? 1.05 : 1.25,
                    accessibilityLabel: "Próximo teclado"
                )
            )
        }

        if settings.layoutStyle == .samsung {
            // Samsung One UI moderno: !#1 | , | Português (espaço limpo) | . | ↵ (SF Symbol)
            row.append(
                KeySpec(
                    title: ",",
                    action: .character(","),
                    isSpecial: false,
                    widthMultiplier: 0.95,
                    accessibilityLabel: "Vírgula"
                )
            )
            row.append(
                KeySpec(
                    title: spaceTitle,
                    action: .space,
                    isSpecial: false,
                    widthMultiplier: includeGlobeKey ? 4.2 : 5.25,
                    accessibilityLabel: "Espaço"
                )
            )
            row.append(
                KeySpec(
                    title: ".",
                    action: .character("."),
                    accentOptions: Self.accentMap["."] ?? [],
                    isSpecial: false,
                    widthMultiplier: 0.95,
                    accessibilityLabel: "Ponto"
                )
            )
            row.append(
                KeySpec(
                    title: "",
                    systemImage: returnKeySymbol,
                    action: .returnKey,
                    isSpecial: true,
                    isAccent: true,
                    widthMultiplier: 1.55,
                    accessibilityLabel: returnAccessibility
                )
            )
        } else {
            // Apple iOS 26: 123 | espaço amplo | ↵ (SF Symbol)
            row.append(
                KeySpec(
                    title: spaceTitle,
                    action: .space,
                    isSpecial: false,
                    widthMultiplier: includeGlobeKey ? 5.3 : 6.55,
                    accessibilityLabel: "Espaço"
                )
            )
            row.append(
                KeySpec(
                    title: "",
                    systemImage: returnKeySymbol,
                    action: .returnKey,
                    isSpecial: true,
                    isAccent: true,
                    widthMultiplier: 1.85,
                    accessibilityLabel: returnAccessibility
                )
            )
        }

        return row
    }

    // MARK: - Helpers

    private func mapLetterRow(_ chars: [String], uppercase: Bool, showSecondary: Bool) -> [KeySpec] {
        chars.map { raw in
            let display = uppercase ? raw.uppercased() : raw
            let rawAccents = Self.accentMap[raw] ?? []
            let accents = uppercase ? rawAccents.map { $0.uppercased() } : rawAccents
            let secondary = showSecondary ? Self.samsungSecondarySymbols[raw] : nil

            return KeySpec(
                title: display,
                secondaryTitle: secondary,
                action: .character(display),
                secondaryAction: secondary.map { .character($0) },
                accentOptions: accents,
                isSpecial: false,
                widthMultiplier: 1.0
            )
        }
    }
}

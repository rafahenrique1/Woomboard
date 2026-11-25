import Foundation

/// Estilo de layout principal do teclado: ergonomia Samsung ou padrão limpo Apple.
public enum KeyboardLayoutStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case samsung
    case apple

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .samsung: return "Samsung"
        case .apple: return "Apple"
        }
    }

    public var subtitle: String {
        switch self {
        case .samsung:
            return "Linha numérica, símbolos no toque longo, vírgula/ponto na base e barra de ferramentas."
        case .apple:
            return "Layout limpo padrão iOS com barra de espaço ampla e foco em simplicidade."
        }
    }
}

/// Idiomas suportados pelo teclado.
public enum KeyboardLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case ptBR = "pt-BR"
    case enUS = "en-US"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ptBR: return "Português (BR)"
        case .enUS: return "English (US)"
        }
    }

    public var shortCode: String {
        switch self {
        case .ptBR: return "PT"
        case .enUS: return "EN"
        }
    }

    public var spacebarLabel: String {
        switch self {
        case .ptBR: return "espaço"
        case .enUS: return "space"
        }
    }

    public var returnLabel: String {
        switch self {
        case .ptBR: return "retorno"
        case .enUS: return "return"
        }
    }

    public var textCheckerLocale: String {
        switch self {
        case .ptBR: return "pt_BR"
        case .enUS: return "en_US"
        }
    }

    public var next: KeyboardLanguage {
        switch self {
        case .ptBR: return .enUS
        case .enUS: return .ptBR
        }
    }
}

/// Altura ergonômica das teclas.
public enum KeyboardHeightPreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case compact
    case standard
    case comfortable

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .compact: return "Compacto"
        case .standard: return "Padrão"
        case .comfortable: return "Confortável"
        }
    }

    /// Altura base de cada fileira de teclas em pontos.
    public var rowHeight: Double {
        switch self {
        case .compact: return 38.0
        case .standard: return 43.0
        case .comfortable: return 48.0
        }
    }
}

/// Modo de digitação com uma mão (estilo Samsung / iOS).
public enum OneHandedMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case off
    case left
    case right

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .off: return "Desativado"
        case .left: return "Mão esquerda"
        case .right: return "Mão direita"
        }
    }
}

/// Intensidade do feedback tátil (Haptics).
public enum HapticIntensity: String, Codable, CaseIterable, Identifiable, Sendable {
    case off
    case light
    case medium

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .off: return "Desligado"
        case .light: return "Leve (Apple)"
        case .medium: return "Médio (Samsung)"
        }
    }
}

/// Atalho rápido de texto (snippet / texto fixado) disponível offline no teclado.
public struct TextSnippet: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var trigger: String
    public var expansion: String

    public init(id: String = UUID().uuidString, trigger: String, expansion: String) {
        self.id = id
        self.trigger = trigger
        self.expansion = expansion
    }

    public static let defaults: [TextSnippet] = [
        TextSnippet(id: "snippet-email", trigger: "@@", expansion: "seuemail@exemplo.com"),
        TextSnippet(id: "snippet-omw", trigger: "chegando", expansion: "Estou a caminho!"),
        TextSnippet(id: "snippet-obg", trigger: "obg", expansion: "Muito obrigado!")
    ]
}

/// Configurações do teclado compartilhadas entre o App Container e a Keyboard Extension.
public struct KeyboardSettings: Codable, Equatable, Sendable {
    public var selectedThemeID: String
    public var followSystemAppearance: Bool
    public var layoutStyle: KeyboardLayoutStyle
    public var language: KeyboardLanguage
    public var heightPreset: KeyboardHeightPreset
    public var oneHandedMode: OneHandedMode

    // Feedback
    public var enableHaptics: Bool
    public var hapticIntensity: HapticIntensity
    public var enableKeySounds: Bool
    public var showKeyPopup: Bool

    // Ergonomia & Funções Samsung / Apple
    public var showNumberRow: Bool
    public var showSecondarySymbols: Bool
    public var showToolbar: Bool
    public var showDedicatedCedilla: Bool
    public var enableSpacebarTrackpad: Bool
    public var autoCapitalization: Bool
    public var doubleSpacePeriod: Bool

    // Snippets pessoais
    public var snippets: [TextSnippet]

    public init(
        selectedThemeID: String = DefaultThemes.woomLight.id,
        followSystemAppearance: Bool = true,
        layoutStyle: KeyboardLayoutStyle = .samsung,
        language: KeyboardLanguage = .ptBR,
        heightPreset: KeyboardHeightPreset = .standard,
        oneHandedMode: OneHandedMode = .off,
        enableHaptics: Bool = true,
        hapticIntensity: HapticIntensity = .light,
        enableKeySounds: Bool = false,
        showKeyPopup: Bool = true,
        showNumberRow: Bool = true,
        showSecondarySymbols: Bool = true,
        showToolbar: Bool = true,
        showDedicatedCedilla: Bool = false,
        enableSpacebarTrackpad: Bool = true,
        autoCapitalization: Bool = true,
        doubleSpacePeriod: Bool = true,
        snippets: [TextSnippet] = TextSnippet.defaults
    ) {
        self.selectedThemeID = selectedThemeID
        self.followSystemAppearance = followSystemAppearance
        self.layoutStyle = layoutStyle
        self.language = language
        self.heightPreset = heightPreset
        self.oneHandedMode = oneHandedMode
        self.enableHaptics = enableHaptics
        self.hapticIntensity = hapticIntensity
        self.enableKeySounds = enableKeySounds
        self.showKeyPopup = showKeyPopup
        self.showNumberRow = showNumberRow
        self.showSecondarySymbols = showSecondarySymbols
        self.showToolbar = showToolbar
        self.showDedicatedCedilla = showDedicatedCedilla
        self.enableSpacebarTrackpad = enableSpacebarTrackpad
        self.autoCapitalization = autoCapitalization
        self.doubleSpacePeriod = doubleSpacePeriod
        self.snippets = snippets
    }

    /// Aplica os padrões ergonômicos recomendados ao alternar entre o layout Samsung e Apple.
    public mutating func applyLayoutPreset(_ style: KeyboardLayoutStyle) {
        layoutStyle = style
        switch style {
        case .samsung:
            showNumberRow = true
            showSecondarySymbols = true
            showToolbar = true
        case .apple:
            showNumberRow = false
            showSecondarySymbols = false
            showToolbar = false
        }
    }

    private enum CodingKeys: String, CodingKey {
        case selectedThemeID
        case followSystemAppearance
        case layoutStyle
        case language
        case heightPreset
        case oneHandedMode
        case enableHaptics
        case hapticIntensity
        case enableKeySounds
        case showKeyPopup
        case showNumberRow
        case showSecondarySymbols
        case showToolbar
        case showDedicatedCedilla
        case enableSpacebarTrackpad
        case autoCapitalization
        case doubleSpacePeriod
        case snippets
    }

    /// Decodificação resiliente para manter compatibilidade com versões anteriores salvas no App Group.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = KeyboardSettings()
        selectedThemeID = try c.decodeIfPresent(String.self, forKey: .selectedThemeID) ?? defaults.selectedThemeID
        followSystemAppearance = try c.decodeIfPresent(Bool.self, forKey: .followSystemAppearance) ?? defaults.followSystemAppearance
        layoutStyle = try c.decodeIfPresent(KeyboardLayoutStyle.self, forKey: .layoutStyle) ?? defaults.layoutStyle
        language = try c.decodeIfPresent(KeyboardLanguage.self, forKey: .language) ?? defaults.language
        heightPreset = try c.decodeIfPresent(KeyboardHeightPreset.self, forKey: .heightPreset) ?? defaults.heightPreset
        oneHandedMode = try c.decodeIfPresent(OneHandedMode.self, forKey: .oneHandedMode) ?? defaults.oneHandedMode
        enableHaptics = try c.decodeIfPresent(Bool.self, forKey: .enableHaptics) ?? defaults.enableHaptics
        hapticIntensity = try c.decodeIfPresent(HapticIntensity.self, forKey: .hapticIntensity) ?? defaults.hapticIntensity
        enableKeySounds = try c.decodeIfPresent(Bool.self, forKey: .enableKeySounds) ?? defaults.enableKeySounds
        showKeyPopup = try c.decodeIfPresent(Bool.self, forKey: .showKeyPopup) ?? defaults.showKeyPopup
        showNumberRow = try c.decodeIfPresent(Bool.self, forKey: .showNumberRow) ?? defaults.showNumberRow
        showSecondarySymbols = try c.decodeIfPresent(Bool.self, forKey: .showSecondarySymbols) ?? defaults.showSecondarySymbols
        showToolbar = try c.decodeIfPresent(Bool.self, forKey: .showToolbar) ?? defaults.showToolbar
        showDedicatedCedilla = try c.decodeIfPresent(Bool.self, forKey: .showDedicatedCedilla) ?? defaults.showDedicatedCedilla
        enableSpacebarTrackpad = try c.decodeIfPresent(Bool.self, forKey: .enableSpacebarTrackpad) ?? defaults.enableSpacebarTrackpad
        autoCapitalization = try c.decodeIfPresent(Bool.self, forKey: .autoCapitalization) ?? defaults.autoCapitalization
        doubleSpacePeriod = try c.decodeIfPresent(Bool.self, forKey: .doubleSpacePeriod) ?? defaults.doubleSpacePeriod
        snippets = try c.decodeIfPresent([TextSnippet].self, forKey: .snippets) ?? defaults.snippets
    }
}

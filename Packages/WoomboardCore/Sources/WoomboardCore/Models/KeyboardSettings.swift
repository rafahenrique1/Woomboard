import Foundation

/// Estilo de layout principal do teclado: ergonomia Samsung One UI moderno ou padrão limpo Apple iOS 26.
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
            return "One UI moderno: linha numérica, símbolos no toque longo, vírgula/ponto na base e toolbar."
        case .apple:
            return "Layout limpo padrão iOS 26 com barra de espaço ampla e foco em simplicidade."
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

/// Itens configuráveis da barra de ferramentas superior (estilo Samsung One UI).
public enum ToolbarItem: String, Codable, CaseIterable, Identifiable, Sendable {
    case emoji
    case clipboard
    case snippets
    case undo
    case oneHanded
    case layoutSwitch
    case language
    case settings

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .emoji: return "Emojis"
        case .clipboard: return "Área de transferência"
        case .snippets: return "Atalhos rápidos"
        case .undo: return "Desfazer"
        case .oneHanded: return "Modo uma mão"
        case .layoutSwitch: return "Alternar Samsung/Apple"
        case .language: return "Idioma (PT/EN)"
        case .settings: return "Ajustes rápidos"
        }
    }

    public var systemImage: String {
        switch self {
        case .emoji: return "face.smiling"
        case .clipboard: return "doc.on.clipboard"
        case .snippets: return "text.badge.star"
        case .undo: return "arrow.uturn.backward"
        case .oneHanded: return "hand.point.up.left"
        case .layoutSwitch: return "keyboard"
        case .language: return "globe"
        case .settings: return "gearshape"
        }
    }

    public static let defaultItems: [ToolbarItem] = [
        .emoji, .clipboard, .snippets, .undo, .oneHanded, .settings
    ]
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
    public var customTheme: KeyboardTheme?
    public var layoutStyle: KeyboardLayoutStyle
    public var language: KeyboardLanguage
    public var heightPreset: KeyboardHeightPreset
    /// Escala contínua de altura do teclado (0.80 a 1.65, limitada a 50% da tela no iOS).
    public var keyboardHeightScale: Double
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
    public var toolbarItems: [ToolbarItem]
    public var showDedicatedCedilla: Bool
    public var enableSpacebarTrackpad: Bool
    public var autoCapitalization: Bool
    public var doubleSpacePeriod: Bool

    // Produtividade offline (Onda 2)
    public var snippets: [TextSnippet]
    public var pinnedClipboardItems: [String]
    public var recentEmojis: [String]
    public var learnedWords: [String: Int]

    public init(
        selectedThemeID: String = DefaultThemes.woomLight.id,
        followSystemAppearance: Bool = true,
        customTheme: KeyboardTheme? = nil,
        layoutStyle: KeyboardLayoutStyle = .samsung,
        language: KeyboardLanguage = .ptBR,
        heightPreset: KeyboardHeightPreset = .standard,
        keyboardHeightScale: Double = 1.0,
        oneHandedMode: OneHandedMode = .off,
        enableHaptics: Bool = true,
        hapticIntensity: HapticIntensity = .light,
        enableKeySounds: Bool = false,
        showKeyPopup: Bool = true,
        showNumberRow: Bool = true,
        showSecondarySymbols: Bool = true,
        showToolbar: Bool = true,
        toolbarItems: [ToolbarItem] = ToolbarItem.defaultItems,
        showDedicatedCedilla: Bool = false,
        enableSpacebarTrackpad: Bool = true,
        autoCapitalization: Bool = true,
        doubleSpacePeriod: Bool = true,
        snippets: [TextSnippet] = TextSnippet.defaults,
        pinnedClipboardItems: [String] = [],
        recentEmojis: [String] = ["😂", "❤️", "🔥", "👍", "😍", "🙏", "😊", "🎉"],
        learnedWords: [String: Int] = [:]
    ) {
        self.selectedThemeID = selectedThemeID
        self.followSystemAppearance = followSystemAppearance
        self.customTheme = customTheme
        self.layoutStyle = layoutStyle
        self.language = language
        self.heightPreset = heightPreset
        self.keyboardHeightScale = min(max(keyboardHeightScale, 0.80), 1.65)
        self.oneHandedMode = oneHandedMode
        self.enableHaptics = enableHaptics
        self.hapticIntensity = hapticIntensity
        self.enableKeySounds = enableKeySounds
        self.showKeyPopup = showKeyPopup
        self.showNumberRow = showNumberRow
        self.showSecondarySymbols = showSecondarySymbols
        self.showToolbar = showToolbar
        self.toolbarItems = toolbarItems
        self.showDedicatedCedilla = showDedicatedCedilla
        self.enableSpacebarTrackpad = enableSpacebarTrackpad
        self.autoCapitalization = autoCapitalization
        self.doubleSpacePeriod = doubleSpacePeriod
        self.snippets = snippets
        self.pinnedClipboardItems = pinnedClipboardItems
        self.recentEmojis = recentEmojis
        self.learnedWords = learnedWords
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

    /// Registra uma palavra digitada com frequência para melhorar sugestões offline (limite de 200 palavras).
    public mutating func recordLearnedWord(_ rawWord: String) {
        let word = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard word.count >= 3, word.count <= 24, word.allSatisfy({ $0.isLetter }) else { return }
        learnedWords[word, default: 0] += 1
        if learnedWords.count > 200 {
            if let leastUsed = learnedWords.min(by: { $0.value < $1.value })?.key {
                learnedWords.removeValue(forKey: leastUsed)
            }
        }
    }

    /// Registra um emoji usado recentemente (mantém os últimos 24).
    public mutating func recordRecentEmoji(_ emoji: String) {
        recentEmojis.removeAll { $0 == emoji }
        recentEmojis.insert(emoji, at: 0)
        if recentEmojis.count > 24 {
            recentEmojis = Array(recentEmojis.prefix(24))
        }
    }

    private enum CodingKeys: String, CodingKey {
        case selectedThemeID
        case followSystemAppearance
        case customTheme
        case layoutStyle
        case language
        case heightPreset
        case keyboardHeightScale
        case oneHandedMode
        case enableHaptics
        case hapticIntensity
        case enableKeySounds
        case showKeyPopup
        case showNumberRow
        case showSecondarySymbols
        case showToolbar
        case toolbarItems
        case showDedicatedCedilla
        case enableSpacebarTrackpad
        case autoCapitalization
        case doubleSpacePeriod
        case snippets
        case pinnedClipboardItems
        case recentEmojis
        case learnedWords
    }

    /// Decodificação resiliente para manter compatibilidade com versões anteriores.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = KeyboardSettings()
        selectedThemeID = try c.decodeIfPresent(String.self, forKey: .selectedThemeID) ?? defaults.selectedThemeID
        followSystemAppearance = try c.decodeIfPresent(Bool.self, forKey: .followSystemAppearance) ?? defaults.followSystemAppearance
        customTheme = try c.decodeIfPresent(KeyboardTheme.self, forKey: .customTheme)
        layoutStyle = try c.decodeIfPresent(KeyboardLayoutStyle.self, forKey: .layoutStyle) ?? defaults.layoutStyle
        language = try c.decodeIfPresent(KeyboardLanguage.self, forKey: .language) ?? defaults.language
        heightPreset = try c.decodeIfPresent(KeyboardHeightPreset.self, forKey: .heightPreset) ?? defaults.heightPreset
        keyboardHeightScale = try c.decodeIfPresent(Double.self, forKey: .keyboardHeightScale) ?? defaults.keyboardHeightScale
        oneHandedMode = try c.decodeIfPresent(OneHandedMode.self, forKey: .oneHandedMode) ?? defaults.oneHandedMode
        enableHaptics = try c.decodeIfPresent(Bool.self, forKey: .enableHaptics) ?? defaults.enableHaptics
        hapticIntensity = try c.decodeIfPresent(HapticIntensity.self, forKey: .hapticIntensity) ?? defaults.hapticIntensity
        enableKeySounds = try c.decodeIfPresent(Bool.self, forKey: .enableKeySounds) ?? defaults.enableKeySounds
        showKeyPopup = try c.decodeIfPresent(Bool.self, forKey: .showKeyPopup) ?? defaults.showKeyPopup
        showNumberRow = try c.decodeIfPresent(Bool.self, forKey: .showNumberRow) ?? defaults.showNumberRow
        showSecondarySymbols = try c.decodeIfPresent(Bool.self, forKey: .showSecondarySymbols) ?? defaults.showSecondarySymbols
        showToolbar = try c.decodeIfPresent(Bool.self, forKey: .showToolbar) ?? defaults.showToolbar
        toolbarItems = try c.decodeIfPresent([ToolbarItem].self, forKey: .toolbarItems) ?? defaults.toolbarItems
        showDedicatedCedilla = try c.decodeIfPresent(Bool.self, forKey: .showDedicatedCedilla) ?? defaults.showDedicatedCedilla
        enableSpacebarTrackpad = try c.decodeIfPresent(Bool.self, forKey: .enableSpacebarTrackpad) ?? defaults.enableSpacebarTrackpad
        autoCapitalization = try c.decodeIfPresent(Bool.self, forKey: .autoCapitalization) ?? defaults.autoCapitalization
        doubleSpacePeriod = try c.decodeIfPresent(Bool.self, forKey: .doubleSpacePeriod) ?? defaults.doubleSpacePeriod
        snippets = try c.decodeIfPresent([TextSnippet].self, forKey: .snippets) ?? defaults.snippets
        pinnedClipboardItems = try c.decodeIfPresent([String].self, forKey: .pinnedClipboardItems) ?? defaults.pinnedClipboardItems
        recentEmojis = try c.decodeIfPresent([String].self, forKey: .recentEmojis) ?? defaults.recentEmojis
        learnedWords = try c.decodeIfPresent([String: Int].self, forKey: .learnedWords) ?? defaults.learnedWords
    }
}

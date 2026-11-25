import Foundation

/// Ações emitidas pelas teclas e barra superior para o KeyboardViewController.
public enum KeyAction: Equatable, Sendable {
    case character(String)
    case space
    case backspace
    case deleteWordBackward
    case returnKey
    case shift
    case capsLock
    case switchToNumbers
    case switchToLetters
    case switchToSymbols
    case nextKeyboard
    case switchLanguage
    case insertSuggestion(String)
    case insertSnippet(String)
    case moveCursor(Int)
    case pasteClipboard
    case toggleOneHanded(OneHandedMode)
    case toggleLayoutStyle
    case openSnippetsDrawer
    case openQuickSettings
}

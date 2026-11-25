import AudioToolbox
import UIKit
import WoomboardCore

/// Ponto de entrada da Custom Keyboard Extension do Woomboard — Onda 2 + 120Hz ProMotion.
/// - Zero travamentos: UITextChecker assíncrono em fila dedicada, reutilização in-place das teclas e haptics pré-aquecidos.
/// - Recursos: Emojis embutidos, Clipboard inteligente + fixados, Undo local, aprendizado de palavras e Ajustes Rápidos.
final class KeyboardViewController: UIInputViewController {
    private let settingsStore = SharedSettingsStore()
    private let layoutEngine = KeyboardLayoutEngine()

    // Fila serial dedicada para UITextChecker (nunca bloqueia a main thread a 120Hz)
    private let suggestionQueue = DispatchQueue(label: "com.woomboard.suggestions", qos: .userInteractive)
    private let textChecker = UITextChecker()
    private var suggestionGeneration: Int = 0

    private var suggestionEngine = SuggestionEngine()
    private var settings: KeyboardSettings = KeyboardSettings()
    private var currentTheme: KeyboardTheme = DefaultThemes.woomLight

    private var currentLayer: KeyboardLayer = .letters
    private var shiftState: ShiftState = .upper
    private var lastShiftTapDate: Date = .distantPast
    private var lastSpaceTapDate: Date = .distantPast

    // Histórico local leve para Undo/Redo
    private enum EditOperation {
        case inserted(String)
        case deleted(String)
    }
    private var undoStack: [EditOperation] = []
    private var redoStack: [EditOperation] = []

    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    private let keyboardView = KeyboardView()
    private let suggestionBar = SuggestionBarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadConfiguration()
        setupHierarchy()
        bindActions()
        syncAutoCapitalization()
        renderCurrentLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadConfiguration()
        applyThemeAndSettings()
        syncAutoCapitalization()
        renderCurrentLayout()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        syncAutoCapitalization()
        scheduleSuggestionsUpdate()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        currentTheme = resolvedTheme()
        applyThemeAndSettings()
    }

    // MARK: - Setup

    private func loadConfiguration() {
        settings = settingsStore.loadSettings()
        currentTheme = resolvedTheme()
        suggestionEngine = SuggestionEngine(snippets: settings.snippets, learnedWords: settings.learnedWords)
    }

    private func resolvedTheme() -> KeyboardTheme {
        if let custom = settings.customTheme, settings.selectedThemeID == custom.id {
            return custom
        }
        if settings.followSystemAppearance,
           settings.selectedThemeID == DefaultThemes.woomLight.id || settings.selectedThemeID == DefaultThemes.woomDark.id {
            return traitCollection.userInterfaceStyle == .dark ? DefaultThemes.woomDark : DefaultThemes.woomLight
        }
        return DefaultThemes.theme(for: settings.selectedThemeID)
    }

    private func setupHierarchy() {
        let containerStack = UIStackView(arrangedSubviews: [suggestionBar, keyboardView])
        containerStack.axis = .vertical
        containerStack.spacing = 4
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            containerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
            suggestionBar.heightAnchor.constraint(equalToConstant: 40)
        ])

        applyThemeAndSettings()
    }

    private func bindActions() {
        keyboardView.onAction = { [weak self] action, sender, event in
            self?.handle(action: action, sender: sender, event: event)
        }

        keyboardView.onPrepareHaptics = { [weak self] in
            guard let self, self.settings.enableHaptics else { return }
            switch self.settings.hapticIntensity {
            case .off: break
            case .light: self.lightHaptic.prepare()
            case .medium: self.mediumHaptic.prepare()
            }
        }

        keyboardView.onBackspaceRepeat = { [weak self] deleteWord in
            guard let self else { return }
            self.triggerFeedback(isSpecial: true)
            if deleteWord {
                self.deleteWordBackward()
            } else {
                self.deleteSingleBackwardAndRecord()
            }
            self.scheduleSuggestionsUpdate()
        }

        keyboardView.onSpacebarPan = { [weak self] offset in
            guard let self else { return }
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
            if self.settings.enableHaptics && self.settings.hapticIntensity != .off {
                self.lightHaptic.impactOccurred(intensity: 0.45)
            }
        }

        keyboardView.onSelectAccentOrSymbol = { [weak self] value in
            guard let self else { return }
            self.triggerFeedback(isSpecial: false)
            self.insertAndRecord(value)
            if self.shiftState == .upper {
                self.shiftState = .lower
                self.renderCurrentLayout()
            }
            self.scheduleSuggestionsUpdate()
        }

        keyboardView.onUpdateSettings = { [weak self] mutate in
            guard let self else { return }
            mutate(&self.settings)
            self.settingsStore.saveSettings(self.settings)
            self.currentTheme = self.resolvedTheme()
            self.suggestionEngine = SuggestionEngine(snippets: self.settings.snippets, learnedWords: self.settings.learnedWords)
            self.applyThemeAndSettings()
            self.renderCurrentLayout()
        }

        suggestionBar.onSelectSuggestion = { [weak self] suggestion in
            self?.replaceCurrentWord(with: suggestion)
        }

        suggestionBar.onToolbarAction = { [weak self] action in
            guard let self else { return }
            self.handle(action: action, sender: self.suggestionBar, event: nil)
        }
    }

    private func applyThemeAndSettings() {
        let usesNativeBackdrop = (currentTheme.id == DefaultThemes.woomLight.id || currentTheme.id == DefaultThemes.woomDark.id)
        view.backgroundColor = usesNativeBackdrop ? .clear : UIColor(hex: currentTheme.backgroundHex)
        keyboardView.apply(theme: currentTheme, settings: settings)
        suggestionBar.apply(theme: currentTheme, settings: settings)
    }

    private func renderCurrentLayout() {
        let rows = layoutEngine.rows(
            layer: currentLayer,
            shiftState: shiftState,
            settings: settings,
            includeGlobeKey: needsInputModeSwitchKey,
            returnKeySymbol: resolvedReturnKeySymbol(),
            returnKeyLabel: resolvedReturnKeyTitle()
        )
        keyboardView.configure(rows: rows, theme: currentTheme, settings: settings)
    }

    // MARK: - Action Handling

    private func handle(action: KeyAction, sender: UIView, event: UIEvent?) {
        let isSpecialAction: Bool
        switch action {
        case .character, .space, .insertSuggestion, .insertSnippet, .insertEmoji:
            isSpecialAction = false
        default:
            isSpecialAction = true
        }
        triggerFeedback(isSpecial: isSpecialAction)

        switch action {
        case .character(let value):
            insertAndRecord(value)
            if currentLayer == .letters && shiftState == .upper {
                shiftState = .lower
                renderCurrentLayout()
            }

        case .space:
            learnCurrentWordBeforeCommit()
            handleSpaceKey()

        case .backspace:
            deleteSingleBackwardAndRecord()
            syncAutoCapitalization()

        case .deleteWordBackward:
            deleteWordBackward()
            syncAutoCapitalization()

        case .returnKey:
            learnCurrentWordBeforeCommit()
            insertAndRecord("\n")
            if currentLayer != .letters {
                currentLayer = .letters
            }
            if settings.autoCapitalization && shiftState == .lower {
                shiftState = .upper
            }
            renderCurrentLayout()

        case .shift:
            handleShiftTap()

        case .capsLock:
            shiftState = (shiftState == .capsLock) ? .lower : .capsLock
            renderCurrentLayout()

        case .switchToNumbers:
            keyboardView.hideDrawers()
            currentLayer = .numbers
            renderCurrentLayout()

        case .switchToSymbols:
            keyboardView.hideDrawers()
            currentLayer = .symbols
            renderCurrentLayout()

        case .switchToLetters:
            keyboardView.hideDrawers()
            currentLayer = .letters
            syncAutoCapitalization()
            renderCurrentLayout()

        case .nextKeyboard:
            if let event {
                handleInputModeList(from: sender, with: event)
            } else {
                advanceToNextInputMode()
            }

        case .switchLanguage:
            settings.language = settings.language.next
            settingsStore.saveSettings(settings)
            applyThemeAndSettings()
            renderCurrentLayout()

        case .toggleLayoutStyle:
            let nextStyle: KeyboardLayoutStyle = (settings.layoutStyle == .samsung) ? .apple : .samsung
            settings.applyLayoutPreset(nextStyle)
            settingsStore.saveSettings(settings)
            applyThemeAndSettings()
            renderCurrentLayout()

        case .toggleOneHanded(let mode):
            settings.oneHandedMode = mode
            settingsStore.saveSettings(settings)
            applyThemeAndSettings()
            renderCurrentLayout()

        case .openEmojiDrawer:
            keyboardView.toggleEmojiDrawer()

        case .openClipboardDrawer:
            let currentPaste = hasFullAccess ? UIPasteboard.general.string : nil
            keyboardView.toggleClipboardDrawer(currentPasteboardText: currentPaste)

        case .openSnippetsDrawer:
            keyboardView.toggleSnippetsDrawer(snippets: settings.snippets)

        case .openQuickSettings:
            keyboardView.toggleQuickSettingsDrawer()

        case .pasteClipboard:
            if hasFullAccess, let pasted = UIPasteboard.general.string, !pasted.isEmpty {
                insertAndRecord(pasted)
            }

        case .undo:
            performUndo()

        case .redo:
            performRedo()

        case .insertSuggestion(let suggestion):
            replaceCurrentWord(with: suggestion)

        case .insertSnippet(let text):
            insertAndRecord(text)

        case .insertEmoji(let emoji):
            insertAndRecord(emoji)
            settings.recordRecentEmoji(emoji)
            settingsStore.saveSettings(settings)

        case .moveCursor(let offset):
            textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
        }

        scheduleSuggestionsUpdate()
    }

    // MARK: - Undo / Redo & Text Helpers

    private func insertAndRecord(_ text: String) {
        textDocumentProxy.insertText(text)
        pushUndo(.inserted(text))
    }

    private func deleteSingleBackwardAndRecord() {
        let deletedChar = textDocumentProxy.documentContextBeforeInput?.last.map(String.init) ?? ""
        textDocumentProxy.deleteBackward()
        if !deletedChar.isEmpty {
            pushUndo(.deleted(deletedChar))
        }
    }

    private func pushUndo(_ op: EditOperation) {
        undoStack.append(op)
        if undoStack.count > 25 {
            undoStack.removeFirst()
        }
        redoStack.removeAll(keepingCapacity: true)
    }

    private func performUndo() {
        guard let last = undoStack.popLast() else { return }
        switch last {
        case .inserted(let text):
            for _ in 0..<text.count {
                textDocumentProxy.deleteBackward()
            }
            redoStack.append(.inserted(text))
        case .deleted(let text):
            textDocumentProxy.insertText(text)
            redoStack.append(.deleted(text))
        }
        syncAutoCapitalization()
    }

    private func performRedo() {
        guard let last = redoStack.popLast() else { return }
        switch last {
        case .inserted(let text):
            textDocumentProxy.insertText(text)
            undoStack.append(.inserted(text))
        case .deleted(let text):
            for _ in 0..<text.count {
                textDocumentProxy.deleteBackward()
            }
            undoStack.append(.deleted(text))
        }
        syncAutoCapitalization()
    }

    private func learnCurrentWordBeforeCommit() {
        let word = suggestionEngine.currentWord(forContextBeforeInput: textDocumentProxy.documentContextBeforeInput)
        guard word.count >= 3 else { return }
        settings.recordLearnedWord(word)
        suggestionEngine = SuggestionEngine(snippets: settings.snippets, learnedWords: settings.learnedWords)
        settingsStore.saveSettings(settings)
    }

    // MARK: - Ergonomic Behaviors

    private func handleShiftTap() {
        let now = Date()
        let isDoubleTap = now.timeIntervalSince(lastShiftTapDate) < 0.35
        lastShiftTapDate = now

        if isDoubleTap && shiftState == .upper {
            shiftState = .capsLock
        } else {
            switch shiftState {
            case .lower: shiftState = .upper
            case .upper, .capsLock: shiftState = .lower
            }
        }
        renderCurrentLayout()
    }

    private func handleSpaceKey() {
        let now = Date()
        let isDoubleTap = now.timeIntervalSince(lastSpaceTapDate) < 0.35
        lastSpaceTapDate = now

        if settings.doubleSpacePeriod,
           isDoubleTap,
           let before = textDocumentProxy.documentContextBeforeInput,
           before.hasSuffix(" "),
           before.count >= 2 {
            let previousChar = before[before.index(before.endIndex, offsetBy: -2)]
            if previousChar.isLetter || previousChar.isNumber {
                textDocumentProxy.deleteBackward()
                insertAndRecord(". ")
                if settings.autoCapitalization && shiftState == .lower {
                    shiftState = .upper
                    renderCurrentLayout()
                }
                return
            }
        }

        insertAndRecord(" ")
        if currentLayer != .letters {
            currentLayer = .letters
            syncAutoCapitalization()
            renderCurrentLayout()
        } else {
            syncAutoCapitalization()
        }
    }

    private func deleteWordBackward() {
        guard let before = textDocumentProxy.documentContextBeforeInput, !before.isEmpty else {
            textDocumentProxy.deleteBackward()
            return
        }

        var deletedChars: [Character] = []
        var sawNonWhitespace = false

        for char in before.reversed() {
            if char.isWhitespace {
                if sawNonWhitespace { break }
                deletedChars.append(char)
            } else {
                sawNonWhitespace = true
                deletedChars.append(char)
            }
        }

        let count = max(deletedChars.count, 1)
        for _ in 0..<count {
            textDocumentProxy.deleteBackward()
        }
        if !deletedChars.isEmpty {
            pushUndo(.deleted(String(deletedChars.reversed())))
        }
    }

    private func syncAutoCapitalization() {
        guard settings.autoCapitalization, shiftState != .capsLock, currentLayer == .letters else { return }

        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let shouldCapitalize: Bool
        if before.isEmpty {
            shouldCapitalize = true
        } else if before.hasSuffix(". ") || before.hasSuffix("! ") || before.hasSuffix("? ") || before.hasSuffix("\n") {
            shouldCapitalize = true
        } else {
            shouldCapitalize = false
        }

        let targetState: ShiftState = shouldCapitalize ? .upper : .lower
        if shiftState != targetState {
            shiftState = targetState
            renderCurrentLayout()
        }
    }

    // MARK: - Async 120Hz Suggestions (UITextChecker fora da Main Thread)

    private func scheduleSuggestionsUpdate() {
        suggestionGeneration += 1
        let generation = suggestionGeneration
        let context = textDocumentProxy.documentContextBeforeInput
        let engine = suggestionEngine
        let locale = settings.language.textCheckerLocale
        let currentWord = engine.currentWord(forContextBeforeInput: context)

        if currentWord.isEmpty {
            suggestionBar.update(suggestions: [])
            return
        }

        // Resposta imediata de snippets/palavras aprendidas sem esperar UITextChecker
        let fastResults = engine.suggestions(forContextBeforeInput: context)
        if !fastResults.isEmpty {
            suggestionBar.update(suggestions: fastResults)
        }

        guard currentWord.count >= 2 else { return }

        suggestionQueue.async { [weak self] in
            guard let self else { return }
            let range = NSRange(location: 0, length: currentWord.utf16.count)
            var systemSuggestions: [String] = []

            if let completions = self.textChecker.completions(forPartialWordRange: range, in: currentWord, language: locale) {
                systemSuggestions.append(contentsOf: completions.prefix(3))
            }

            let misspelled = self.textChecker.rangeOfMisspelledWord(
                in: currentWord,
                range: range,
                startingAt: 0,
                wrap: false,
                language: locale
            )
            if misspelled.location != NSNotFound,
               let guesses = self.textChecker.guesses(forWordRange: misspelled, in: currentWord, language: locale) {
                systemSuggestions.insert(contentsOf: guesses.prefix(2), at: 0)
            }

            let combined = engine.suggestions(
                forContextBeforeInput: context,
                systemCompletions: systemSuggestions
            )

            DispatchQueue.main.async { [weak self] in
                guard let self, self.suggestionGeneration == generation else { return }
                self.suggestionBar.update(suggestions: combined)
            }
        }
    }

    private func replaceCurrentWord(with suggestion: String) {
        let context = textDocumentProxy.documentContextBeforeInput
        let token = suggestionEngine.currentWord(forContextBeforeInput: context)
        for _ in 0..<token.count {
            textDocumentProxy.deleteBackward()
        }
        insertAndRecord(suggestion + " ")
        settings.recordLearnedWord(suggestion)
        settingsStore.saveSettings(settings)
        syncAutoCapitalization()
        scheduleSuggestionsUpdate()
    }

    // MARK: - Feedback & Return Key

    private func triggerFeedback(isSpecial: Bool) {
        if settings.enableHaptics {
            switch settings.hapticIntensity {
            case .off:
                break
            case .light:
                lightHaptic.impactOccurred()
            case .medium:
                mediumHaptic.impactOccurred()
            }
        }

        if settings.enableKeySounds {
            AudioServicesPlaySystemSound(isSpecial ? 1155 : 1104)
        }
    }

    private func resolvedReturnKeySymbol() -> String {
        switch textDocumentProxy.returnKeyType {
        case .search: return "magnifyingglass"
        case .send: return "paperplane.fill"
        case .go: return "arrow.right"
        case .done: return "checkmark"
        case .next: return "arrow.right.to.line"
        default: return "return"
        }
    }

    private func resolvedReturnKeyTitle() -> String {
        let isPT = settings.language == .ptBR
        switch textDocumentProxy.returnKeyType {
        case .search: return isPT ? "buscar" : "search"
        case .send: return isPT ? "enviar" : "send"
        case .go: return isPT ? "ir" : "go"
        case .done: return isPT ? "ok" : "done"
        case .next: return isPT ? "próx." : "next"
        default: return settings.language.returnLabel
        }
    }
}

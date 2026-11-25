import UIKit
import WoomboardCore

/// View principal otimizada para 120Hz ProMotion:
/// - Reutiliza `KeyButton`s no lugar quando o formato das fileiras não muda (zero recriação no Shift!)
/// - Hospeda modo uma mão, KeyPopupView, EmojiDrawerView, Clipboard inteligente, Snippets e Ajustes Rápidos.
final class KeyboardView: UIView {
    var onAction: ((KeyAction, UIView, UIEvent?) -> Void)?
    var onBackspaceRepeat: ((_ deleteWord: Bool) -> Void)?
    var onSpacebarPan: ((Int) -> Void)?
    var onSelectAccentOrSymbol: ((String) -> Void)?
    var onUpdateSettings: (((inout KeyboardSettings) -> Void) -> Void)?
    var onPrepareHaptics: (() -> Void)?

    private var currentTheme: KeyboardTheme = DefaultThemes.woomLight
    private var currentSettings: KeyboardSettings = KeyboardSettings()

    // Cache de estrutura para reutilização in-place a 120Hz
    private var rowButtons: [[KeyButton]] = []
    private var lastRowSignature: String = ""

    private let contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let rowsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 9
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let oneHandedRail: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.isHidden = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let popupView = KeyPopupView()
    private let emojiDrawer: EmojiDrawerView = {
        let view = EmojiDrawerView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Gaveta compartilhada (Clipboard, Snippets ou Ajustes Rápidos)
    private let drawerOverlay: UIView = {
        let view = UIView()
        view.isHidden = true
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let drawerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private enum DrawerMode {
        case none
        case emoji
        case clipboard
        case snippets
        case quickSettings
    }
    private var activeDrawerMode: DrawerMode = .none

    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var railLeadingConstraint: NSLayoutConstraint?
    private var railTrailingConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false

        addSubview(contentContainer)
        addSubview(oneHandedRail)
        contentContainer.addSubview(rowsStack)
        addSubview(emojiDrawer)
        addSubview(drawerOverlay)
        addSubview(popupView)

        setupDrawerOverlay()
        setupEmojiDrawerCallbacks()

        let leading = contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor)
        let railLeading = oneHandedRail.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        let railTrailing = oneHandedRail.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        let height = heightAnchor.constraint(equalToConstant: 220)

        leadingConstraint = leading
        trailingConstraint = trailing
        railLeadingConstraint = railLeading
        railTrailingConstraint = railTrailing
        heightConstraint = height

        NSLayoutConstraint.activate([
            height,
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            leading,
            trailing,

            rowsStack.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),

            oneHandedRail.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            oneHandedRail.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            oneHandedRail.widthAnchor.constraint(equalToConstant: 44),

            emojiDrawer.topAnchor.constraint(equalTo: topAnchor),
            emojiDrawer.leadingAnchor.constraint(equalTo: leadingAnchor),
            emojiDrawer.trailingAnchor.constraint(equalTo: trailingAnchor),
            emojiDrawer.bottomAnchor.constraint(equalTo: bottomAnchor),

            drawerOverlay.topAnchor.constraint(equalTo: topAnchor),
            drawerOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            drawerOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            drawerOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configura ou atualiza in-place as teclas. Quando apenas Shift/CapsLock/idioma muda,
    /// atualiza cada `KeyButton` sem destruir views nem refazer constraints (120Hz sem engasgos).
    func configure(rows: [[KeySpec]], theme: KeyboardTheme, settings: KeyboardSettings) {
        currentTheme = theme
        currentSettings = settings
        popupView.hide()

        let signature = makeSignature(rows: rows, settings: settings)
        if signature == lastRowSignature && rowButtons.count == rows.count {
            for (rIdx, row) in rows.enumerated() {
                for (cIdx, spec) in row.enumerated() {
                    let button = rowButtons[rIdx][cIdx]
                    button.enableSpacebarTrackpad = settings.enableSpacebarTrackpad
                    button.update(spec: spec, theme: theme)
                }
            }
            if activeDrawerMode == .quickSettings {
                renderQuickSettingsDrawer()
            }
            return
        }

        lastRowSignature = signature
        rowButtons.removeAll(keepingCapacity: true)

        let baseRowHeight = CGFloat(settings.heightPreset.rowHeight)
        let numberRowHeight = round(baseRowHeight * 0.84)
        let rowSpacing: CGFloat = rows.count >= 5 ? 7 : 9
        rowsStack.spacing = rowSpacing

        var totalHeight: CGFloat = 0
        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for (idx, row) in rows.enumerated() {
            let isNumRow = row.first?.isNumberRow == true
            let rowHeight = isNumRow ? numberRowHeight : baseRowHeight
            let (rowContainer, buttons) = buildProportionalRow(specs: row, theme: theme, settings: settings)
            rowContainer.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
            rowsStack.addArrangedSubview(rowContainer)
            rowButtons.append(buttons)
            totalHeight += rowHeight
            if idx < rows.count - 1 {
                totalHeight += rowSpacing
            }
        }

        heightConstraint?.constant = totalHeight
        updateOneHandedConstraints(mode: settings.oneHandedMode)

        if activeDrawerMode == .quickSettings {
            renderQuickSettingsDrawer()
        }
    }

    func apply(theme: KeyboardTheme, settings: KeyboardSettings) {
        currentTheme = theme
        currentSettings = settings
        backgroundColor = .clear
        drawerOverlay.backgroundColor = UIColor(hex: theme.backgroundHex).withAlphaComponent(0.96)

        for row in rowButtons {
            for button in row {
                button.enableSpacebarTrackpad = settings.enableSpacebarTrackpad
                button.apply(theme: theme)
            }
        }
    }

    // MARK: - Drawers (Emoji, Clipboard, Snippets, Quick Settings)

    func toggleEmojiDrawer() {
        if activeDrawerMode == .emoji {
            hideDrawers()
            return
        }
        hideDrawers()
        activeDrawerMode = .emoji
        emojiDrawer.configure(recentEmojis: currentSettings.recentEmojis, theme: currentTheme)
        emojiDrawer.isHidden = false
        bringSubviewToFront(emojiDrawer)
    }

    func toggleClipboardDrawer(currentPasteboardText: String?) {
        if activeDrawerMode == .clipboard {
            hideDrawers()
            return
        }
        hideDrawers()
        activeDrawerMode = .clipboard
        renderClipboardDrawer(currentPasteboardText: currentPasteboardText)
        drawerOverlay.isHidden = false
        bringSubviewToFront(drawerOverlay)
    }

    func toggleSnippetsDrawer(snippets: [TextSnippet]) {
        if activeDrawerMode == .snippets {
            hideDrawers()
            return
        }
        hideDrawers()
        activeDrawerMode = .snippets
        drawerOverlay.backgroundColor = UIColor(hex: currentTheme.backgroundHex).withAlphaComponent(0.96)
        clearDrawerStack()

        drawerStack.addArrangedSubview(makeDrawerHeader(title: "Atalhos rápidos"))

        if snippets.isEmpty {
            drawerStack.addArrangedSubview(makeEmptyLabel("Adicione atalhos no app Woomboard."))
        } else {
            for snippet in snippets.prefix(5) {
                let button = makeListButton(title: "\(snippet.trigger)  →  \(snippet.expansion)") { [weak self] btn in
                    self?.hideDrawers()
                    self?.onAction?(.insertSnippet(snippet.expansion), btn, nil)
                }
                drawerStack.addArrangedSubview(button)
            }
        }

        drawerOverlay.isHidden = false
        bringSubviewToFront(drawerOverlay)
    }

    func toggleQuickSettingsDrawer() {
        if activeDrawerMode == .quickSettings {
            hideDrawers()
            return
        }
        hideDrawers()
        activeDrawerMode = .quickSettings
        renderQuickSettingsDrawer()
        drawerOverlay.isHidden = false
        bringSubviewToFront(drawerOverlay)
    }

    func hideDrawers() {
        activeDrawerMode = .none
        drawerOverlay.isHidden = true
        emojiDrawer.isHidden = true
    }

    private func renderClipboardDrawer(currentPasteboardText: String?) {
        drawerOverlay.backgroundColor = UIColor(hex: currentTheme.backgroundHex).withAlphaComponent(0.97)
        clearDrawerStack()

        drawerStack.addArrangedSubview(makeDrawerHeader(title: "Área de transferência"))

        if let current = currentPasteboardText, !current.isEmpty {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6

            let insertBtn = makeListButton(title: "📋  \(current)") { [weak self] btn in
                self?.hideDrawers()
                self?.onAction?(.insertSnippet(current), btn, nil)
            }

            let isPinned = currentSettings.pinnedClipboardItems.contains(current)
            let pinBtn = UIButton(type: .system)
            pinBtn.setImage(UIImage(systemName: isPinned ? "pin.slash.fill" : "pin.fill"), for: .normal)
            pinBtn.tintColor = UIColor(hex: currentTheme.accentHex)
            pinBtn.backgroundColor = UIColor(hex: currentTheme.keyBackgroundHex)
            pinBtn.layer.cornerRadius = 9
            pinBtn.widthAnchor.constraint(equalToConstant: 42).isActive = true
            pinBtn.addAction(UIAction { [weak self] _ in
                self?.onUpdateSettings? { s in
                    if let idx = s.pinnedClipboardItems.firstIndex(of: current) {
                        s.pinnedClipboardItems.remove(at: idx)
                    } else {
                        s.pinnedClipboardItems.insert(current, at: 0)
                        if s.pinnedClipboardItems.count > 8 {
                            s.pinnedClipboardItems = Array(s.pinnedClipboardItems.prefix(8))
                        }
                    }
                }
                self?.renderClipboardDrawer(currentPasteboardText: current)
            }, for: .touchUpInside)

            row.addArrangedSubview(insertBtn)
            row.addArrangedSubview(pinBtn)
            drawerStack.addArrangedSubview(row)
        }

        if currentSettings.pinnedClipboardItems.isEmpty && (currentPasteboardText?.isEmpty ?? true) {
            drawerStack.addArrangedSubview(makeEmptyLabel("Copie um texto ou fixe itens frequentes para colar com 1 toque."))
        } else {
            for item in currentSettings.pinnedClipboardItems.prefix(4) {
                let btn = makeListButton(title: "📌  \(item)") { [weak self] b in
                    self?.hideDrawers()
                    self?.onAction?(.insertSnippet(item), b, nil)
                }
                drawerStack.addArrangedSubview(btn)
            }
        }
    }

    private func renderQuickSettingsDrawer() {
        drawerOverlay.backgroundColor = UIColor(hex: currentTheme.backgroundHex).withAlphaComponent(0.97)
        clearDrawerStack()

        drawerStack.addArrangedSubview(makeDrawerHeader(title: "Ajustes rápidos • Woomboard"))

        let layoutRow = makePillRow(options: [
            ("Samsung One UI", currentSettings.layoutStyle == .samsung, { [weak self] in
                self?.onUpdateSettings? { $0.applyLayoutPreset(.samsung) }
            }),
            ("Apple iOS", currentSettings.layoutStyle == .apple, { [weak self] in
                self?.onUpdateSettings? { $0.applyLayoutPreset(.apple) }
            })
        ])
        drawerStack.addArrangedSubview(layoutRow)

        let togglesRow = makePillRow(options: [
            ("Números 1–0", currentSettings.showNumberRow, { [weak self] in
                self?.onUpdateSettings? { $0.showNumberRow.toggle() }
            }),
            ("Símbolos", currentSettings.showSecondarySymbols, { [weak self] in
                self?.onUpdateSettings? { $0.showSecondarySymbols.toggle() }
            }),
            ("Toolbar", currentSettings.showToolbar, { [weak self] in
                self?.onUpdateSettings? { $0.showToolbar.toggle() }
            })
        ])
        drawerStack.addArrangedSubview(togglesRow)

        let heightRow = makePillRow(options: KeyboardHeightPreset.allCases.map { preset in
            (preset.displayName, currentSettings.heightPreset == preset, { [weak self] in
                self?.onUpdateSettings? { $0.heightPreset = preset }
            })
        })
        drawerStack.addArrangedSubview(heightRow)

        let themeRow = makePillRow(options: [
            ("Auto", currentSettings.followSystemAppearance && (currentSettings.selectedThemeID == DefaultThemes.woomLight.id || currentSettings.selectedThemeID == DefaultThemes.woomDark.id), { [weak self] in
                self?.onUpdateSettings? {
                    $0.selectedThemeID = DefaultThemes.woomLight.id
                    $0.followSystemAppearance = true
                }
            }),
            ("Claro", !currentSettings.followSystemAppearance && currentSettings.selectedThemeID == DefaultThemes.woomLight.id, { [weak self] in
                self?.onUpdateSettings? {
                    $0.selectedThemeID = DefaultThemes.woomLight.id
                    $0.followSystemAppearance = false
                }
            }),
            ("Escuro", !currentSettings.followSystemAppearance && currentSettings.selectedThemeID == DefaultThemes.woomDark.id, { [weak self] in
                self?.onUpdateSettings? {
                    $0.selectedThemeID = DefaultThemes.woomDark.id
                    $0.followSystemAppearance = false
                }
            }),
            ("OLED", currentSettings.selectedThemeID == DefaultThemes.midnightOLED.id, { [weak self] in
                self?.onUpdateSettings? {
                    $0.selectedThemeID = DefaultThemes.midnightOLED.id
                    $0.followSystemAppearance = false
                }
            })
        ])
        drawerStack.addArrangedSubview(themeRow)
    }

    private func makeDrawerHeader(title: String) -> UIStackView {
        let header = UIStackView()
        header.axis = .horizontal
        header.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor(hex: currentTheme.textHex)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("OK", for: .normal)
        closeButton.setTitleColor(UIColor(hex: currentTheme.accentHex), for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        closeButton.addAction(UIAction { [weak self] _ in
            self?.hideDrawers()
        }, for: .touchUpInside)

        header.addArrangedSubview(titleLabel)
        header.addArrangedSubview(closeButton)
        return header
    }

    private func makeListButton(title: String, onTap: @escaping (UIButton) -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.contentHorizontalAlignment = .leading
        button.setTitle("  \(title)", for: .normal)
        button.setTitleColor(UIColor(hex: currentTheme.textHex), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.backgroundColor = UIColor(hex: currentTheme.keyBackgroundHex)
        button.layer.cornerRadius = 9
        button.layer.cornerCurve = .continuous
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addAction(UIAction { _ in onTap(button) }, for: .touchUpInside)
        return button
    }

    private func makeEmptyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13.5)
        label.numberOfLines = 2
        label.textColor = UIColor(hex: currentTheme.secondaryTextHex)
        return label
    }

    private func makePillRow(options: [(String, Bool, () -> Void)]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually

        for (title, isSelected, handler) in options {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .semibold)
            button.layer.cornerRadius = 9
            button.layer.cornerCurve = .continuous
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true

            if isSelected {
                button.backgroundColor = UIColor(hex: currentTheme.accentHex)
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = UIColor(hex: currentTheme.keyBackgroundHex)
                button.setTitleColor(UIColor(hex: currentTheme.textHex), for: .normal)
            }

            button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }

    private func clearDrawerStack() {
        drawerStack.arrangedSubviews.forEach {
            drawerStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    // MARK: - Proportional Row Layout

    private func makeSignature(rows: [[KeySpec]], settings: KeyboardSettings) -> String {
        let shape = rows.map { row in
            row.map { String(format: "%.2f", $0.widthMultiplier) }.joined(separator: ",")
        }.joined(separator: "|")
        return "\(shape)#\(settings.heightPreset.rawValue)#\(settings.oneHandedMode.rawValue)"
    }

    private func buildProportionalRow(
        specs: [KeySpec],
        theme: KeyboardTheme,
        settings: KeyboardSettings
    ) -> (UIView, [KeyButton]) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = false

        let spacing: CGFloat = 5.5
        let totalWeight = specs.reduce(CGFloat(0)) { $0 + $1.widthMultiplier }
        guard totalWeight > 0 else { return (container, []) }

        let horizontalInset: CGFloat = (specs.count == 9 && !specs[0].isSpecial) ? 14.0 : 0.0
        let totalSpacing = spacing * CGFloat(max(specs.count - 1, 0)) + (horizontalInset * 2)

        var previousButton: KeyButton?
        var createdButtons: [KeyButton] = []

        for (index, spec) in specs.enumerated() {
            let button = KeyButton(spec: spec)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.enableSpacebarTrackpad = settings.enableSpacebarTrackpad
            button.apply(theme: theme)
            bindCallbacks(to: button)
            container.addSubview(button)
            createdButtons.append(button)

            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: container.topAnchor),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            if let prev = previousButton {
                button.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: spacing).isActive = true
            } else {
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: horizontalInset).isActive = true
            }

            if index == specs.count - 1 {
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -horizontalInset).isActive = true
            }

            let ratio = spec.widthMultiplier / totalWeight
            button.widthAnchor.constraint(
                equalTo: container.widthAnchor,
                multiplier: ratio,
                constant: -totalSpacing * ratio
            ).isActive = true

            previousButton = button
        }

        return (container, createdButtons)
    }

    private func bindCallbacks(to button: KeyButton) {
        button.onTap = { [weak self] action, sender, event in
            self?.onAction?(action, sender, event)
        }

        button.onPressStart = { [weak self] keyButton in
            guard let self else { return }
            self.onPrepareHaptics?()
            guard self.currentSettings.showKeyPopup, !keyButton.spec.isSpecial, !keyButton.spec.title.isEmpty else { return }
            let frameInSelf = keyButton.convert(keyButton.bounds, to: self)
            self.popupView.showPreview(
                character: keyButton.spec.title,
                above: frameInSelf,
                in: self.bounds,
                theme: self.currentTheme
            )
        }

        button.onPressEnd = { [weak self] _ in
            self?.popupView.hide()
        }

        button.onLongPressStart = { [weak self] keyButton in
            guard let self else { return }
            let options = keyButton.spec.longPressOptions
            guard !options.isEmpty else { return }
            let frameInSelf = keyButton.convert(keyButton.bounds, to: self)
            self.popupView.showOptions(
                options,
                above: frameInSelf,
                in: self.bounds,
                theme: self.currentTheme
            )
        }

        button.onLongPressMove = { [weak self] keyButton, localPoint in
            guard let self else { return }
            let pointInSelf = keyButton.convert(localPoint, to: self)
            self.popupView.updateSelection(at: pointInSelf)
        }

        button.onLongPressEnd = { [weak self] _ in
            guard let self else { return }
            if let chosen = self.popupView.selectedOption {
                self.onSelectAccentOrSymbol?(chosen)
            }
            self.popupView.hide()
        }

        button.onBackspaceRepeat = { [weak self] deleteWord in
            self?.onBackspaceRepeat?(deleteWord)
        }

        button.onSpacebarPan = { [weak self] offset in
            self?.onSpacebarPan?(offset)
        }
    }

    // MARK: - One-Handed Mode

    private func updateOneHandedConstraints(mode: OneHandedMode) {
        let railWidth: CGFloat = 56.0
        railLeadingConstraint?.isActive = false
        railTrailingConstraint?.isActive = false

        switch mode {
        case .off:
            oneHandedRail.isHidden = true
            leadingConstraint?.constant = 0
            trailingConstraint?.constant = 0
        case .left:
            oneHandedRail.isHidden = false
            leadingConstraint?.constant = 0
            trailingConstraint?.constant = -railWidth
            railTrailingConstraint?.isActive = true
            rebuildOneHandedRail(isLeft: true)
        case .right:
            oneHandedRail.isHidden = false
            leadingConstraint?.constant = railWidth
            trailingConstraint?.constant = 0
            railLeadingConstraint?.isActive = true
            rebuildOneHandedRail(isLeft: false)
        }
    }

    private func rebuildOneHandedRail(isLeft: Bool) {
        oneHandedRail.arrangedSubviews.forEach {
            oneHandedRail.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let expandButton = UIButton(type: .system)
        expandButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        expandButton.tintColor = UIColor(hex: currentTheme.textHex)
        expandButton.accessibilityLabel = "Expandir teclado"
        expandButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onAction?(.toggleOneHanded(.off), expandButton, nil)
        }, for: .touchUpInside)

        let flipButton = UIButton(type: .system)
        flipButton.setImage(UIImage(systemName: isLeft ? "chevron.right" : "chevron.left"), for: .normal)
        flipButton.tintColor = UIColor(hex: currentTheme.textHex)
        flipButton.accessibilityLabel = isLeft ? "Mover para direita" : "Mover para esquerda"
        flipButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onAction?(.toggleOneHanded(isLeft ? .right : .left), flipButton, nil)
        }, for: .touchUpInside)

        oneHandedRail.addArrangedSubview(expandButton)
        oneHandedRail.addArrangedSubview(flipButton)
    }

    private func setupDrawerOverlay() {
        drawerOverlay.addSubview(drawerStack)
        NSLayoutConstraint.activate([
            drawerStack.topAnchor.constraint(equalTo: drawerOverlay.topAnchor, constant: 10),
            drawerStack.leadingAnchor.constraint(equalTo: drawerOverlay.leadingAnchor, constant: 10),
            drawerStack.trailingAnchor.constraint(equalTo: drawerOverlay.trailingAnchor, constant: -10)
        ])
    }

    private func setupEmojiDrawerCallbacks() {
        emojiDrawer.onSelectEmoji = { [weak self] emoji in
            guard let self else { return }
            self.onAction?(.insertEmoji(emoji), self.emojiDrawer, nil)
        }
        emojiDrawer.onClose = { [weak self] in
            self?.hideDrawers()
        }
        emojiDrawer.onBackspace = { [weak self] in
            guard let self else { return }
            self.onAction?(.backspace, self.emojiDrawer, nil)
        }
    }
}

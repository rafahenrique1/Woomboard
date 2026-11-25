import UIKit
import WoomboardCore

/// View principal que organiza as fileiras com larguras proporcionais exatas,
/// suporta modo uma mão (estilo Samsung/iOS), popup de teclas/acentos, gaveta de snippets e ajustes rápidos.
final class KeyboardView: UIView {
    var onAction: ((KeyAction, UIView, UIEvent?) -> Void)?
    var onBackspaceRepeat: ((_ deleteWord: Bool) -> Void)?
    var onSpacebarPan: ((Int) -> Void)?
    var onSelectAccentOrSymbol: ((String) -> Void)?
    var onUpdateSettings: (((inout KeyboardSettings) -> Void) -> Void)?

    private var currentTheme: KeyboardTheme = DefaultThemes.woomLight
    private var currentSettings: KeyboardSettings = KeyboardSettings()

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

    // Gaveta compartilhada (Snippets ou Ajustes Rápidos dentro do teclado)
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
        addSubview(drawerOverlay)
        addSubview(popupView)

        setupDrawerOverlay()

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

            drawerOverlay.topAnchor.constraint(equalTo: topAnchor),
            drawerOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            drawerOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            drawerOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(rows: [[KeySpec]], theme: KeyboardTheme, settings: KeyboardSettings) {
        currentTheme = theme
        currentSettings = settings
        popupView.hide()

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
            let rowContainer = buildProportionalRow(specs: row, theme: theme, settings: settings)
            rowContainer.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
            rowsStack.addArrangedSubview(rowContainer)
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

        for rowContainer in rowsStack.arrangedSubviews {
            for case let button as KeyButton in rowContainer.subviews {
                button.enableSpacebarTrackpad = settings.enableSpacebarTrackpad
                button.apply(theme: theme)
            }
        }
    }

    // MARK: - Drawers (Snippets & Quick Settings)

    func toggleSnippetsDrawer(snippets: [TextSnippet]) {
        if activeDrawerMode == .snippets {
            hideDrawers()
            return
        }
        activeDrawerMode = .snippets
        drawerOverlay.backgroundColor = UIColor(hex: currentTheme.backgroundHex).withAlphaComponent(0.96)
        clearDrawerStack()

        drawerStack.addArrangedSubview(makeDrawerHeader(title: "Atalhos rápidos"))

        if snippets.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "Adicione atalhos no app Woomboard."
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.textColor = UIColor(hex: currentTheme.secondaryTextHex)
            drawerStack.addArrangedSubview(emptyLabel)
        } else {
            for snippet in snippets.prefix(5) {
                let button = UIButton(type: .system)
                button.contentHorizontalAlignment = .leading
                button.setTitle("  \(snippet.trigger)  →  \(snippet.expansion)", for: .normal)
                button.setTitleColor(UIColor(hex: currentTheme.textHex), for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
                button.titleLabel?.lineBreakMode = .byTruncatingTail
                button.backgroundColor = UIColor(hex: currentTheme.keyBackgroundHex)
                button.layer.cornerRadius = 9
                button.heightAnchor.constraint(equalToConstant: 36).isActive = true
                let textToInsert = snippet.expansion
                button.addAction(UIAction { [weak self] _ in
                    self?.hideDrawers()
                    self?.onAction?(.insertSnippet(textToInsert), button, nil)
                }, for: .touchUpInside)
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
        activeDrawerMode = .quickSettings
        renderQuickSettingsDrawer()
        drawerOverlay.isHidden = false
        bringSubviewToFront(drawerOverlay)
    }

    func hideDrawers() {
        activeDrawerMode = .none
        drawerOverlay.isHidden = true
    }

    private func renderQuickSettingsDrawer() {
        drawerOverlay.backgroundColor = UIColor(hex: currentTheme.backgroundHex).withAlphaComponent(0.97)
        clearDrawerStack()

        drawerStack.addArrangedSubview(makeDrawerHeader(title: "Ajustes rápidos • Woomboard"))

        // Linha 1: Layout Samsung vs Apple
        let layoutRow = makePillRow(options: [
            ("Samsung One UI", currentSettings.layoutStyle == .samsung, { [weak self] in
                self?.onUpdateSettings? { $0.applyLayoutPreset(.samsung) }
            }),
            ("Apple iOS", currentSettings.layoutStyle == .apple, { [weak self] in
                self?.onUpdateSettings? { $0.applyLayoutPreset(.apple) }
            })
        ])
        drawerStack.addArrangedSubview(layoutRow)

        // Linha 2: Toggles rápidos (Linha numérica, Símbolos, Toolbar)
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

        // Linha 3: Altura (Compacto / Padrão / Confortável)
        let heightRow = makePillRow(options: KeyboardHeightPreset.allCases.map { preset in
            (preset.displayName, currentSettings.heightPreset == preset, { [weak self] in
                self?.onUpdateSettings? { $0.heightPreset = preset }
            })
        })
        drawerStack.addArrangedSubview(heightRow)

        // Linha 4: Temas rápidos
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

    private func buildProportionalRow(
        specs: [KeySpec],
        theme: KeyboardTheme,
        settings: KeyboardSettings
    ) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = false

        let spacing: CGFloat = 5.5
        let totalWeight = specs.reduce(CGFloat(0)) { $0 + $1.widthMultiplier }
        guard totalWeight > 0 else { return container }

        // Fileira intermediária com 9 letras (a..l) ganha respiro lateral sutil estilo Apple/One UI
        let horizontalInset: CGFloat = (specs.count == 9 && !specs[0].isSpecial) ? 14.0 : 0.0
        let totalSpacing = spacing * CGFloat(max(specs.count - 1, 0)) + (horizontalInset * 2)

        var previousButton: KeyButton?

        for (index, spec) in specs.enumerated() {
            let button = KeyButton(spec: spec)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.enableSpacebarTrackpad = settings.enableSpacebarTrackpad
            button.apply(theme: theme)
            bindCallbacks(to: button)
            container.addSubview(button)

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

        return container
    }

    private func bindCallbacks(to button: KeyButton) {
        button.onTap = { [weak self] action, sender, event in
            self?.onAction?(action, sender, event)
        }

        button.onPressStart = { [weak self] keyButton in
            guard let self, self.currentSettings.showKeyPopup, !keyButton.spec.isSpecial, !keyButton.spec.title.isEmpty else { return }
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
}

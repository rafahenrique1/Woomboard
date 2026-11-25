import UIKit
import WoomboardCore

/// View principal que organiza as fileiras com larguras proporcionais exatas,
/// suporta modo uma mão (estilo Samsung/iOS), popup de teclas/acentos e gaveta de snippets.
final class KeyboardView: UIView {
    var onAction: ((KeyAction, UIView, UIEvent?) -> Void)?
    var onBackspaceRepeat: ((_ deleteWord: Bool) -> Void)?
    var onSpacebarPan: ((Int) -> Void)?
    var onSelectAccentOrSymbol: ((String) -> Void)?

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
        stack.spacing = 8
        stack.distribution = .fillEqually
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

    // Gaveta rápida de Snippets (overlay leve sobre as teclas)
    private let snippetsOverlay: UIView = {
        let view = UIView()
        view.isHidden = true
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let snippetsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

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
        addSubview(snippetsOverlay)
        addSubview(popupView)

        setupSnippetsOverlay()

        let leading = contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor)
        let trailing = contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor)
        let railLeading = oneHandedRail.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        let railTrailing = oneHandedRail.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        let height = heightAnchor.constraint(equalToConstant: 216)

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

            snippetsOverlay.topAnchor.constraint(equalTo: topAnchor),
            snippetsOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            snippetsOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            snippetsOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(rows: [[KeySpec]], theme: KeyboardTheme, settings: KeyboardSettings) {
        currentTheme = theme
        currentSettings = settings
        popupView.hide()

        let rowCount = CGFloat(max(rows.count, 4))
        let rowSpacing: CGFloat = rows.count >= 5 ? 6 : 8
        rowsStack.spacing = rowSpacing
        let totalHeight = (CGFloat(settings.heightPreset.rowHeight) * rowCount) + (rowSpacing * (rowCount - 1))
        heightConstraint?.constant = totalHeight

        updateOneHandedConstraints(mode: settings.oneHandedMode)

        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for row in rows {
            let rowContainer = buildProportionalRow(specs: row, theme: theme, settings: settings)
            rowsStack.addArrangedSubview(rowContainer)
        }
    }

    func apply(theme: KeyboardTheme, settings: KeyboardSettings) {
        currentTheme = theme
        currentSettings = settings
        backgroundColor = .clear
        snippetsOverlay.backgroundColor = UIColor(hex: theme.backgroundHex)

        for rowContainer in rowsStack.arrangedSubviews {
            for case let button as KeyButton in rowContainer.subviews {
                button.enableSpacebarTrackpad = settings.enableSpacebarTrackpad
                button.apply(theme: theme)
            }
        }
    }

    func toggleSnippetsDrawer(snippets: [TextSnippet]) {
        if !snippetsOverlay.isHidden {
            snippetsOverlay.isHidden = true
            return
        }

        snippetsOverlay.backgroundColor = UIColor(hex: currentTheme.backgroundHex)
        snippetsStack.arrangedSubviews.forEach {
            snippetsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        // Cabeçalho da gaveta
        let header = UIStackView()
        header.axis = .horizontal
        header.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = "Atalhos rápidos"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = UIColor(hex: currentTheme.textHex)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Fechar", for: .normal)
        closeButton.setTitleColor(UIColor(hex: currentTheme.accentHex), for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        closeButton.addAction(UIAction { [weak self] _ in
            self?.snippetsOverlay.isHidden = true
        }, for: .touchUpInside)

        header.addArrangedSubview(titleLabel)
        header.addArrangedSubview(closeButton)
        snippetsStack.addArrangedSubview(header)

        if snippets.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "Adicione atalhos no app Woomboard."
            emptyLabel.font = .systemFont(ofSize: 14)
            emptyLabel.textColor = UIColor(hex: currentTheme.secondaryTextHex)
            snippetsStack.addArrangedSubview(emptyLabel)
        } else {
            for snippet in snippets.prefix(5) {
                let button = UIButton(type: .system)
                button.contentHorizontalAlignment = .leading
                button.setTitle("  \(snippet.trigger)  →  \(snippet.expansion)", for: .normal)
                button.setTitleColor(UIColor(hex: currentTheme.textHex), for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
                button.titleLabel?.lineBreakMode = .byTruncatingTail
                button.backgroundColor = UIColor(hex: currentTheme.keyBackgroundHex)
                button.layer.cornerRadius = 8
                button.heightAnchor.constraint(equalToConstant: 34).isActive = true
                let textToInsert = snippet.expansion
                button.addAction(UIAction { [weak self] _ in
                    self?.snippetsOverlay.isHidden = true
                    self?.onAction?(.insertSnippet(textToInsert), button, nil)
                }, for: .touchUpInside)
                snippetsStack.addArrangedSubview(button)
            }
        }

        snippetsOverlay.isHidden = false
        bringSubviewToFront(snippetsOverlay)
    }

    func hideSnippetsDrawer() {
        snippetsOverlay.isHidden = true
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

        let spacing: CGFloat = 5.0
        let totalWeight = specs.reduce(CGFloat(0)) { $0 + $1.widthMultiplier }
        guard totalWeight > 0 else { return container }

        // Fileira intermediária com 9 letras (a..l) ganha respiro lateral sutil estilo Apple
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
            guard let self, self.currentSettings.showKeyPopup, !keyButton.spec.isSpecial else { return }
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

    private func setupSnippetsOverlay() {
        snippetsOverlay.addSubview(snippetsStack)
        NSLayoutConstraint.activate([
            snippetsStack.topAnchor.constraint(equalTo: snippetsOverlay.topAnchor, constant: 8),
            snippetsStack.leadingAnchor.constraint(equalTo: snippetsOverlay.leadingAnchor, constant: 10),
            snippetsStack.trailingAnchor.constraint(equalTo: snippetsOverlay.trailingAnchor, constant: -10)
        ])
    }
}

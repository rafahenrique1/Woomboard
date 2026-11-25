import UIKit
import WoomboardCore

/// Barra superior otimizada para 120Hz (zero recriação de botões durante a digitação)
/// com suporte a sugestões + toolbar personalizável estilo Samsung One UI.
final class SuggestionBarView: UIView {
    var onSelectSuggestion: ((String) -> Void)?
    var onToolbarAction: ((KeyAction) -> Void)?

    private var currentTheme: KeyboardTheme = DefaultThemes.woomLight
    private var currentSettings: KeyboardSettings = KeyboardSettings()
    private var currentSuggestions: [String] = []

    // 3 botões de sugestão pré-alocados e reutilizados a cada tecla (zero churn na main thread)
    private let suggestionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        stack.isHidden = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private var suggestionButtons: [UIButton] = []

    // Stack separado da toolbar (reconstruído apenas quando settings/tema mudam)
    private let toolbarStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(toolbarStack)
        addSubview(suggestionsStack)

        for idx in 0..<3 {
            let button = UIButton(type: .system)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.layer.cornerRadius = 10
            button.layer.cornerCurve = .continuous
            button.isHidden = true
            button.addAction(UIAction { [weak self] _ in
                guard let self, self.currentSuggestions.indices.contains(idx) else { return }
                self.onSelectSuggestion?(self.currentSuggestions[idx])
            }, for: .touchUpInside)
            suggestionsStack.addArrangedSubview(button)
            suggestionButtons.append(button)
        }

        NSLayoutConstraint.activate([
            toolbarStack.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            toolbarStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            toolbarStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            toolbarStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            suggestionsStack.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            suggestionsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            suggestionsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            suggestionsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(theme: KeyboardTheme, settings: KeyboardSettings) {
        currentTheme = theme
        currentSettings = settings
        backgroundColor = .clear

        let textColor = UIColor(hex: theme.textHex)
        let pillBg = UIColor(hex: theme.keyBackgroundHex).withAlphaComponent(0.45)
        for button in suggestionButtons {
            button.setTitleColor(textColor, for: .normal)
            button.backgroundColor = pillBg
        }

        rebuildToolbar()
        syncVisibility()
    }

    func update(suggestions: [String]) {
        currentSuggestions = Array(suggestions.prefix(3))
        for (idx, button) in suggestionButtons.enumerated() {
            if currentSuggestions.indices.contains(idx) {
                button.setTitle(currentSuggestions[idx], for: .normal)
                button.isHidden = false
            } else {
                button.isHidden = true
            }
        }
        syncVisibility()
    }

    private func syncVisibility() {
        let showingSuggestions = !currentSuggestions.isEmpty
        suggestionsStack.isHidden = !showingSuggestions
        toolbarStack.isHidden = showingSuggestions
    }

    private func rebuildToolbar() {
        toolbarStack.arrangedSubviews.forEach {
            toolbarStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if !currentSettings.showToolbar {
            renderMinimalAppleBar()
            return
        }

        toolbarStack.distribution = .fillEqually
        let items = currentSettings.toolbarItems.isEmpty ? ToolbarItem.defaultItems : currentSettings.toolbarItems
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15.5, weight: .medium)

        for item in items.prefix(6) {
            let button = UIButton(type: .system)
            let action = mapAction(for: item)
            let isActive = (item == .oneHanded && currentSettings.oneHandedMode != .off)

            if item == .layoutSwitch {
                button.setTitle(currentSettings.layoutStyle.displayName, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            } else if item == .language {
                button.setTitle(currentSettings.language.shortCode, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            } else {
                button.setImage(UIImage(systemName: item.systemImage, withConfiguration: symbolConfig), for: .normal)
            }

            let tint = isActive
                ? UIColor(hex: currentTheme.accentHex)
                : UIColor(hex: currentTheme.textHex).withAlphaComponent(0.84)
            button.tintColor = tint
            button.setTitleColor(tint, for: .normal)
            button.accessibilityLabel = item.displayName

            button.addAction(UIAction { [weak self] _ in
                self?.onToolbarAction?(action)
            }, for: .touchUpInside)

            toolbarStack.addArrangedSubview(button)
        }
    }

    private func renderMinimalAppleBar() {
        toolbarStack.distribution = .fill
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let settingsBtn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        settingsBtn.setImage(UIImage(systemName: "gearshape", withConfiguration: config), for: .normal)
        settingsBtn.tintColor = UIColor(hex: currentTheme.secondaryTextHex)
        settingsBtn.accessibilityLabel = "Ajustes rápidos do Woomboard"
        settingsBtn.widthAnchor.constraint(equalToConstant: 40).isActive = true
        settingsBtn.addAction(UIAction { [weak self] _ in
            self?.onToolbarAction?(.openQuickSettings)
        }, for: .touchUpInside)

        toolbarStack.addArrangedSubview(spacer)
        toolbarStack.addArrangedSubview(settingsBtn)
    }

    private func mapAction(for item: ToolbarItem) -> KeyAction {
        switch item {
        case .emoji: return .openEmojiDrawer
        case .clipboard: return .openClipboardDrawer
        case .snippets: return .openSnippetsDrawer
        case .undo: return .undo
        case .oneHanded: return .toggleOneHanded(nextOneHandedMode())
        case .layoutSwitch: return .toggleLayoutStyle
        case .language: return .switchLanguage
        case .settings: return .openQuickSettings
        }
    }

    private func nextOneHandedMode() -> OneHandedMode {
        switch currentSettings.oneHandedMode {
        case .off: return .right
        case .right: return .left
        case .left: return .off
        }
    }
}

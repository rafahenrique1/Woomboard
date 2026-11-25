import UIKit
import WoomboardCore

/// Barra superior estilo Samsung One UI moderno + estética Apple iOS 26.
/// Alterna entre sugestões de texto e barra de ferramentas rápida (com botão ⚙️ de ajustes diretos no teclado).
final class SuggestionBarView: UIView {
    var onSelectSuggestion: ((String) -> Void)?
    var onToolbarAction: ((KeyAction) -> Void)?

    private var currentTheme: KeyboardTheme = DefaultThemes.woomLight
    private var currentSettings: KeyboardSettings = KeyboardSettings()
    private var currentSuggestions: [String] = []

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(theme: KeyboardTheme, settings: KeyboardSettings) {
        currentTheme = theme
        currentSettings = settings
        backgroundColor = .clear
        render()
    }

    func update(suggestions: [String]) {
        currentSuggestions = suggestions
        render()
    }

    private func render() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if !currentSuggestions.isEmpty {
            renderSuggestions()
        } else if currentSettings.showToolbar {
            renderToolbar()
        } else {
            renderMinimalAppleBar()
        }
    }

    private func renderSuggestions() {
        stackView.distribution = .fillEqually
        for suggestion in currentSuggestions.prefix(3) {
            let button = UIButton(type: .system)
            button.setTitle(suggestion, for: .normal)
            button.setTitleColor(UIColor(hex: currentTheme.textHex), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.backgroundColor = UIColor(hex: currentTheme.keyBackgroundHex).withAlphaComponent(0.45)
            button.layer.cornerRadius = 10
            button.layer.cornerCurve = .continuous
            button.addAction(UIAction { [weak self] _ in
                self?.onSelectSuggestion?(suggestion)
            }, for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }

    private func renderToolbar() {
        stackView.distribution = .fillEqually

        let items: [(title: String?, systemImage: String?, action: KeyAction, accessibility: String, isActive: Bool)] = [
            (nil, "text.badge.star", .openSnippetsDrawer, "Atalhos rápidos", false),
            (nil, "doc.on.clipboard", .pasteClipboard, "Colar", false),
            (nil, "hand.point.up.left", .toggleOneHanded(nextOneHandedMode()), "Modo uma mão", currentSettings.oneHandedMode != .off),
            (currentSettings.layoutStyle.displayName, nil, .toggleLayoutStyle, "Alternar layout Samsung ou Apple", false),
            (currentSettings.language.shortCode, nil, .switchLanguage, "Alternar idioma", false),
            (nil, "gearshape", .openQuickSettings, "Ajustes rápidos do Woomboard", false)
        ]

        for item in items {
            let button = UIButton(type: .system)
            if let imageName = item.systemImage {
                let config = UIImage.SymbolConfiguration(pointSize: 15.5, weight: .medium)
                button.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
            } else if let title = item.title {
                button.setTitle(title, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            }

            let tint = item.isActive
                ? UIColor(hex: currentTheme.accentHex)
                : UIColor(hex: currentTheme.textHex).withAlphaComponent(0.82)
            button.tintColor = tint
            button.setTitleColor(tint, for: .normal)
            button.accessibilityLabel = item.accessibility

            let action = item.action
            button.addAction(UIAction { [weak self] _ in
                self?.onToolbarAction?(action)
            }, for: .touchUpInside)

            stackView.addArrangedSubview(button)
        }
    }

    /// No layout Apple limpo (sem toolbar completa), mantém apenas um botão discreto ⚙️ no canto direito
    /// para o usuário sempre poder voltar ao Samsung ou ajustar o teclado instantaneamente.
    private func renderMinimalAppleBar() {
        stackView.distribution = .fill
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

        stackView.addArrangedSubview(spacer)
        stackView.addArrangedSubview(settingsBtn)
    }

    private func nextOneHandedMode() -> OneHandedMode {
        switch currentSettings.oneHandedMode {
        case .off: return .right
        case .right: return .left
        case .left: return .off
        }
    }
}

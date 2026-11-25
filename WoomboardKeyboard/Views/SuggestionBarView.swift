import UIKit
import WoomboardCore

/// Barra superior inteligente: alterna entre sugestões de texto (UITextChecker + Snippets)
/// e a barra de ferramentas rápida estilo Samsung (Snippets, Colar, Uma Mão, Layout, Idioma).
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

    private let bottomSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        addSubview(bottomSeparator)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            bottomSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSeparator.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(theme: KeyboardTheme, settings: KeyboardSettings) {
        currentTheme = theme
        currentSettings = settings
        backgroundColor = .clear
        bottomSeparator.backgroundColor = UIColor(hex: theme.secondaryTextHex).withAlphaComponent(0.22)
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
            button.backgroundColor = UIColor(hex: currentTheme.keyBackgroundHex).withAlphaComponent(0.35)
            button.layer.cornerRadius = 7
            button.addAction(UIAction { [weak self] _ in
                self?.onSelectSuggestion?(suggestion)
            }, for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }

    private func renderToolbar() {
        stackView.distribution = .fillEqually

        let items: [(title: String, systemImage: String?, action: KeyAction, accessibility: String)] = [
            ("", "text.badge.star", .openSnippetsDrawer, "Atalhos rápidos"),
            ("", "doc.on.clipboard", .pasteClipboard, "Colar"),
            ("", "hand.point.up.left", .toggleOneHanded(nextOneHandedMode()), "Modo uma mão"),
            (currentSettings.layoutStyle.displayName, nil, .toggleLayoutStyle, "Alternar layout Samsung ou Apple"),
            (currentSettings.language.shortCode, nil, .switchLanguage, "Alternar idioma")
        ]

        for item in items {
            let button = UIButton(type: .system)
            if let imageName = item.systemImage {
                let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
                button.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
            } else {
                button.setTitle(item.title, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 12.5, weight: .semibold)
            }

            let isActiveOneHanded = item.systemImage == "hand.point.up.left" && currentSettings.oneHandedMode != .off
            button.tintColor = isActiveOneHanded
                ? UIColor(hex: currentTheme.accentHex)
                : UIColor(hex: currentTheme.textHex).withAlphaComponent(0.85)
            button.setTitleColor(button.tintColor, for: .normal)
            button.accessibilityLabel = item.accessibility

            let action = item.action
            button.addAction(UIAction { [weak self] _ in
                self?.onToolbarAction?(action)
            }, for: .touchUpInside)

            stackView.addArrangedSubview(button)
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

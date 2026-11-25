import UIKit
import WoomboardCore

/// Popup estilo Apple exibido acima da tecla ao tocar (ampliação) ou ao segurar (seletor de acentos/símbolos).
final class KeyPopupView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var optionLabels: [UILabel] = []
    private var options: [String] = []
    private var selectedIndex: Int = 0
    private var currentTheme: KeyboardTheme = DefaultThemes.woomLight

    var selectedOption: String? {
        guard options.indices.contains(selectedIndex) else { return nil }
        return options[selectedIndex]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isHidden = true
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 6

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Exibe a ampliação rápida de uma única tecla (estilo iOS).
    func showPreview(character: String, above sourceFrame: CGRect, in containerBounds: CGRect, theme: KeyboardTheme) {
        showOptions([character], above: sourceFrame, in: containerBounds, theme: theme, highlightSelection: false)
    }

    /// Exibe o seletor horizontal de acentos ou símbolos secundários (long-press).
    func showOptions(
        _ items: [String],
        above sourceFrame: CGRect,
        in containerBounds: CGRect,
        theme: KeyboardTheme,
        highlightSelection: Bool = true
    ) {
        guard !items.isEmpty else {
            hide()
            return
        }

        currentTheme = theme
        options = items
        selectedIndex = 0

        backgroundColor = UIColor(hex: theme.keyBackgroundHex)

        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        optionLabels.removeAll()

        for item in items {
            let label = UILabel()
            label.text = item
            label.textAlignment = .center
            label.font = .systemFont(ofSize: items.count == 1 ? 28 : 22, weight: .regular)
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            stackView.addArrangedSubview(label)
            optionLabels.append(label)
        }

        let itemWidth: CGFloat = items.count == 1 ? max(sourceFrame.width + 14, 44) : 36
        let popupWidth = CGFloat(items.count) * itemWidth + 8
        let popupHeight: CGFloat = 50

        var originX = sourceFrame.midX - (popupWidth / 2)
        originX = max(4, min(originX, containerBounds.width - popupWidth - 4))
        let originY = max(2, sourceFrame.minY - popupHeight - 6)

        frame = CGRect(x: originX, y: originY, width: popupWidth, height: popupHeight)
        updateHighlight(enabled: highlightSelection)
        isHidden = false
        superview?.bringSubviewToFront(self)
    }

    /// Atualiza a opção destacada enquanto o usuário desliza o dedo no popup.
    func updateSelection(at pointInContainer: CGPoint) {
        guard options.count > 1, !isHidden else { return }
        let localX = pointInContainer.x - frame.minX - 4
        let usableWidth = max(frame.width - 8, 1)
        let ratio = max(0, min(0.999, localX / usableWidth))
        let newIndex = Int(ratio * CGFloat(options.count))
        if newIndex != selectedIndex {
            selectedIndex = newIndex
            updateHighlight(enabled: true)
        }
    }

    func hide() {
        isHidden = true
        options.removeAll()
        optionLabels.removeAll()
    }

    private func updateHighlight(enabled: Bool) {
        for (index, label) in optionLabels.enumerated() {
            if enabled && index == selectedIndex {
                label.backgroundColor = UIColor(hex: currentTheme.accentHex)
                label.textColor = .white
            } else {
                label.backgroundColor = .clear
                label.textColor = UIColor(hex: currentTheme.textHex)
            }
        }
    }
}

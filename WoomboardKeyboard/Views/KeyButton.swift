import UIKit
import WoomboardCore

/// Botão individual de tecla com visual Apple e interações ergonômicas estilo Samsung
/// (sub-símbolo no canto superior, toque longo para acentos/símbolos, backspace contínuo e trackpad na barra de espaço).
final class KeyButton: UIControl {
    let spec: KeySpec

    var onTap: ((KeyAction, UIView, UIEvent?) -> Void)?
    var onPressStart: ((KeyButton) -> Void)?
    var onPressEnd: ((KeyButton) -> Void)?
    var onLongPressStart: ((KeyButton) -> Void)?
    var onLongPressMove: ((KeyButton, CGPoint) -> Void)?
    var onLongPressEnd: ((KeyButton) -> Void)?
    var onBackspaceRepeat: ((_ deleteWord: Bool) -> Void)?
    var onSpacebarPan: ((Int) -> Void)?

    var enableSpacebarTrackpad: Bool = true

    private var currentTheme: KeyboardTheme = DefaultThemes.woomLight
    private var longPressTimer: Timer?
    private var backspaceTimer: Timer?
    private var backspaceRepeatCount: Int = 0
    private var isLongPressActive: Bool = false
    private var isTrackpadActive: Bool = false
    private var trackpadLastX: CGFloat = 0

    private let primaryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let secondaryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 9.5, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(spec: KeySpec) {
        self.spec = spec
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityTraits = .keyboardKey
        accessibilityLabel = spec.accessibilityLabel

        primaryLabel.text = spec.title
        if spec.action == .space {
            primaryLabel.font = .systemFont(ofSize: 14, weight: .regular)
        } else if spec.isSpecial {
            primaryLabel.font = .systemFont(ofSize: 15, weight: .medium)
        } else {
            primaryLabel.font = .systemFont(ofSize: 22, weight: .regular)
        }

        secondaryLabel.text = spec.secondaryTitle
        secondaryLabel.isHidden = (spec.secondaryTitle == nil)

        addSubview(primaryLabel)
        addSubview(secondaryLabel)

        NSLayoutConstraint.activate([
            primaryLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: spec.secondaryTitle == nil ? 0 : 2),
            primaryLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 3),
            primaryLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -3),

            secondaryLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2.5),
            secondaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        invalidateTimers()
    }

    func apply(theme: KeyboardTheme) {
        currentTheme = theme
        updateVisualState(pressed: isHighlighted)
    }

    private func updateVisualState(pressed: Bool) {
        let baseColor: UIColor
        if spec.isAccent {
            baseColor = UIColor(hex: currentTheme.accentHex)
        } else if spec.isHighlighted {
            baseColor = UIColor(hex: currentTheme.keyBackgroundHex)
        } else if spec.isSpecial {
            baseColor = UIColor(hex: currentTheme.specialKeyBackgroundHex)
        } else {
            baseColor = UIColor(hex: currentTheme.keyBackgroundHex)
        }

        backgroundColor = pressed ? baseColor.withAlphaComponent(0.75) : baseColor

        if spec.isAccent {
            primaryLabel.textColor = .white
        } else {
            primaryLabel.textColor = UIColor(hex: currentTheme.textHex)
        }
        secondaryLabel.textColor = UIColor(hex: currentTheme.secondaryTextHex)

        layer.cornerRadius = CGFloat(currentTheme.keyCornerRadius)
        if currentTheme.showKeyShadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.28
            layer.shadowOffset = CGSize(width: 0, height: 1)
            layer.shadowRadius = 0.4
        } else {
            layer.shadowOpacity = 0
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        isHighlighted = true
        isLongPressActive = false
        isTrackpadActive = false
        updateVisualState(pressed: true)

        if let touch = touches.first {
            trackpadLastX = touch.location(in: window ?? self).x
        }

        // Tecla Globo precisa do evento nativo imediatamente para abrir o menu do iOS
        if spec.action == .nextKeyboard {
            onTap?(spec.action, self, event)
            return
        }

        onPressStart?(self)

        if spec.action == .backspace {
            startBackspaceRepeatTimer()
        } else if !spec.longPressOptions.isEmpty {
            startLongPressTimer()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }

        if isLongPressActive {
            onLongPressMove?(self, touch.location(in: self))
            return
        }

        // Modo Trackpad na barra de espaço (deslizar horizontalmente move o cursor)
        if spec.action == .space && enableSpacebarTrackpad {
            let currentX = touch.location(in: window ?? self).x
            let delta = currentX - trackpadLastX
            let step: CGFloat = 13.0
            if abs(delta) >= step {
                isTrackpadActive = true
                let offset = delta > 0 ? 1 : -1
                trackpadLastX = currentX
                onSpacebarPan?(offset)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let wasLongPress = isLongPressActive
        let wasTrackpad = isTrackpadActive
        let didRepeatBackspace = backspaceRepeatCount > 0

        invalidateTimers()
        isHighlighted = false
        isLongPressActive = false
        isTrackpadActive = false
        backspaceRepeatCount = 0
        updateVisualState(pressed: false)

        if spec.action == .nextKeyboard {
            return
        }

        if wasLongPress {
            onLongPressEnd?(self)
        } else {
            onPressEnd?(self)
            if !wasTrackpad && !didRepeatBackspace {
                onTap?(spec.action, self, event)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        invalidateTimers()
        isHighlighted = false
        isLongPressActive = false
        isTrackpadActive = false
        backspaceRepeatCount = 0
        updateVisualState(pressed: false)
        onPressEnd?(self)
    }

    // MARK: - Timers

    private func startLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.34, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isLongPressActive = true
            self.onLongPressStart?(self)
        }
    }

    private func startBackspaceRepeatTimer() {
        backspaceTimer?.invalidate()
        backspaceRepeatCount = 0
        // Dispara o primeiro delete imediatamente ao segurar após 0.35s e acelera para apagar palavra inteira
        backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.backspaceRepeatCount += 1
                let deleteWord = self.backspaceRepeatCount >= 12
                self.onBackspaceRepeat?(deleteWord)
            }
        }
    }

    private func invalidateTimers() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        backspaceTimer?.invalidate()
        backspaceTimer = nil
    }
}

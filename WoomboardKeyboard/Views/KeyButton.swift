import UIKit
import WoomboardCore

/// Botão individual de tecla otimizado para 120Hz ProMotion:
/// - Reutilização in-place via `update(spec:theme:)` (zero recriação de views ao alternar Shift/CapsLock)
/// - `shadowPath` em cache no `layoutSubviews()` para renderização de sombra em GPU sem offscreen pass
/// - SF Symbols nativos da Apple + ergonomia Samsung One UI moderno
final class KeyButton: UIControl {
    private(set) var spec: KeySpec

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
    private var lastShadowBounds: CGRect = .zero
    private var longPressTimer: Timer?
    private var backspaceTimer: Timer?
    private var backspaceRepeatCount: Int = 0
    private var isLongPressActive: Bool = false
    private var isTrackpadActive: Bool = false
    private var trackpadLastX: CGFloat = 0

    private var primaryCenterYConstraint: NSLayoutConstraint?

    private let primaryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let secondaryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 9.0, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(spec: KeySpec) {
        self.spec = spec
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityTraits = .keyboardKey
        layer.cornerCurve = .continuous

        addSubview(primaryLabel)
        addSubview(iconView)
        addSubview(secondaryLabel)

        let centerY = primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        primaryCenterYConstraint = centerY

        NSLayoutConstraint.activate([
            primaryLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerY,
            primaryLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 3),
            primaryLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -3),

            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(lessThanOrEqualToConstant: 22),
            iconView.heightAnchor.constraint(lessThanOrEqualToConstant: 22),

            secondaryLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            secondaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])

        applySpecContent(spec)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        invalidateTimers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Atualiza o shadowPath apenas quando o tamanho muda — elimina rasterização offscreen a 120Hz
        if currentTheme.showKeyShadow && bounds != lastShadowBounds && !bounds.isEmpty {
            lastShadowBounds = bounds
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: CGFloat(currentTheme.keyCornerRadius)
            ).cgPath
        }
    }

    /// Atualiza a tecla no lugar (sem recriar UIView nem refazer Auto Layout) em < 0.1ms.
    func update(spec newSpec: KeySpec, theme: KeyboardTheme) {
        let specChanged = (spec != newSpec)
        let themeChanged = (currentTheme != theme)
        spec = newSpec
        currentTheme = theme

        if specChanged {
            applySpecContent(newSpec)
        }
        if specChanged || themeChanged {
            updateVisualState(pressed: isHighlighted)
        }
    }

    func apply(theme: KeyboardTheme) {
        currentTheme = theme
        lastShadowBounds = .zero
        updateVisualState(pressed: isHighlighted)
        setNeedsLayout()
    }

    private func applySpecContent(_ spec: KeySpec) {
        accessibilityLabel = spec.accessibilityLabel

        if let symbolName = spec.systemImage {
            let weight: UIImage.SymbolWeight = spec.isAccent ? .semibold : .medium
            let config = UIImage.SymbolConfiguration(pointSize: 17, weight: weight)
            iconView.image = UIImage(systemName: symbolName, withConfiguration: config)
            iconView.isHidden = false
            primaryLabel.isHidden = true
        } else {
            iconView.isHidden = true
            primaryLabel.isHidden = false
            primaryLabel.text = spec.title
            if spec.action == .space {
                primaryLabel.font = .systemFont(ofSize: 13.5, weight: .regular)
            } else if spec.isNumberRow {
                primaryLabel.font = .systemFont(ofSize: 18.5, weight: .regular)
            } else if spec.isSpecial {
                primaryLabel.font = .systemFont(ofSize: 14.5, weight: .medium)
            } else {
                primaryLabel.font = .systemFont(ofSize: 22, weight: .regular)
            }
        }

        secondaryLabel.text = spec.secondaryTitle
        secondaryLabel.isHidden = (spec.secondaryTitle == nil)
        primaryCenterYConstraint?.constant = (spec.secondaryTitle == nil) ? 0 : 2.5
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

        backgroundColor = pressed ? baseColor.withAlphaComponent(0.72) : baseColor

        let foreground: UIColor
        if spec.isAccent {
            foreground = .white
        } else if spec.action == .space {
            foreground = UIColor(hex: currentTheme.secondaryTextHex)
        } else {
            foreground = UIColor(hex: currentTheme.textHex)
        }

        primaryLabel.textColor = foreground
        iconView.tintColor = foreground
        secondaryLabel.textColor = UIColor(hex: currentTheme.secondaryTextHex).withAlphaComponent(0.65)

        layer.cornerRadius = CGFloat(currentTheme.keyCornerRadius)

        if currentTheme.showKeyShadow {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.22
            layer.shadowOffset = CGSize(width: 0, height: 1)
            layer.shadowRadius = 0.4
            if !bounds.isEmpty {
                layer.shadowPath = UIBezierPath(
                    roundedRect: bounds,
                    cornerRadius: CGFloat(currentTheme.keyCornerRadius)
                ).cgPath
            }
        } else {
            layer.shadowOpacity = 0
            layer.shadowPath = nil
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
        backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
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

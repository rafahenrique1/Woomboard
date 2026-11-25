import UIKit
import WoomboardCore

/// Seletor de Emojis embutido com rolagem suave a 120Hz (UICollectionView),
/// categorias estilo Apple/One UI, recentes persistidos e barra inferior com ABC + Backspace.
final class EmojiDrawerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var onSelectEmoji: ((String) -> Void)?
    var onClose: (() -> Void)?
    var onBackspace: (() -> Void)?

    private struct EmojiCategory {
        let icon: String
        let emojis: [String]
    }

    private static let baseCategories: [EmojiCategory] = [
        EmojiCategory(icon: "face.smiling", emojis: [
            "😀","😃","😄","😁","😆","😅","🤣","😂","🙂","😉","😊","😇","🥰","😍","🤩","😘",
            "😋","😛","😜","🤪","😝","🤑","🤗","🤭","🤫","🤔","🤐","🤨","😐","😑","😶","😏",
            "😒","🙄","😬","😌","😔","😪","😴","😷","🤒","🤕","🤢","🤮","🥵","🥶","🥴","😵",
            "🤯","🤠","🥳","😎","🤓","🧐","😕","😟","🙁","😮","😯","😲","😳","🥺","😦","😧",
            "😨","😰","😥","😢","😭","😱","😖","😣","😞","😓","😩","😫","🥱","😤","😡","😠"
        ]),
        EmojiCategory(icon: "hand.thumbsup", emojis: [
            "👍","👎","👏","🙌","👐","🤲","🤝","🙏","✌️","🤞","🤟","🤘","👌","🤌","🤏","👈",
            "👉","👆","👇","☝️","✋","🤚","🖐️","🖖","👋","🤙","💪","🦾","✍️","🤳","💅","👀"
        ]),
        EmojiCategory(icon: "heart.fill", emojis: [
            "❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❤️‍🔥","💕","💞","💓","💗","💖",
            "💘","💝","✨","🌟","💫","🔥","💥","💯","🎉","🎊","🎈","🎁","🏆","🥇","⚡","🌈"
        ]),
        EmojiCategory(icon: "cup.and.saucer.fill", emojis: [
            "☕","🍕","🍔","🍟","🌭","🍿","🍫","🍰","🎂","🍺","🍻","🥂","🍷","⚽","🏀","🎮",
            "🎧","🎵","🎶","📱","💻","⌚","📷","🚗","✈️","🚀","🏠","💡","📌","✅","❌","⚠️"
        ])
    ]

    private var categories: [EmojiCategory] = []
    private var selectedCategoryIndex: Int = 0
    private var currentTheme: KeyboardTheme = DefaultThemes.woomLight

    private let collectionView: UICollectionView
    private let categoryBar: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false

        super.init(frame: frame)
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous

        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self

        addSubview(collectionView)
        addSubview(categoryBar)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: categoryBar.topAnchor, constant: -4),

            categoryBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            categoryBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            categoryBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            categoryBar.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(recentEmojis: [String], theme: KeyboardTheme) {
        currentTheme = theme
        backgroundColor = UIColor(hex: theme.backgroundHex).withAlphaComponent(0.97)

        var list: [EmojiCategory] = []
        if !recentEmojis.isEmpty {
            list.append(EmojiCategory(icon: "clock", emojis: recentEmojis))
        }
        list.append(contentsOf: Self.baseCategories)
        categories = list

        if selectedCategoryIndex >= categories.count {
            selectedCategoryIndex = 0
        }

        rebuildCategoryBar()
        collectionView.reloadData()
    }

    private func rebuildCategoryBar() {
        categoryBar.arrangedSubviews.forEach {
            categoryBar.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        // Botão ABC para voltar às letras
        let abcButton = UIButton(type: .system)
        abcButton.setTitle("ABC", for: .normal)
        abcButton.titleLabel?.font = .systemFont(ofSize: 13.5, weight: .semibold)
        abcButton.setTitleColor(UIColor(hex: currentTheme.textHex), for: .normal)
        abcButton.backgroundColor = UIColor(hex: currentTheme.specialKeyBackgroundHex)
        abcButton.layer.cornerRadius = 8
        abcButton.addAction(UIAction { [weak self] _ in
            self?.onClose?()
        }, for: .touchUpInside)
        categoryBar.addArrangedSubview(abcButton)

        // Ícones das categorias
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        for (index, category) in categories.enumerated() {
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: category.icon, withConfiguration: config), for: .normal)
            btn.tintColor = (index == selectedCategoryIndex)
                ? UIColor(hex: currentTheme.accentHex)
                : UIColor(hex: currentTheme.secondaryTextHex)
            btn.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.selectedCategoryIndex = index
                self.rebuildCategoryBar()
                self.collectionView.setContentOffset(.zero, animated: false)
                self.collectionView.reloadData()
            }, for: .touchUpInside)
            categoryBar.addArrangedSubview(btn)
        }

        // Botão Backspace
        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "delete.left", withConfiguration: config), for: .normal)
        deleteButton.tintColor = UIColor(hex: currentTheme.textHex)
        deleteButton.backgroundColor = UIColor(hex: currentTheme.specialKeyBackgroundHex)
        deleteButton.layer.cornerRadius = 8
        deleteButton.addAction(UIAction { [weak self] _ in
            self?.onBackspace?()
        }, for: .touchUpInside)
        categoryBar.addArrangedSubview(deleteButton)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard categories.indices.contains(selectedCategoryIndex) else { return 0 }
        return categories[selectedCategoryIndex].emojis.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCell.reuseID, for: indexPath) as? EmojiCell else {
            return UICollectionViewCell()
        }
        let emoji = categories[selectedCategoryIndex].emojis[indexPath.item]
        cell.setEmoji(emoji)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard categories.indices.contains(selectedCategoryIndex) else { return }
        let emoji = categories[selectedCategoryIndex].emojis[indexPath.item]
        onSelectEmoji?(emoji)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let columns: CGFloat = 8
        let totalSpacing = 12 + (columns - 1) * 4
        let width = floor((collectionView.bounds.width - totalSpacing) / columns)
        return CGSize(width: max(width, 32), height: 38)
    }
}

private final class EmojiCell: UICollectionViewCell {
    static let reuseID = "EmojiCell"

    private let label: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 28)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEmoji(_ emoji: String) {
        label.text = emoji
    }
}

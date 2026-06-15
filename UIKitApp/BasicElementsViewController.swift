import UIKit

/// SwiftUI 版 `BasicElementsView` と同じ UI・同じ accessibilityIdentifier 命名規約
/// （`<screen>.<element>`）で実装した UIKit 版の基準値画面。
/// `List` のミラーとして inset grouped な `UITableView` を用いる。
/// SwiftUI 版との差分（特に Toggle / UISwitch の要素フレーム）を実測比較するための対象。
final class BasicElementsViewController: UITableViewController {
    private enum Row {
        case staticText
        case button
        case toggle
        case textField
        case secureField
        case listItem(Int)
        case scroll
        case modalButton
        case alertButton
    }

    private struct Section {
        let title: String
        let rows: [Row]
    }

    private let listItems = ["りんご", "みかん", "ぶどう"]

    private lazy var sections: [Section] = [
        Section(title: "テキスト", rows: [.staticText]),
        Section(title: "ボタン", rows: [.button, .toggle]),
        Section(title: "入力", rows: [.textField, .secureField]),
        Section(title: "リスト", rows: [.listItem(0), .listItem(1), .listItem(2)]),
        Section(title: "ScrollView内の要素", rows: [.scroll]),
        Section(title: "モーダル / アラート", rows: [.modalButton, .alertButton]),
    ]

    private var tapCount = 0
    private weak var primaryButton: UIButton?

    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "基本要素"
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Table data

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section].rows[indexPath.row] {
        case .scroll: return 92
        default: return 52
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none

        switch sections[indexPath.section].rows[indexPath.row] {
        case .staticText:
            let label = makeLabel("これは静的なテキストです。", identifier: "basics.staticText")
            pin(label, in: cell)

        case .button:
            let button = UIButton(type: .system)
            button.setTitle("タップ回数: \(tapCount)", for: .normal)
            button.contentHorizontalAlignment = .leading
            button.accessibilityIdentifier = "basics.primaryButton"
            button.addAction(UIAction { [weak self] _ in self?.incrementTap() }, for: .touchUpInside)
            primaryButton = button
            pin(button, in: cell)

        case .toggle:
            let label = makeLabel("トグル", identifier: nil)
            let toggle = UISwitch()
            toggle.accessibilityIdentifier = "basics.toggle"
            label.translatesAutoresizingMaskIntoConstraints = false
            toggle.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(label)
            cell.contentView.addSubview(toggle)
            let margins = cell.contentView.layoutMarginsGuide
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                toggle.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                toggle.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            ])

        case .textField:
            let field = makeTextField(placeholder: "テキストを入力", identifier: "basics.textField")
            pin(field, in: cell)

        case .secureField:
            let field = makeTextField(placeholder: "パスワードを入力", identifier: "basics.secureField")
            field.isSecureTextEntry = true
            pin(field, in: cell)

        case .listItem(let index):
            let label = makeLabel(listItems[index], identifier: "basics.listItem.\(index)")
            pin(label, in: cell)

        case .scroll:
            let scrollView = makeHorizontalScrollView()
            pin(scrollView, in: cell)

        case .modalButton:
            let button = makeActionButton("モーダルを開く", identifier: "basics.showModalButton") { [weak self] in
                self?.presentModal()
            }
            pin(button, in: cell)

        case .alertButton:
            let button = makeActionButton("アラートを表示", identifier: "basics.showAlertButton") { [weak self] in
                self?.presentAlert()
            }
            pin(button, in: cell)
        }

        return cell
    }

    // MARK: - Actions

    private func incrementTap() {
        tapCount += 1
        primaryButton?.setTitle("タップ回数: \(tapCount)", for: .normal)
    }

    private func presentModal() {
        let modal = UINavigationController(rootViewController: ModalViewController())
        present(modal, animated: true)
    }

    private func presentAlert() {
        let alert = UIAlertController(
            title: "アラート",
            message: "これは標準のアラートです。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - View factories

    private func makeLabel(_ text: String, identifier: String?) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.accessibilityIdentifier = identifier
        return label
    }

    private func makeTextField(placeholder: String, identifier: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.accessibilityIdentifier = identifier
        field.borderStyle = .none
        return field
    }

    private func makeActionButton(_ title: String, identifier: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.accessibilityIdentifier = identifier
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func makeHorizontalScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        for index in 0..<10 {
            let chip = UILabel()
            chip.text = "\(index)"
            chip.textAlignment = .center
            chip.font = .preferredFont(forTextStyle: .headline)
            chip.backgroundColor = UIColor.tintColor.withAlphaComponent(0.15)
            chip.layer.cornerRadius = 8
            chip.clipsToBounds = true
            chip.accessibilityIdentifier = "basics.scrollItem.\(index)"
            chip.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                chip.widthAnchor.constraint(equalToConstant: 56),
                chip.heightAnchor.constraint(equalToConstant: 56),
            ])
            stack.addArrangedSubview(chip)
        }

        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])
        return scrollView
    }

    /// 単一のサブビューをセルの contentView のレイアウトマージンにフィットさせる。
    private func pin(_ view: UIView, in cell: UITableViewCell) {
        view.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(view)
        let margins = cell.contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            view.topAnchor.constraint(equalTo: margins.topAnchor),
            view.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
        ])
    }
}

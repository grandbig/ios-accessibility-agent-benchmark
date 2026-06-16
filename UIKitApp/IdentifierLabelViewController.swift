import UIKit

/// SwiftUI 版 `IdentifierLabelView` に対応する UIKit 版の identifier/label 検証画面。
/// 同じ6パターン・同じ accessibilityIdentifier・同じヘッダー文言で実装し、
/// 「親View に identifier を付けたとき子に伝播するか」を SwiftUI と対比する。
/// 命名規約: `idlabel.caseN.*`
final class IdentifierLabelViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ID/Label"
        view.backgroundColor = .systemBackground

        let content = UIStackView(arrangedSubviews: [
            case1(), case2(), case3(), case4(), case5(), case6(),
        ])
        content.axis = .vertical
        content.spacing = 28
        content.alignment = .leading
        content.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        view.addSubview(scrollView)

        let margins = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: margins.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    // ① 子Buttonのみに identifier（親は無印）
    private func case1() -> UIView {
        let button = borderedButton(title: "子ボタン1")
        button.accessibilityIdentifier = "idlabel.case1.child"
        return headeredCase("① 子Buttonのみにidentifier", parentRow(parentId: nil, button: button))
    }

    // ② 親View のみに identifier（子Buttonは無印）
    private func case2() -> UIView {
        let button = borderedButton(title: "子ボタン2")
        return headeredCase("② 親Viewのみにidentifier", parentRow(parentId: "idlabel.case2.parent", button: button))
    }

    // ③ 親View + 子Button の両方に identifier
    private func case3() -> UIView {
        let button = borderedButton(title: "子ボタン3")
        button.accessibilityIdentifier = "idlabel.case3.child"
        return headeredCase("③ 親View+子Button両方にidentifier", parentRow(parentId: "idlabel.case3.parent", button: button))
    }

    // ④ label のみ（identifier なし）
    private func case4() -> UIView {
        let button = borderedButton(title: "子ボタン4")
        return headeredCase("④ labelのみ（identifierなし）", button)
    }

    // ⑤ identifier のみ（ラベルになるテキストなし＝図形ボタン）
    private func case5() -> UIView {
        let button = UIButton(type: .system)
        button.backgroundColor = .tintColor
        button.layer.cornerRadius = 18
        button.accessibilityIdentifier = "idlabel.case5.noLabelButton"
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 36),
            button.heightAnchor.constraint(equalToConstant: 36),
        ])
        return headeredCase("⑤ identifierのみ（ラベルなし・図形）", button)
    }

    // ⑥ label + identifier の両方
    private func case6() -> UIView {
        let button = borderedButton(title: "子ボタン6")
        button.accessibilityIdentifier = "idlabel.case6.button"
        return headeredCase("⑥ label + identifier両方", button)
    }

    // MARK: - Builders

    private func borderedButton(title: String) -> UIButton {
        var config = UIButton.Configuration.bordered()
        config.title = title
        return UIButton(configuration: config)
    }

    /// 「親」ラベル + 子Button の水平 stack。stack（親View）に identifier を付けられる。
    private func parentRow(parentId: String?, button: UIButton) -> UIStackView {
        let oya = UILabel()
        oya.text = "親"
        let row = UIStackView(arrangedSubviews: [oya, button])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.accessibilityIdentifier = parentId
        return row
    }

    private func headeredCase(_ title: String, _ content: UIView) -> UIView {
        let header = UILabel()
        header.text = title
        header.font = .preferredFont(forTextStyle: .headline)
        header.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [header, content])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }
}

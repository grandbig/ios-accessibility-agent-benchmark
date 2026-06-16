import UIKit

/// SwiftUI 版 `GroupingView` に対応する UIKit 版の grouping 検証画面。
/// SwiftUI の `accessibilityElement(children:)` に対応する UIKit API で同じカードをまとめ、
/// VoiceOver 向けのまとまりと自動操作からの個別検出性のトレードオフを対比する。
///
/// 対応関係:
/// - `.combine` 相当 → `isAccessibilityElement = true` ＋ 連結した `accessibilityLabel`
/// - `.contain` 相当 → `accessibilityContainerType = .semanticGroup`（子は個別のまま）
/// - `.ignore`  相当 → `isAccessibilityElement = true` ＋ 独自の `accessibilityLabel`
final class GroupingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Grouping"
        view.backgroundColor = .systemBackground

        // ① grouping なし（default）：子は個別に公開される
        let a = card("A")

        // ② isAccessibilityElement=true（.combine 相当）：1要素にまとめ、ラベルを連結
        let b = card("B")
        b.isAccessibilityElement = true
        b.accessibilityLabel = "タイトルB, サブタイトルB"

        // ③ accessibilityContainerType=.semanticGroup（.contain 相当）：子は個別のままグループ化
        let c = card("C")
        c.accessibilityContainerType = .semanticGroup

        // ④ isAccessibilityElement=true + 独自ラベル（.ignore 相当）
        let d = card("D")
        d.isAccessibilityElement = true
        d.accessibilityLabel = "グループDのまとめ"

        let content = UIStackView(arrangedSubviews: [
            section("① groupingなし（default）", a),
            section("② isAccessibilityElement=true（combine相当）", b),
            section("③ .semanticGroup（contain相当）", c),
            section("④ isAccessibilityElement=true + 独自ラベル（ignore相当）", d),
        ])
        content.axis = .vertical
        content.spacing = 28
        content.alignment = .fill
        content.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        view.addSubview(scrollView)

        let guide = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: guide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    /// カード本体（タイトル・サブタイトル・操作ボタン）。
    private func card(_ tag: String) -> UIView {
        let title = UILabel()
        title.text = "タイトル\(tag)"
        title.font = .preferredFont(forTextStyle: .headline)

        let subtitle = UILabel()
        subtitle.text = "サブタイトル\(tag)"
        subtitle.font = .preferredFont(forTextStyle: .caption1)
        subtitle.textColor = .secondaryLabel

        var config = UIButton.Configuration.bordered()
        config.title = "操作\(tag)"
        let button = UIButton(configuration: config)
        button.accessibilityIdentifier = "group.\(tag).button"

        let stack = UIStackView(arrangedSubviews: [title, subtitle, button])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 12
        return stack
    }

    private func section(_ title: String, _ content: UIView) -> UIView {
        let header = UILabel()
        header.text = title
        header.font = .preferredFont(forTextStyle: .headline)
        header.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [header, content])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        return stack
    }
}

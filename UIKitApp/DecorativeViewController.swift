import UIKit

/// SwiftUI 版 `DecorativeView` に対応する UIKit 版の装飾UI検証画面。
/// カスタム描画（`draw(_:)`）/ Gesture のみ / Blur（UIVisualEffectView）/ Glass で、
/// 装飾・カスタム描画が自動操作からどう見えるかを SwiftUI と対比する。
/// 命名規約: `deco.*`
final class DecorativeViewController: UIViewController {
    private let lastTappedLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Decorative"
        view.backgroundColor = .systemBackground

        lastTappedLabel.text = "最後にタップ: なし"
        lastTappedLabel.font = .preferredFont(forTextStyle: .footnote)
        lastTappedLabel.accessibilityIdentifier = "deco.lastTapped"

        let content = UIStackView(arrangedSubviews: [
            lastTappedLabel,
            section("① カスタム描画（アクセシビリティなし）", customNoA11y()),
            section("② カスタム描画 + accessibility", customFixed()),
            section("③ Gestureのみ（アクセシビリティなし）", gestureNoA11y()),
            section("④ Gesture + accessibility", gestureFixed()),
            section("⑤ Blur の上の Button", blurButton()),
            section("⑥ Glass の上の Button", glassButton()),
        ])
        content.axis = .vertical
        content.spacing = 28
        content.alignment = .leading
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

    // ① カスタム描画（draw(_:) で描いたボタン風UI）+ Gesture、アクセシビリティ指定なし
    private func customNoA11y() -> UIView {
        let v = sized(DrawnButtonView())
        v.accessibilityIdentifier = "deco.custom"
        addTap(v) { [weak self] in self?.setTapped("custom") }
        return v
    }

    // ② ①に accessibility（label + .button トレイト）を補った版
    private func customFixed() -> UIView {
        let v = sized(DrawnButtonView())
        v.isAccessibilityElement = true
        v.accessibilityLabel = "送信"
        v.accessibilityTraits = .button
        v.accessibilityIdentifier = "deco.customFixed"
        addTap(v) { [weak self] in self?.setTapped("customFixed") }
        return v
    }

    // ③ Gesture のみで操作する図形（アクセシビリティ指定なし）
    private func gestureNoA11y() -> UIView {
        let v = sized(filledView())
        v.accessibilityIdentifier = "deco.gesture"
        addTap(v) { [weak self] in self?.setTapped("gesture") }
        return v
    }

    // ④ ③に accessibility を補った版
    private func gestureFixed() -> UIView {
        let v = sized(filledView())
        v.isAccessibilityElement = true
        v.accessibilityLabel = "実行"
        v.accessibilityTraits = .button
        v.accessibilityIdentifier = "deco.gestureFixed"
        addTap(v) { [weak self] in self?.setTapped("gestureFixed") }
        return v
    }

    // ⑤ Blur（UIVisualEffectView）の上の通常の UIButton
    private func blurButton() -> UIView {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        return effectContainer(effectView: blur, identifier: "deco.blurButton", tap: "blur", title: "ブラーの上")
    }

    // ⑥ Glass（iOS 26 の UIGlassEffect）の上の通常の UIButton（古いOSは Blur フォールバック）
    private func glassButton() -> UIView {
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            effect = UIGlassEffect()
        } else {
            effect = UIBlurEffect(style: .systemMaterial)
        }
        let effectView = UIVisualEffectView(effect: effect)
        return effectContainer(effectView: effectView, identifier: "deco.glassButton", tap: "glass", title: "グラスの上")
    }

    // MARK: - Builders

    /// 装飾（Blur/Glass）の上に通常の UIButton を載せたコンテナ。
    private func effectContainer(effectView: UIVisualEffectView, identifier: String, tap: String, title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemIndigo
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.translatesAutoresizingMaskIntoConstraints = false

        effectView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(effectView)

        var config = UIButton.Configuration.borderedProminent()
        config.title = title
        let button = UIButton(configuration: config)
        button.accessibilityIdentifier = identifier
        button.addAction(UIAction { [weak self] _ in self?.setTapped(tap) }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)

        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 260),
            container.heightAnchor.constraint(equalToConstant: 100),
            effectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: container.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func sized(_ v: UIView) -> UIView {
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: 120),
            v.heightAnchor.constraint(equalToConstant: 44),
        ])
        return v
    }

    private func filledView() -> UIView {
        let v = UIView()
        v.backgroundColor = .systemGreen
        v.layer.cornerRadius = 8
        return v
    }

    private func addTap(_ view: UIView, _ action: @escaping () -> Void) {
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(TapClosureRecognizer(handler: action))
    }

    private func setTapped(_ name: String) {
        lastTappedLabel.text = "最後にタップ: \(name)"
    }

    private func section(_ title: String, _ content: UIView) -> UIView {
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

/// `draw(_:)` でボタン風の見た目（角丸 + テキスト）を描くカスタムビュー。
/// テキストも描画なので、デフォルトではアクセシビリティ要素にならない。
private final class DrawnButtonView: UIView {
    private let title = "送信"

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        UIColor.systemBlue.setFill()
        path.fill()

        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 16),
        ]
        let text = title as NSString
        let size = text.size(withAttributes: attrs)
        text.draw(
            at: CGPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2),
            withAttributes: attrs
        )
    }
}

/// クロージャで扱える UITapGestureRecognizer。
private final class TapClosureRecognizer: UITapGestureRecognizer {
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(fire))
    }

    @objc private func fire() {
        handler()
    }
}

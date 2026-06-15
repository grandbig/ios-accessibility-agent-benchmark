import UIKit

/// UIKit 版の基本要素画面は今後 SwiftUI 版と同じUIを再現する形で実装する。
/// 現状はプロジェクト構成を確立するためのビルド可能なプレースホルダ。
final class PlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "UIKit App（実装予定）"
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "uikit.placeholder.label"
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

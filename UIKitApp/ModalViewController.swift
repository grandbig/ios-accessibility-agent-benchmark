import UIKit

/// SwiftUI 版のモーダル（sheet）に対応する UIKit 版モーダル。
final class ModalViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "モーダル"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "閉じる",
            style: .done,
            target: self,
            action: #selector(close)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "modal.closeButton"

        let titleLabel = UILabel()
        titleLabel.text = "モーダル"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.accessibilityIdentifier = "modal.title"

        let bodyLabel = UILabel()
        bodyLabel.text = "これは標準のモーダルです。"
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .center
        bodyLabel.accessibilityIdentifier = "modal.body"

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
        ])
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

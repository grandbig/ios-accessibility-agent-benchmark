import UIKit

/// SwiftUI 版 `AboutView` に対応する UIKit 版。
final class AboutViewController: UITableViewController {
    private struct Item {
        let text: String
        let identifier: String
        let isHeadline: Bool
    }

    private let items = [
        Item(text: "iOS Accessibility × Agent Benchmark", identifier: "about.title", isHeadline: true),
        Item(text: "基本要素の基準値画面（UIKit）", identifier: "about.subtitle", isHeadline: false),
    ]

    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none

        let label = UILabel()
        label.text = item.text
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: item.isHeadline ? .headline : .subheadline)
        label.textColor = item.isHeadline ? .label : .secondaryLabel
        label.accessibilityIdentifier = item.identifier
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(label)
        let margins = cell.contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            label.topAnchor.constraint(equalTo: margins.topAnchor),
            label.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
        ])
        return cell
    }
}

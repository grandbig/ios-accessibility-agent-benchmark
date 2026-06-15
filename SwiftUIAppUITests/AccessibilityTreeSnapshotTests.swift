import XCTest

/// アクセシビリティツリーのスナップショット採取用。
///
/// `app.debugDescription` で、各画面状態のアクセシビリティ要素階層
/// （要素タイプ / identifier / label / value / frame）をまるごと標準出力へ出す。
/// iOS の UI テストはシミュレータ側サンドボックスで動くためリポジトリへ直接書けない。
/// そのため出力をマーカーで囲み、`scripts/dump-accessibility-trees.sh` が
/// `docs/trees/*.txt` に取り出す。Accessibility Inspector（GUI）と違い、
/// OSS なし・1 コマンドで再現・差分管理できる「機械から見たツリー」の証跡。
///
/// 通常の基準値スイート（BasicElementsUITests）とは分離し、明示的に
/// `-only-testing` で指定したときだけ実行する。
final class AccessibilityTreeSnapshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testDumpAccessibilityTrees() {
        dumpTree(name: "basics-top")

        // 画面下部（モーダル/アラートのボタン、横スクロール要素）まで送ってから採取。
        app.swipeUp()
        app.swipeUp()
        dumpTree(name: "basics-bottom")

        // モーダル表示状態
        let modalButton = app.buttons["basics.showModalButton"]
        scrollToHittable(modalButton)
        modalButton.tap()
        XCTAssertTrue(app.staticTexts["modal.title"].waitForExistence(timeout: 3))
        dumpTree(name: "modal")
        app.buttons["modal.closeButton"].tap()

        // アラート表示状態
        let alertButton = app.buttons["basics.showAlertButton"]
        scrollToHittable(alertButton)
        alertButton.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        dumpTree(name: "alert")
        app.alerts.buttons["OK"].firstMatch.tap()

        // About タブ
        app.tabBars.buttons["About"].tap()
        XCTAssertTrue(app.staticTexts["about.title"].waitForExistence(timeout: 2))
        dumpTree(name: "about")
    }

    // MARK: - Helpers

    private func dumpTree(name: String) {
        print("===TREE-START:\(name)===")
        print(app.debugDescription)
        print("===TREE-END:\(name)===")
    }

    @discardableResult
    private func scrollToHittable(_ element: XCUIElement, maxSwipes: Int = 10) -> Bool {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        return element.isHittable
    }
}

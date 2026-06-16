import XCTest

/// UIKit 版アクセシビリティツリーの採取。SwiftUI 版
/// （AccessibilityTreeSnapshotTests）と同じ画面状態・同じマーカー名で
/// `app.debugDescription` を標準出力へ出す。`scripts/dump-accessibility-trees.sh`
/// が `docs/trees/uikit-*.txt` として取り出し、SwiftUI 版と差分比較できるようにする。
final class UIKitAccessibilityTreeSnapshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testDumpAccessibilityTrees() {
        dumpTree(name: "basics-top")

        app.swipeUp()
        app.swipeUp()
        dumpTree(name: "basics-bottom")

        let modalButton = app.buttons["basics.showModalButton"]
        scrollToHittable(modalButton)
        modalButton.tap()
        XCTAssertTrue(app.staticTexts["modal.title"].waitForExistence(timeout: 3))
        dumpTree(name: "modal")
        app.buttons["modal.closeButton"].tap()

        let alertButton = app.buttons["basics.showAlertButton"]
        scrollToHittable(alertButton)
        alertButton.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        dumpTree(name: "alert")
        app.alerts.buttons["OK"].firstMatch.tap()

        app.tabBars.buttons["ID/Label"].tap()
        XCTAssertTrue(app.staticTexts["① 子Buttonのみにidentifier"].waitForExistence(timeout: 2))
        dumpTree(name: "idlabel")

        app.tabBars.buttons["Grouping"].tap()
        XCTAssertTrue(app.staticTexts["① groupingなし（default）"].waitForExistence(timeout: 2))
        dumpTree(name: "grouping")

        app.tabBars.buttons["Decorative"].tap()
        XCTAssertTrue(app.staticTexts["① カスタム描画（アクセシビリティなし）"].waitForExistence(timeout: 2))
        dumpTree(name: "decorative")

        app.tabBars.buttons["About"].tap()
        XCTAssertTrue(app.staticTexts["about.title"].waitForExistence(timeout: 2))
        dumpTree(name: "about")
    }

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

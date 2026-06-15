import XCTest

/// UIKit 版 基準値（ものさし）テスト。SwiftUIAppUITests/BasicElementsUITests と
/// 同じ画面・同じ identifier に対する検出/操作を測定し、SwiftUI 版との差分を見る。
///
/// 注目点: Toggle/UISwitch の操作。SwiftUI 版は `.tap()`（要素中央）では切り替わらず
/// 座標オフセットが必要だったが、UIKit の `UISwitch` は独立した小さな要素フレームを
/// 持つため、ここでは **`.tap()`（中央タップ）で切り替わる** ことを検証する。
final class UIKitBasicElementsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
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

    func testTabsAreDetectableAndSwitchable() {
        let basicsTab = app.tabBars.buttons["基本要素"]
        let aboutTab = app.tabBars.buttons["About"]
        XCTAssertTrue(basicsTab.waitForExistence(timeout: 5), "基本要素タブが検出できない")
        XCTAssertTrue(aboutTab.exists, "Aboutタブが検出できない")

        aboutTab.tap()
        XCTAssertTrue(app.staticTexts["about.title"].waitForExistence(timeout: 2), "About画面に遷移できない")

        basicsTab.tap()
        XCTAssertTrue(app.navigationBars["基本要素"].waitForExistence(timeout: 2), "基本要素画面に戻れない")
    }

    func testStaticTextIsDetectable() {
        XCTAssertTrue(app.staticTexts["basics.staticText"].waitForExistence(timeout: 5), "静的テキストが検出できない")
    }

    func testButtonIsDetectableAndTappable() {
        let button = app.buttons["basics.primaryButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "ボタンが検出できない")
        button.tap()
        XCTAssertTrue(button.label.contains("1"), "タップ後にラベルが更新されない: \(button.label)")
    }

    func testToggleIsDetectableAndSwitchable() {
        let toggle = app.switches["basics.toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "トグルが検出できない")

        let before = toggle.value as? String
        // UIKit の UISwitch は要素フレームがスイッチ本体だけなので、中央 .tap() で切り替わる。
        toggle.tap()
        let after = toggle.value as? String
        XCTAssertNotEqual(before, after, "UISwitch が中央タップで切り替わらない")
    }

    func testTextFieldIsDetectableAndEditable() {
        let textField = app.textFields["basics.textField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "テキストフィールドが検出できない")
        textField.tap()
        textField.typeText("hello")
        XCTAssertEqual(textField.value as? String, "hello", "入力した文字列が反映されない")
    }

    func testSecureFieldIsDetectableAndEditable() {
        let secureField = app.secureTextFields["basics.secureField"]
        XCTAssertTrue(secureField.waitForExistence(timeout: 5), "セキュアフィールドが検出できない")
        secureField.tap()
        secureField.typeText("secret")
        let value = secureField.value as? String ?? ""
        XCTAssertFalse(value.isEmpty, "セキュアフィールドへの入力が反映されない")
    }

    func testListItemsAreDetectable() {
        let firstItem = app.staticTexts["basics.listItem.0"]
        XCTAssertTrue(scrollToHittable(firstItem), "リスト項目0が検出できない")
        for index in 1..<3 {
            let item = app.staticTexts["basics.listItem.\(index)"]
            XCTAssertTrue(scrollToHittable(item), "リスト項目\(index)が検出できない")
        }
    }

    func testScrollViewItemsAreDetectable() {
        let firstItem = app.staticTexts["basics.scrollItem.0"]
        XCTAssertTrue(scrollToHittable(firstItem), "横スクロール内の先頭要素が検出できない")
        XCTAssertTrue(app.staticTexts["basics.scrollItem.9"].exists, "横スクロール内の末尾要素が検出できない")
    }

    func testModalCanBePresentedAndDismissed() {
        let openButton = app.buttons["basics.showModalButton"]
        XCTAssertTrue(scrollToHittable(openButton), "モーダルを開くボタンが検出できない")
        openButton.tap()
        XCTAssertTrue(app.staticTexts["modal.title"].waitForExistence(timeout: 3), "モーダルが表示されない")

        let closeButton = app.buttons["modal.closeButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2), "モーダルの閉じるボタンが検出できない")
        closeButton.tap()
        XCTAssertFalse(app.staticTexts["modal.title"].waitForExistence(timeout: 1), "モーダルが閉じられない")
    }

    func testAlertCanBePresentedAndDismissed() {
        let openButton = app.buttons["basics.showAlertButton"]
        XCTAssertTrue(scrollToHittable(openButton), "アラートを表示するボタンが検出できない")
        openButton.tap()

        let okButton = app.alerts.buttons["OK"].firstMatch
        XCTAssertTrue(okButton.waitForExistence(timeout: 3), "アラートが表示されない")
        okButton.tap()
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 1), "アラートが閉じられない")
    }
}

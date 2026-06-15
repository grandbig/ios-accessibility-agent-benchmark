import XCTest

/// 基準値（ものさし）テスト。
///
/// 「普通に作った」基本要素画面の各 UI 要素が、Apple 純正の UI 自動操作
/// （XCUITest）で **検出できるか（exists）** と **操作できるか（tap/type）**
/// を機械的に確認する。ここでの結果が、以降の identifier/label・grouping・
/// 装飾UI などの検証における比較の基準になる。
final class BasicElementsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Helpers

    /// 縦スクロール（List）内の遅延読み込み要素を、操作可能になるまでスクロールして表示する。
    @discardableResult
    private func scrollToHittable(_ element: XCUIElement, maxSwipes: Int = 10) -> Bool {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        return element.isHittable
    }

    // MARK: - Tab

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

    // MARK: - Text

    func testStaticTextIsDetectable() {
        XCTAssertTrue(app.staticTexts["basics.staticText"].waitForExistence(timeout: 5), "静的テキストが検出できない")
    }

    // MARK: - Button

    func testButtonIsDetectableAndTappable() {
        let button = app.buttons["basics.primaryButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "ボタンが検出できない")

        button.tap()
        XCTAssertTrue(button.label.contains("1"), "タップ後にラベルが更新されない（操作が反映されていない）: \(button.label)")
    }

    // MARK: - Toggle

    func testToggleIsDetectableAndSwitchable() {
        let toggle = app.switches["basics.toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "トグルが検出できない")

        let before = toggle.value as? String
        // 知見: List 内の Toggle は switch 要素のフレームが行(セル)全体と一致するため、
        // .tap()（要素中央タップ）だと行中央の余白を叩いてしまい切り替わらない。
        // スイッチ本体は右端にあるので、座標オフセットで明示的にタップする。
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let after = toggle.value as? String
        XCTAssertNotEqual(before, after, "トグルの状態が切り替わらない")
    }

    // MARK: - TextField

    func testTextFieldIsDetectableAndEditable() {
        let textField = app.textFields["basics.textField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5), "テキストフィールドが検出できない")

        textField.tap()
        textField.typeText("hello")
        XCTAssertEqual(textField.value as? String, "hello", "入力した文字列が反映されない")
    }

    // MARK: - SecureField

    func testSecureFieldIsDetectableAndEditable() {
        let secureField = app.secureTextFields["basics.secureField"]
        XCTAssertTrue(secureField.waitForExistence(timeout: 5), "セキュアフィールドが検出できない")

        secureField.tap()
        secureField.typeText("secret")
        // セキュアフィールドの値はマスクされるため、入力後に空でないことのみ確認する。
        let value = secureField.value as? String ?? ""
        XCTAssertFalse(value.isEmpty, "セキュアフィールドへの入力が反映されない")
    }

    // MARK: - List item

    func testListItemsAreDetectable() {
        // List は遅延読み込みのため、先頭項目までスクロールしてから検出を確認する。
        let firstItem = app.staticTexts["basics.listItem.0"]
        XCTAssertTrue(scrollToHittable(firstItem), "リスト項目0が検出できない")

        for index in 1..<3 {
            let item = app.staticTexts["basics.listItem.\(index)"]
            XCTAssertTrue(scrollToHittable(item), "リスト項目\(index)が検出できない")
        }
    }

    // MARK: - ScrollView 内の要素

    func testScrollViewItemsAreDetectable() {
        let firstItem = app.staticTexts["basics.scrollItem.0"]
        XCTAssertTrue(scrollToHittable(firstItem), "横スクロール内の先頭要素が検出できない")

        // 横 ScrollView 内の要素は非遅延の HStack なので、画面外の要素も
        // アクセシビリティツリー上に存在するはずである（検出のみ確認）。
        XCTAssertTrue(app.staticTexts["basics.scrollItem.9"].exists, "横スクロール内の末尾要素が検出できない")
    }

    // MARK: - Modal (sheet)

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

    // MARK: - Alert

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

import XCTest

/// 実アプリ寄せの「設定」画面で、Slider / Stepper / Picker / NavigationLink / 複数 Toggle が
/// 自動操作からどう見える・操作できるかを固定化する。基本要素の合成画面で見つけた知見
/// （Toggle 中央タップ問題など）が現実的な文脈でも再現することを確認する。詳細は docs/settings.md。
final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["About"].tap()
        app.buttons["about.settingsLink"].tap()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5))
    }

    @discardableResult
    private func scrollToHittable(_ element: XCUIElement, maxSwipes: Int = 8) -> Bool {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        return element.isHittable
    }

    /// Toggle は switch として検出される。中央タップでは切り替わらず（基本要素と同じ）、右端なら切り替わる。
    func testToggle_centerTapMisses_rightEdgeWorks() {
        let push = app.switches["settings.push"]
        XCTAssertTrue(push.waitForExistence(timeout: 3))

        let before = push.value as? String
        push.tap() // 中央
        XCTAssertEqual(push.value as? String, before, "List内Toggleは中央タップで切り替わらない")

        push.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertNotEqual(push.value as? String, before, "右端タップなら切り替わる")
    }

    /// Slider は slider として検出され、adjust で操作できる。
    func testSlider_isAdjustable() {
        let slider = app.sliders["settings.fontSize"]
        XCTAssertTrue(slider.waitForExistence(timeout: 3))
        let before = slider.value as? String
        slider.adjust(toNormalizedSliderPosition: 0.9)
        XCTAssertNotEqual(slider.value as? String, before, "Slider は adjust で値が変わる")
    }

    /// Stepper の identifier は `-Increment` / `-Decrement` の2ボタンに分割される。
    /// 素の identifier を狙う自動化は当たらず、増減ボタンの suffix 付き id で操作する必要がある。
    func testStepper_identifierIsSplitIntoIncrementDecrement() {
        XCTAssertFalse(app.buttons["settings.lineSpacing"].exists, "素のidはボタンにならない")
        let increment = app.buttons["settings.lineSpacing-Increment"]
        XCTAssertTrue(scrollToHittable(increment), "increment ボタンは suffix 付き id で検出できる")
        XCTAssertTrue(increment.label.contains("2"), "操作前は行間2")
        increment.tap()
        XCTAssertTrue(increment.label.contains("3"), "increment で行間3に増える")
    }

    /// Picker（メニュー）は button として検出され、ラベルに現在値を含む。
    func testPicker_detectedAsButtonWithValue() {
        let theme = app.buttons["settings.theme"]
        XCTAssertTrue(theme.waitForExistence(timeout: 3))
        XCTAssertTrue(theme.label.contains("テーマ"), "ラベルにテーマを含む: \(theme.label)")
        XCTAssertTrue(theme.label.contains("システム"), "ラベルに現在値を含む: \(theme.label)")
    }

    /// NavigationLink は button として検出され、タップで詳細に遷移する。
    func testNavigationLink_pushesDetail() {
        let account = app.buttons["settings.account"]
        XCTAssertTrue(scrollToHittable(account))
        account.tap()
        XCTAssertTrue(app.staticTexts["settings.accountDetail"].waitForExistence(timeout: 3))
    }

    /// 破壊的ボタンは検出・操作できる。
    func testDestructiveButton_operates() {
        let clear = app.buttons["settings.clearCache"]
        XCTAssertTrue(scrollToHittable(clear))
        clear.tap()
        XCTAssertTrue(app.staticTexts["settings.lastAction"].label.contains("clearCache"))
    }
}

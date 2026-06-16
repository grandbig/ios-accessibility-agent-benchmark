import XCTest

/// UIKit 装飾UI / カスタム描画が自動操作からどう見えるかの検証。SwiftUI 版（DecorativeUITests）との対比。
/// 詳細な考察は docs/decorative.md。
final class UIKitDecorativeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Decorative"].tap()
        XCTAssertTrue(app.staticTexts["① カスタム描画（アクセシビリティなし）"].waitForExistence(timeout: 5))
    }

    /// ① カスタム描画（accessibility なし）：見た目はボタンだが button とは認識されない。
    func testCustomNoA11y_notRecognizedAsButton() {
        XCTAssertFalse(app.buttons["deco.custom"].exists, "カスタム描画はボタンとして認識されないはず")
        XCTAssertTrue(app.otherElements["deco.custom"].exists, "汎用の Other 要素にはなる")
    }

    /// ② カスタム描画 + accessibility（label + .button トレイト）：ボタンとして検出・操作できる。
    func testCustomFixed_becomesOperableButton() {
        let button = app.buttons["deco.customFixed"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "送信")
        button.tap()
        XCTAssertTrue(app.staticTexts["deco.lastTapped"].label.contains("customFixed"))
    }

    /// ③ Gesture のみ（accessibility なし）：button として認識されない。
    func testGestureNoA11y_notRecognizedAsButton() {
        XCTAssertFalse(app.buttons["deco.gesture"].exists)
        XCTAssertTrue(app.otherElements["deco.gesture"].exists)
    }

    /// ④ Gesture + accessibility：button として検出・操作できる。
    func testGestureFixed_becomesOperableButton() {
        let button = app.buttons["deco.gestureFixed"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "実行")
        button.tap()
        XCTAssertTrue(app.staticTexts["deco.lastTapped"].label.contains("gestureFixed"))
    }

    /// ⑤ Blur（UIVisualEffectView）の上の Button：装飾は検出に影響しない。
    func testBlurButton_detectedNormally() {
        XCTAssertTrue(app.buttons["deco.blurButton"].exists)
    }

    /// ⑥ Glass（UIGlassEffect）の上の Button：装飾は検出に影響しない。
    func testGlassButton_detectedNormally() {
        XCTAssertTrue(app.buttons["deco.glassButton"].exists)
    }
}

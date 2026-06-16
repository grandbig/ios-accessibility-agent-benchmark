import XCTest

/// 装飾UI / カスタム描画が自動操作からどう見えるかを固定化する検証テスト。
/// 「人間には見えるが機械にはボタンと認識されない UI」と、accessibility 補完で
/// 操作可能になることを示す。詳細な考察は docs/decorative.md。
final class DecorativeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Decorative"].tap()
        XCTAssertTrue(app.staticTexts["① Canvas描画（アクセシビリティなし）"].waitForExistence(timeout: 5))
    }

    /// ① Canvas 描画（accessibility なし）：見た目はボタンだが、ボタンとは認識されない。
    /// identifier を付けても汎用の Other 要素止まりで、操作対象（button）にはならない。
    func testCanvasNoA11y_notRecognizedAsButton() {
        XCTAssertFalse(app.buttons["deco.canvas"].exists, "Canvas描画はボタンとして認識されないはず")
        XCTAssertTrue(app.otherElements["deco.canvas"].exists, "汎用の Other 要素にはなる")
    }

    /// ② Canvas 描画 + accessibility（label + .isButton）：ボタンとして検出・操作できる。
    func testCanvasFixed_becomesOperableButton() {
        let button = app.buttons["deco.canvasFixed"]
        XCTAssertTrue(button.exists, "accessibility補完でボタンになるはず")
        XCTAssertEqual(button.label, "送信")
        button.tap()
        XCTAssertTrue(
            app.staticTexts["deco.lastTapped"].label.contains("canvasFixed"),
            "ボタンとしてタップ操作できるはず"
        )
    }

    /// ③ Gesture のみ（accessibility なし）：ボタンとして認識されない。
    func testGestureNoA11y_notRecognizedAsButton() {
        XCTAssertFalse(app.buttons["deco.gesture"].exists)
        XCTAssertTrue(app.otherElements["deco.gesture"].exists)
    }

    /// ④ Gesture + accessibility：ボタンとして検出・操作できる。
    func testGestureFixed_becomesOperableButton() {
        let button = app.buttons["deco.gestureFixed"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "実行")
        button.tap()
        XCTAssertTrue(app.staticTexts["deco.lastTapped"].label.contains("gestureFixed"))
    }

    /// ⑤ Blur の上の Button：装飾（ブラー）は検出に影響しない。
    func testBlurButton_detectedNormally() {
        XCTAssertTrue(app.buttons["deco.blurButton"].exists, "Blur は検出に影響しないはず")
    }

    /// ⑥ Glass の上の Button：装飾（グラス）は検出に影響しない。
    func testGlassButton_detectedNormally() {
        XCTAssertTrue(app.buttons["deco.glassButton"].exists, "Glass は検出に影響しないはず")
    }
}

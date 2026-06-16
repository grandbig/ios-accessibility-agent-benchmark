import XCTest

/// UIKit grouping（isAccessibilityElement / accessibilityContainerType）の検証。
/// SwiftUI 版（GroupingUITests）との対比が主眼。詳細な考察は docs/grouping.md。
final class UIKitGroupingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Grouping"].tap()
        XCTAssertTrue(app.staticTexts["① groupingなし（default）"].waitForExistence(timeout: 5))
    }

    /// ① default：子が個別要素として公開される。
    func testDefault_childrenIndividuallyExposed() {
        XCTAssertTrue(app.staticTexts["タイトルA"].exists)
        let button = app.buttons["group.A.button"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "操作A")
        XCTAssertEqual(app.buttons.matching(identifier: "group.A.button").count, 1)
    }

    /// ② isAccessibilityElement=true + 連結ラベル（.combine 相当）。
    /// コンテナが1要素になり、子の StaticText は吸収されて消える。
    /// SwiftUI の .combine と違い、コンテナは Button ではなく、操作ボタンの id は重複しない。
    func testCombineEquivalent_collapsesAndAbsorbsLabels() {
        XCTAssertTrue(
            app.otherElements["タイトルB, サブタイトルB"].exists,
            "コンテナが連結ラベルの1要素になるはず"
        )
        XCTAssertFalse(
            app.staticTexts["タイトルB"].exists,
            "子の StaticText はコンテナのラベルに吸収され、個別要素としては消えるはず"
        )
        XCTAssertEqual(
            app.buttons.matching(identifier: "group.B.button").count, 1,
            "SwiftUIの.combineと異なり、操作ボタンのidは重複しないはず"
        )
    }

    /// ③ accessibilityContainerType=.semanticGroup（.contain 相当）：子は個別に保持。
    func testSemanticGroup_keepsChildrenAddressable() {
        XCTAssertTrue(app.staticTexts["タイトルC"].exists)
        let button = app.buttons["group.C.button"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "操作C")
        XCTAssertEqual(app.buttons.matching(identifier: "group.C.button").count, 1)
    }

    /// ④ isAccessibilityElement=true + 独自ラベル（.ignore 相当）。
    /// コンテナの独自ラベルが1要素として公開され、子の StaticText は消える。
    func testIgnoreEquivalent_exposesContainerLabel() {
        XCTAssertTrue(app.otherElements["グループDのまとめ"].exists)
        XCTAssertFalse(app.staticTexts["タイトルD"].exists, "子の StaticText は消えるはず")
        // ボタンは VoiceOver からは無視されるが、XCUITest のツリーには残る（観測事実）
        XCTAssertTrue(app.buttons["group.D.button"].exists)
    }
}

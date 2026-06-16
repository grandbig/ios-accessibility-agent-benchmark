import XCTest

/// grouping（`accessibilityElement(children:)`）が、XCUITest から見た要素構造に
/// どう影響するかを固定化する検証テスト。VoiceOver 向けのまとまりと自動操作の
/// 検出性のトレードオフを示す。詳細な考察は docs/grouping.md。
final class GroupingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Grouping"].tap()
        XCTAssertTrue(app.staticTexts["① groupingなし（default）"].waitForExistence(timeout: 5))
    }

    /// ① default：子（タイトル/サブタイトル/操作ボタン）が個別の要素として公開される。
    func testDefault_childrenIndividuallyExposed() {
        XCTAssertTrue(app.staticTexts["タイトルA"].exists)
        XCTAssertTrue(app.staticTexts["サブタイトルA"].exists)
        let button = app.buttons["group.A.button"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "操作A")
        XCTAssertEqual(app.buttons.matching(identifier: "group.A.button").count, 1)
    }

    /// ② .combine：カード全体が1つの要素にまとまり、ラベルが連結される。
    /// 結果、操作ボタンの identifier がカード全体の要素にも複製され、重複マッチが起きる。
    func testCombine_collapsesIntoOneElement() {
        // カード全体が「タイトルB, サブタイトルB」というラベルの1要素になる
        XCTAssertTrue(
            app.buttons["タイトルB, サブタイトルB"].exists,
            ".combine でカード全体が連結ラベルの1要素になるはず"
        )
        // 操作ボタンの id がカード全体の要素にも乗り、複数マッチになる（Multiple matches の温床）
        XCTAssertGreaterThanOrEqual(
            app.buttons.matching(identifier: "group.B.button").count, 2,
            ".combine で操作ボタンの id が重複するはず"
        )
    }

    /// ③ .contain：コンテナ化しても子は個別にアクセスできる（操作ボタンは単独・自分のラベル）。
    func testContain_keepsChildrenAddressable() {
        XCTAssertTrue(app.staticTexts["タイトルC"].exists)
        let button = app.buttons["group.C.button"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "操作C")
        XCTAssertEqual(
            app.buttons.matching(identifier: "group.C.button").count, 1,
            ".contain では操作ボタンは単独で一意に検出できるはず"
        )
    }

    /// ④ .ignore：コンテナの独自ラベルが要素として公開される。
    /// （VoiceOver は子を無視し 'グループDのまとめ' のみ読む。ただし子は XCUITest ツリーには残る）
    func testIgnore_exposesContainerLabel() {
        XCTAssertTrue(
            app.otherElements["グループDのまとめ"].exists,
            ".ignore でコンテナの独自ラベルが公開されるはず"
        )
        // 子ボタンは VoiceOver からは無視されるが、XCUITest のツリーには残る（観測事実）
        XCTAssertTrue(app.buttons["group.D.button"].exists)
    }
}

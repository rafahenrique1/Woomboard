import XCTest
@testable import WoomboardCore

final class WoomboardCoreTests: XCTestCase {
    func testDefaultThemeLookupFallsBackToLight() {
        let fallback = DefaultThemes.theme(for: "tema-inexistente")
        XCTAssertEqual(fallback.id, DefaultThemes.woomLight.id)
        XCTAssertEqual(fallback.name, "Apple Light")
    }

    func testSuggestionEngineExpandsSnippet() {
        let engine = SuggestionEngine(snippets: ["@@": "contato@woomboard.app"])
        let suggestions = engine.suggestions(forContextBeforeInput: "Meu email é @@")
        XCTAssertEqual(suggestions, ["contato@woomboard.app"])
    }

    func testSuggestionEnginePrefixMatchingAndEmptyAfterSpace() {
        let engine = SuggestionEngine(snippets: [
            TextSnippet(trigger: "chegando", expansion: "Estou a caminho!")
        ])
        XCTAssertEqual(engine.suggestions(forContextBeforeInput: "cheg"), ["Estou a caminho!"])
        XCTAssertEqual(engine.suggestions(forContextBeforeInput: "chegando "), [])
    }

    func testSettingsCodableResilienceWithLegacyPayload() throws {
        let legacyJSON = """
        {
            "selectedThemeID": "woom-dark",
            "enableHaptics": false,
            "enableKeySounds": true,
            "showNumberRow": false,
            "autoCapitalization": true,
            "doubleSpacePeriod": false
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(KeyboardSettings.self, from: legacyJSON)
        XCTAssertEqual(decoded.selectedThemeID, "woom-dark")
        XCTAssertFalse(decoded.enableHaptics)
        XCTAssertTrue(decoded.enableKeySounds)
        XCTAssertFalse(decoded.showNumberRow)
        XCTAssertFalse(decoded.doubleSpacePeriod)
        XCTAssertEqual(decoded.layoutStyle, .samsung)
        XCTAssertEqual(decoded.language, .ptBR)
    }

    func testLanguageToggleCyclesBetweenPTBRAndENUS() {
        XCTAssertEqual(KeyboardLanguage.ptBR.next, .enUS)
        XCTAssertEqual(KeyboardLanguage.enUS.next, .ptBR)
    }
}

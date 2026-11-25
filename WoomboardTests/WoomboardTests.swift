import XCTest
@testable import WoomboardCore

final class WoomboardTests: XCTestCase {
    func testDefaultSettingsUseSamsungErgonomicsAndAppleLightTheme() {
        let settings = KeyboardSettings()
        XCTAssertEqual(settings.selectedThemeID, DefaultThemes.woomLight.id)
        XCTAssertEqual(settings.layoutStyle, .samsung)
        XCTAssertEqual(settings.language, .ptBR)
        XCTAssertTrue(settings.showNumberRow)
        XCTAssertTrue(settings.showSecondarySymbols)
        XCTAssertTrue(settings.showToolbar)
        XCTAssertTrue(settings.enableSpacebarTrackpad)
        XCTAssertTrue(settings.enableHaptics)
        XCTAssertTrue(settings.autoCapitalization)
    }

    func testApplyingAppleAndSamsungLayoutPresets() {
        var settings = KeyboardSettings()
        settings.applyLayoutPreset(.apple)
        XCTAssertEqual(settings.layoutStyle, .apple)
        XCTAssertFalse(settings.showNumberRow)
        XCTAssertFalse(settings.showSecondarySymbols)
        XCTAssertFalse(settings.showToolbar)

        settings.applyLayoutPreset(.samsung)
        XCTAssertEqual(settings.layoutStyle, .samsung)
        XCTAssertTrue(settings.showNumberRow)
        XCTAssertTrue(settings.showSecondarySymbols)
        XCTAssertTrue(settings.showToolbar)
    }

    func testSuggestionEngineExpandsSnippetsAndMergesSystemCompletions() {
        let engine = SuggestionEngine(snippets: [
            TextSnippet(trigger: "@@", expansion: "contato@woomboard.app")
        ])

        XCTAssertEqual(
            engine.suggestions(forContextBeforeInput: "Meu email é @@"),
            ["contato@woomboard.app"]
        )

        XCTAssertEqual(
            engine.suggestions(
                forContextBeforeInput: "ol",
                systemCompletions: ["olá", "olho", "olhar"]
            ),
            ["olá", "olho", "olhar"]
        )
    }
}

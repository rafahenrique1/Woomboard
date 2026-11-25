import SwiftUI
import WoomboardCore

struct ContentView: View {
    @State private var settings: KeyboardSettings
    private let store = SharedSettingsStore()

    init() {
        let initial = SharedSettingsStore().loadSettings()
        _settings = State(initialValue: initial)
    }

    var body: some View {
        TabView {
            SettingsView(settings: $settings, onSave: save)
                .tabItem {
                    Label("Layout & Ajustes", systemImage: "keyboard.badge.ellipsis")
                }

            ThemesView(settings: $settings, onSave: save)
                .tabItem {
                    Label("Temas", systemImage: "paintpalette")
                }

            PlaygroundView(settings: settings)
                .tabItem {
                    Label("Testar", systemImage: "text.cursor")
                }

            OnboardingView()
                .tabItem {
                    Label("Ativar", systemImage: "checkmark.shield")
                }
        }
    }

    private func save() {
        store.saveSettings(settings)
    }
}

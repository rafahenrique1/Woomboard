import SwiftUI
import WoomboardCore

struct PlaygroundView: View {
    let settings: KeyboardSettings
    @State private var sampleText: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    statusPill("Layout: \(settings.layoutStyle.displayName)")
                    statusPill(settings.language.shortCode)
                    statusPill(DefaultThemes.theme(for: settings.selectedThemeID).name)
                }

                Text("Toque no campo abaixo para testar o Woomboard (long-press para acentos/símbolos, deslize na barra de espaço para mover o cursor):")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $sampleText)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                HStack {
                    Button("Limpar texto") {
                        sampleText = ""
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Playground")
        }
    }

    private func statusPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.secondary.opacity(0.14))
            .clipShape(Capsule())
    }
}

import SwiftUI
import WoomboardCore

struct ThemesView: View {
    @Binding var settings: KeyboardSettings
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Seguir Claro/Escuro do iOS", isOn: $settings.followSystemAppearance)
                        .onChange(of: settings.followSystemAppearance) { _ in
                            onSave()
                        }
                } footer: {
                    Text("Alterna automaticamente entre Apple Light e Apple Dark conforme a aparência do iPhone.")
                }

                Section("Temas") {
                    ForEach(DefaultThemes.all) { theme in
                Button {
                    settings.selectedThemeID = theme.id
                    onSave()
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Raio \(Int(theme.keyCornerRadius))pt • \(theme.showKeyShadow ? "Sombra iOS" : "Plano")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.selectedThemeID == theme.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.tint)
                            }
                        }

                        // Prévia de teclas no tema
                        HStack(spacing: 5) {
                            ForEach(["Q", "W", "E", "R", "T"], id: \.self) { letter in
                                Text(letter)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Color(hex: theme.textHex))
                                    .frame(maxWidth: .infinity, minHeight: 28)
                                    .background(Color(hex: theme.keyBackgroundHex))
                                    .clipShape(RoundedRectangle(cornerRadius: theme.keyCornerRadius))
                            }
                            Text("↵")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 28)
                                .background(Color(hex: theme.accentHex))
                                .clipShape(RoundedRectangle(cornerRadius: theme.keyCornerRadius))
                        }
                        .padding(8)
                        .background(Color(hex: theme.backgroundHex))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Temas Apple")
        }
    }
}

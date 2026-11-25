import SwiftUI
import WoomboardCore

struct ThemesView: View {
    @Binding var settings: KeyboardSettings
    let onSave: () -> Void

    @State private var bgColor: Color = Color(hex: "#1C1C1E")
    @State private var keyColor: Color = Color(hex: "#3A3A3C")
    @State private var accentColor: Color = Color(hex: "#0A84FF")
    @State private var textColor: Color = Color(hex: "#FFFFFF")
    @State private var cornerRadius: Double = 9.0
    @State private var showShadow: Bool = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Seguir Claro/Escuro do iOS", isOn: $settings.followSystemAppearance)
                        .onChange(of: settings.followSystemAppearance) { _ in
                            onSave()
                        }
                } footer: {
                    Text("Alterna automaticamente entre Apple Light e Apple Dark com fundo translúcido nativo do iOS.")
                }

                Section("Temas Apple") {
                    ForEach(DefaultThemes.all) { theme in
                        themeRow(theme)
                    }
                }

                Section {
                    ColorPicker("Fundo do teclado", selection: $bgColor, supportsOpacity: false)
                    ColorPicker("Cor das teclas", selection: $keyColor, supportsOpacity: false)
                    ColorPicker("Cor de destaque", selection: $accentColor, supportsOpacity: false)
                    ColorPicker("Cor do texto", selection: $textColor, supportsOpacity: false)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Arredondamento: \(Int(cornerRadius))pt")
                            .font(.subheadline)
                        Slider(value: $cornerRadius, in: 4...14, step: 1)
                    }

                    Toggle("Sombra estilo iOS", isOn: $showShadow)

                    Button {
                        let custom = KeyboardTheme(
                            id: "custom-theme",
                            name: "Meu Tema",
                            backgroundHex: bgColor.toHex(),
                            keyBackgroundHex: keyColor.toHex(),
                            specialKeyBackgroundHex: bgColor.toHex(),
                            accentHex: accentColor.toHex(),
                            textHex: textColor.toHex(),
                            secondaryTextHex: textColor.toHex(),
                            keyCornerRadius: cornerRadius,
                            showKeyShadow: showShadow
                        )
                        settings.customTheme = custom
                        settings.selectedThemeID = custom.id
                        settings.followSystemAppearance = false
                        onSave()
                    } label: {
                        HStack {
                            Label("Aplicar Meu Tema Customizado", systemImage: "sparkles")
                            Spacer()
                            if settings.selectedThemeID == "custom-theme" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                } header: {
                    Text("Estúdio de Tema Customizado")
                }
            }
            .onAppear(perform: loadCustomColors)
            .navigationTitle("Temas")
        }
    }

    private func themeRow(_ theme: KeyboardTheme) -> some View {
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

                HStack(spacing: 5) {
                    ForEach(["Q", "W", "E", "R", "T"], id: \.self) { letter in
                        Text(letter)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color(hex: theme.textHex))
                            .frame(maxWidth: .infinity, minHeight: 28)
                            .background(Color(hex: theme.keyBackgroundHex))
                            .clipShape(RoundedRectangle(cornerRadius: theme.keyCornerRadius))
                    }
                    Image(systemName: "return")
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

    private func loadCustomColors() {
        guard let custom = settings.customTheme else { return }
        bgColor = Color(hex: custom.backgroundHex)
        keyColor = Color(hex: custom.keyBackgroundHex)
        accentColor = Color(hex: custom.accentHex)
        textColor = Color(hex: custom.textHex)
        cornerRadius = custom.keyCornerRadius
        showShadow = custom.showKeyShadow
    }
}

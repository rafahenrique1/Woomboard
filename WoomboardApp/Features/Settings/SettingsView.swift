import SwiftUI
import WoomboardCore

struct SettingsView: View {
    @Binding var settings: KeyboardSettings
    let onSave: () -> Void

    @State private var newTrigger: String = ""
    @State private var newExpansion: String = ""
    @State private var newPinnedClip: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(KeyboardLayoutStyle.allCases) { style in
                        LayoutStyleCard(
                            style: style,
                            isSelected: settings.layoutStyle == style,
                            theme: DefaultThemes.theme(for: settings.selectedThemeID)
                        ) {
                            settings.applyLayoutPreset(style)
                            onSave()
                        }
                    }
                } header: {
                    Text("Estilo de Layout")
                } footer: {
                    Text("Dica: você também pode trocar o layout e ajustes direto no botão ⚙️ da barra superior do teclado.")
                }

                Section("Ergonomia & Recursos") {
                    Picker("Idioma", selection: $settings.language) {
                        ForEach(KeyboardLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }

                    Picker("Altura do teclado", selection: $settings.heightPreset) {
                        ForEach(KeyboardHeightPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }

                    Picker("Modo uma mão", selection: $settings.oneHandedMode) {
                        ForEach(OneHandedMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }

                    Toggle("Linha numérica fixa (1–0)", isOn: $settings.showNumberRow)
                    Toggle("Símbolos secundários nas letras", isOn: $settings.showSecondarySymbols)
                    Toggle("Barra de ferramentas no topo", isOn: $settings.showToolbar)

                    if settings.language == .ptBR {
                        Toggle("Tecla Ç dedicada", isOn: $settings.showDedicatedCedilla)
                    }
                }

                if settings.showToolbar {
                    Section {
                        ForEach(ToolbarItem.allCases) { item in
                            Toggle(isOn: Binding(
                                get: { settings.toolbarItems.contains(item) },
                                set: { enabled in
                                    if enabled {
                                        if !settings.toolbarItems.contains(item) && settings.toolbarItems.count < 6 {
                                            settings.toolbarItems.append(item)
                                        }
                                    } else {
                                        settings.toolbarItems.removeAll { $0 == item }
                                    }
                                    onSave()
                                }
                            )) {
                                Label(item.displayName, systemImage: item.systemImage)
                            }
                        }
                    } header: {
                        Text("Ícones da Barra de Ferramentas (máx. 6)")
                    }
                }

                Section("Digitação & Gestos (120Hz)") {
                    Toggle("Trackpad na barra de espaço", isOn: $settings.enableSpacebarTrackpad)
                    Toggle("Maiúscula automática", isOn: $settings.autoCapitalization)
                    Toggle("Ponto com duplo espaço", isOn: $settings.doubleSpacePeriod)
                    Toggle("Popup de ampliação da tecla", isOn: $settings.showKeyPopup)
                }

                Section("Feedback Tátil & Som") {
                    Toggle("Resposta tátil (Haptics)", isOn: $settings.enableHaptics)
                    if settings.enableHaptics {
                        Picker("Intensidade", selection: $settings.hapticIntensity) {
                            ForEach(HapticIntensity.allCases) { intensity in
                                Text(intensity.displayName).tag(intensity)
                            }
                        }
                    }
                    Toggle("Som das teclas", isOn: $settings.enableKeySounds)
                }

                Section("Itens Fixados (Clipboard Offline)") {
                    ForEach(settings.pinnedClipboardItems, id: \.self) { item in
                        Text(item)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    .onDelete { offsets in
                        settings.pinnedClipboardItems.remove(atOffsets: offsets)
                        onSave()
                    }

                    HStack {
                        TextField("Novo texto fixado (ex.: PIX, endereço)", text: $newPinnedClip)
                        Button("Fixar") {
                            let cleaned = newPinnedClip.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !cleaned.isEmpty else { return }
                            settings.pinnedClipboardItems.insert(cleaned, at: 0)
                            newPinnedClip = ""
                            onSave()
                        }
                        .disabled(newPinnedClip.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    ForEach(settings.snippets) { snippet in
                        HStack {
                            Text(snippet.trigger)
                                .font(.subheadline.monospaced().bold())
                                .foregroundStyle(.tint)
                            Text("→")
                                .foregroundStyle(.secondary)
                            Text(snippet.expansion)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }
                    .onDelete { offsets in
                        settings.snippets.remove(atOffsets: offsets)
                        onSave()
                    }

                    VStack(spacing: 8) {
                        TextField("Atalho (ex.: @@)", text: $newTrigger)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Texto completo", text: $newExpansion)
                        Button("Adicionar atalho") {
                            let trigger = newTrigger.trimmingCharacters(in: .whitespacesAndNewlines)
                            let expansion = newExpansion.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trigger.isEmpty, !expansion.isEmpty else { return }
                            settings.snippets.append(TextSnippet(trigger: trigger, expansion: expansion))
                            newTrigger = ""
                            newExpansion = ""
                            onSave()
                        }
                        .disabled(newTrigger.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  newExpansion.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Atalhos Rápidos (Snippets)")
                } footer: {
                    Text("Funcionam 100% offline na barra de sugestões e na gaveta da toolbar.")
                }
            }
            .onChange(of: settings) { _ in
                onSave()
            }
            .navigationTitle("Woomboard")
        }
    }
}

private struct LayoutStyleCard: View {
    let style: KeyboardLayoutStyle
    let isSelected: Bool
    let theme: KeyboardTheme
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Layout \(style.displayName)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(style.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }

                VStack(spacing: 4) {
                    if style == .samsung {
                        miniRow(keys: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], isSpecialRow: false)
                    }
                    miniRow(keys: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"], isSpecialRow: false)
                    miniRow(
                        keys: style == .samsung
                            ? ["!#1", ",", "Português", ".", "↵"]
                            : ["123", "espaço", "↵"],
                        isSpecialRow: true
                    )
                }
                .padding(6)
                .background(Color(hex: theme.backgroundHex))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func miniRow(keys: [String], isSpecialRow: Bool) -> some View {
        HStack(spacing: 3) {
            ForEach(keys, id: \.self) { key in
                let isAccent = (key == "↵")
                let isSpace = (key == "espaço" || key == "Português")
                Text(key)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isAccent ? .white : Color(hex: theme.textHex))
                    .frame(maxWidth: isSpace ? .infinity : nil)
                    .frame(minWidth: isSpace ? 60 : 18, minHeight: 18)
                    .padding(.horizontal, isSpecialRow ? 4 : 0)
                    .background(
                        isAccent
                            ? Color(hex: theme.accentHex)
                            : Color(hex: (isSpecialRow && !isSpace && key != "," && key != ".") ? theme.specialKeyBackgroundHex : theme.keyBackgroundHex)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

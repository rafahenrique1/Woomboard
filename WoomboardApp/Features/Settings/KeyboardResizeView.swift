import SwiftUI
import WoomboardCore

/// Tela interativa de redimensionamento manual em tempo real (estilo Samsung One UI).
/// Mostra o layout escolhido (Samsung ou Apple) em escala real ancorado na base da tela,
/// permitindo arrastar a alça superior ou ajustar o slider até 50% da altura da tela.
struct KeyboardResizeView: View {
    @Binding var settings: KeyboardSettings
    let onSave: () -> Void

    @State private var dragStartScale: Double? = nil

    private var activeTheme: KeyboardTheme {
        if let custom = settings.customTheme, settings.selectedThemeID == custom.id {
            return custom
        }
        return DefaultThemes.theme(for: settings.selectedThemeID)
    }

    var body: some View {
        GeometryReader { geo in
            let maxKeyboardHeight = geo.size.height * 0.50
            let rowCount = settings.showNumberRow ? 5.0 : 4.0
            let baseRowHeight = 43.0
            let rawHeight = (baseRowHeight * settings.keyboardHeightScale * rowCount)
                + (settings.showToolbar ? 40.0 : 12.0)
                + (7.0 * (rowCount - 1))
            let previewHeight = min(max(rawHeight, 180.0), maxKeyboardHeight)
            let percent = Int(round(settings.keyboardHeightScale * 100))

            VStack(spacing: 0) {
                // Área superior com controles e feedback em tempo real
                VStack(spacing: 14) {
                    Text("Arraste a alça azul do teclado ou use o controle abaixo")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Label("Layout \(settings.layoutStyle.displayName)", systemImage: "keyboard")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.14))
                            .clipShape(Capsule())

                        Text("\(percent)% • \(Int(previewHeight))pt")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.16))
                            .foregroundStyle(.tint)
                            .clipShape(Capsule())
                    }

                    VStack(spacing: 6) {
                        Slider(
                            value: Binding(
                                get: { settings.keyboardHeightScale },
                                set: { newVal in
                                    settings.keyboardHeightScale = newVal
                                    onSave()
                                }
                            ),
                            in: 0.80...1.65,
                            step: 0.01
                        )
                        HStack {
                            Text("Compacto")
                            Spacer()
                            Text("Padrão")
                            Spacer()
                            Text("Metade da tela")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)

                    Button("Restaurar tamanho padrão (100%)") {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            settings.keyboardHeightScale = 1.0
                            settings.heightPreset = .standard
                            onSave()
                        }
                    }
                    .font(.footnote.weight(.medium))
                }
                .padding(.top, 16)
                .padding(.horizontal)

                Spacer(minLength: 12)

                // Alça de arraste superior estilo Samsung One UI
                VStack(spacing: 4) {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: 56, height: 6)
                    Image(systemName: "arrow.up.and.down")
                        .font(.caption2.bold())
                        .foregroundStyle(.tint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if dragStartScale == nil {
                                dragStartScale = settings.keyboardHeightScale
                            }
                            let start = dragStartScale ?? 1.0
                            // Arrastar para cima aumenta a altura; para baixo diminui
                            let deltaScale = Double(-value.translation.height) / 220.0
                            let clamped = min(max(start + deltaScale, 0.80), 1.65)
                            settings.keyboardHeightScale = clamped
                        }
                        .onEnded { _ in
                            dragStartScale = nil
                            onSave()
                        }
                )

                // Prévia 1:1 do teclado escolhido (Samsung ou Apple)
                LiveKeyboardPreview(
                    settings: settings,
                    theme: activeTheme,
                    totalHeight: previewHeight
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .navigationTitle("Tamanho do Teclado")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LiveKeyboardPreview: View {
    let settings: KeyboardSettings
    let theme: KeyboardTheme
    let totalHeight: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            if settings.showToolbar {
                HStack {
                    ForEach(settings.toolbarItems.prefix(6)) { item in
                        Spacer()
                        Image(systemName: item.systemImage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: theme.textHex).opacity(0.8))
                        Spacer()
                    }
                }
                .frame(height: 30)
            }

            if settings.showNumberRow {
                previewRow(["1","2","3","4","5","6","7","8","9","0"], isNumberRow: true)
            }

            previewRow(["Q","W","E","R","T","Y","U","I","O","P"])
            previewRow(["A","S","D","F","G","H","J","K","L"], horizontalInset: 14)

            HStack(spacing: 5) {
                specialKey(symbol: "shift.fill", width: 42)
                ForEach(["Z","X","C","V","B","N","M"], id: \.self) { char in
                    letterKey(char)
                }
                specialKey(symbol: "delete.left", width: 42)
            }

            HStack(spacing: 5) {
                specialKey(title: settings.layoutStyle == .samsung ? "!#1" : "123", width: 46)
                if settings.layoutStyle == .samsung {
                    letterKey(",", fixedWidth: 30)
                }
                Text(settings.layoutStyle == .samsung
                     ? (settings.language == .ptBR ? "Português" : "English")
                     : settings.language.spacebarLabel)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: theme.secondaryTextHex))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: theme.keyBackgroundHex))
                    .clipShape(RoundedRectangle(cornerRadius: theme.keyCornerRadius, style: .continuous))
                if settings.layoutStyle == .samsung {
                    letterKey(".", fixedWidth: 30)
                }
                Image(systemName: "return")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: settings.layoutStyle == .samsung ? 52 : 66)
                    .frame(maxHeight: .infinity)
                    .background(Color(hex: theme.accentHex))
                    .clipShape(RoundedRectangle(cornerRadius: theme.keyCornerRadius, style: .continuous))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(height: totalHeight)
        .frame(maxWidth: .infinity)
        .background(Color(hex: theme.backgroundHex))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.6), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
    }

    private func previewRow(_ chars: [String], isNumberRow: Bool = false, horizontalInset: CGFloat = 0) -> some View {
        HStack(spacing: 5) {
            ForEach(chars, id: \.self) { char in
                letterKey(char, isNumber: isNumberRow)
            }
        }
        .padding(.horizontal, horizontalInset)
    }

    private func letterKey(_ text: String, isNumber: Bool = false, fixedWidth: CGFloat? = nil) -> some View {
        Text(text)
            .font(.system(size: isNumber ? 16 : 19, weight: .regular))
            .foregroundStyle(Color(hex: theme.textHex))
            .frame(maxWidth: fixedWidth == nil ? .infinity : fixedWidth, maxHeight: .infinity)
            .background(Color(hex: theme.keyBackgroundHex))
            .clipShape(RoundedRectangle(cornerRadius: theme.keyCornerRadius, style: .continuous))
    }

    private func specialKey(title: String? = nil, symbol: String? = nil, width: CGFloat) -> some View {
        Group {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .medium))
            } else if let title {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .foregroundStyle(Color(hex: theme.textHex))
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(Color(hex: theme.specialKeyBackgroundHex))
        .clipShape(RoundedRectangle(cornerRadius: theme.keyCornerRadius, style: .continuous))
    }
}

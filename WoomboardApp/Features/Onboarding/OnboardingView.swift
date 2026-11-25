import SwiftUI
import UIKit

struct OnboardingView: View {
    @State private var isKeyboardEnabled: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: isKeyboardEnabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isKeyboardEnabled ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isKeyboardEnabled ? "Woomboard ativo no iOS" : "Teclado ainda não ativado")
                                .font(.headline)
                            Text(isKeyboardEnabled
                                 ? "Você já pode selecioná-lo pelo botão 🌐 em qualquer app."
                                 : "Siga os passos abaixo para ativar nos Ajustes do iPhone.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Passo a passo") {
                    Label("1. Abra o app Ajustes do iOS.", systemImage: "gear")
                    Label("2. Vá em Geral → Teclado → Teclados.", systemImage: "keyboard")
                    Label("3. Toque em Adicionar Novo Teclado e escolha Woomboard.", systemImage: "plus.circle")
                    Label("4. (Opcional) Ative Permitir Acesso Total para sincronizar temas/ajustes e colar da área de transferência.", systemImage: "lock.open")
                }

                Section("Privacidade") {
                    Text("O Woomboard funciona 100% offline para digitação, sugestões e atalhos rápidos. Nenhum texto digitado é enviado para servidores externos.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Section {
                        Link(destination: url) {
                            Label("Abrir Ajustes do iOS", systemImage: "arrow.up.right.square")
                        }
                    }
                }
            }
            .onAppear(perform: refreshStatus)
            .navigationTitle("Ativação")
        }
    }

    private func refreshStatus() {
        let modes = UITextInputMode.activeInputModes
        isKeyboardEnabled = modes.contains { mode in
            (mode.value(forKey: "identifier") as? String)?.contains("com.woomboard") == true
        }
    }
}

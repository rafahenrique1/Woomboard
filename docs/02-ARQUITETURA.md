# 02 — Arquitetura Técnica

## 1. Visão Geral dos Módulos

No iOS, um teclado de terceiros não é um app isolado — ele precisa de um **Container App** que empacota uma **App Extension** do tipo `com.apple.keyboard-service`.

```text
+-------------------------------------------------------------------+
|                        WoomboardApp (SwiftUI)                     |
|  Onboarding | Galeria de Temas | Configurações | Playground       |
+---------------------------------+---------------------------------+
                                  |
                         (App Groups / Shared)
                                  |
+---------------------------------v---------------------------------+
|                     WoomboardCore (Swift Package)                 |
|  Models | Themes | SharedSettingsStore | SuggestionEngine         |
+---------------------------------^---------------------------------+
                                  |
+---------------------------------+---------------------------------+
|                 WoomboardKeyboard (UIKit Extension)               |
|  KeyboardViewController | LayoutEngine | KeyButton | SuggestionBar|
+-------------------------------------------------------------------+
```

## 2. Por que SwiftUI no App e UIKit na Extensão?

- **WoomboardApp (SwiftUI):** telas de configuração, onboarding, pré-visualização de temas e playground são ideais em SwiftUI pela produtividade e facilidade de manutenção.
- **WoomboardKeyboard (UIKit):**
  - Extensões de teclado no iOS possuem um **limite rígido de memória** (historicamente ~48–60 MB; se ultrapassar, o iOS encerra o teclado imediatamente).
  - UIKit oferece controle fino sobre `UIInputViewController`, eventos de toque (`touchesBegan`/`Moved`/`Ended`), hit-testing customizado e menor overhead de memória e latência.

## 3. Comunicação entre App e Extensão

O App Container e a Keyboard Extension rodam em processos separados e sandboxes distintos. A comunicação é feita via **App Groups**:
- **Identificador sugerido:** `group.com.woomboard.shared`
- **Dados leves (preferências, tema ativo, toggles):** `UserDefaults(suiteName:)` encapsulado em `SharedSettingsStore`.
- **Dados estruturados (temas customizados, snippets, dicionário pessoal):** arquivos JSON ou SQLite/CoreData no diretório retornado por `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`.

## 4. Fluxo de Digitação

1. Usuário toca em uma `KeyButton`.
2. `KeyboardView` envia uma `KeyAction` ao `KeyboardViewController`.
3. `KeyboardViewController` aplica o feedback tátil/sonoro (se habilitado) e envia o texto para `textDocumentProxy.insertText(_:)` ou `deleteBackward()`.
4. O contexto atual (`documentContextBeforeInput`) é consultado para atualizar:
   - Estado de Shift (auto-capitalização no início de frase).
   - Sugestões na `SuggestionBarView` via `SuggestionEngine`.

## 5. Boas Práticas de Performance e Memória

- Evitar carregar imagens grandes ou fontes pesadas na memória da extensão.
- Reutilizar views das teclas ao trocar entre camadas (letras / números / símbolos) em vez de recriar toda a hierarquia.
- Nunca bloquear a main thread durante cálculo de sugestões (executar buscas pesadas de forma assíncrona e cancelar tarefas anteriores).
- Sempre monitorar o uso de RAM no Xcode Instruments (Memory / Allocations) rodando no dispositivo físico.

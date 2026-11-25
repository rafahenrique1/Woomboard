# Woomboard

Teclado inteligente e personalizável para **iOS**, desenvolvido em **Swift puro** (SwiftUI para o App Container + UIKit para a Keyboard Extension + Swift Package compartilhado).

## Visão Geral

O **Woomboard** combina personalização visual profunda (temas, cores, fontes, sons, haptics e layouts) com recursos inteligentes de digitação (sugestões contextuais, atalhos/snippets, correção e assistência de texto) mantendo foco rigoroso em **desempenho**, **baixo consumo de memória** e **privacidade**.

## Stack Recomendada

- **Linguagem:** Swift 5.9+ (Swift puro)
- **Plataforma:** iOS 16.0+
- **App Container (`WoomboardApp`):** SwiftUI
- **Keyboard Extension (`WoomboardKeyboard`):** UIKit (`UIInputViewController`) — recomendado pela Apple e pela indústria para respeitar o limite rígido de memória das extensões de teclado (~48–60 MB) e garantir latência mínima no toque
- **Core Compartilhado (`Packages/WoomboardCore`):** Swift Package Manager (modelos, temas, motor de sugestões, persistência via App Groups)
- **Geração de Projeto:** `project.yml` compatível com [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Estrutura do Projeto

```text
Woomboard/
├── README.md
├── project.yml                         # Gera o Woomboard.xcodeproj via XcodeGen
├── docs/                               # Documentação técnica e de produto
│   ├── 01-VISAO-E-ESCOPO.md
│   ├── 02-ARQUITETURA.md
│   ├── 03-FUNCIONALIDADES.md
│   ├── 04-DESIGN-E-TEMAS.md
│   ├── 05-PRIVACIDADE-E-APPLE-GUIDELINES.md
│   └── 06-ROADMAP.md
├── WoomboardApp/                       # App principal (Configurações, Temas, Onboarding, Playground)
├── WoomboardKeyboard/                  # Extensão de teclado (UIInputViewController)
├── Packages/
│   └── WoomboardCore/                  # Código compartilhado (Temas, Storage, Inteligência)
└── WoomboardTests/                     # Testes unitários
```

## Como Começar no macOS / Xcode

1. Instale o Xcode (15 ou superior) e, opcionalmente, o XcodeGen:
   ```bash
   brew install xcodegen
   ```
2. Na raiz do projeto, gere o `.xcodeproj`:
   ```bash
   xcodegen generate
   ```
3. Abra `Woomboard.xcodeproj` no Xcode.
4. Configure o **Team** (Signing & Capabilities) nos targets `WoomboardApp` e `WoomboardKeyboard`.
5. Configure o mesmo **App Group** (ex.: `group.com.woomboard.shared`) em ambos os targets.
6. Execute o scheme `WoomboardApp` no simulador ou dispositivo físico e ative o teclado em:
   **Ajustes → Geral → Teclado → Teclados → Adicionar Novo Teclado → Woomboard**.

## Documentação

- [01 - Visão e Escopo](docs/01-VISAO-E-ESCOPO.md)
- [02 - Arquitetura](docs/02-ARQUITETURA.md)
- [03 - Funcionalidades](docs/03-FUNCIONALIDADES.md)
- [04 - Design e Temas](docs/04-DESIGN-E-TEMAS.md)
- [05 - Privacidade e Diretrizes da Apple](docs/05-PRIVACIDADE-E-APPLE-GUIDELINES.md)
- [06 - Roadmap](docs/06-ROADMAP.md)

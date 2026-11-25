# 06 — Roadmap de Desenvolvimento

## Fase 1 — Fundação e MVP Funcional
- [ ] Gerar projeto no Xcode (`xcodegen generate`) e configurar Signing + App Groups no macOS.
- [x] Implementar motor de layouts duplos (**Samsung** e **Apple**) com camadas `ABC`, `123` e `#+=` em `PT-BR` e `EN-US`.
- [x] Implementar botão de troca de teclado (`needsInputModeSwitchKey`).
- [x] Implementar barra superior híbrida: sugestões (`UITextChecker` + Snippets) e toolbar estilo Samsung.
- [x] Implementar `WoomboardApp` com seleção visual de layouts, temas Apple, snippets, Playground e Onboarding.
- [ ] Validar consumo de memória (< 35 MB em uso contínuo) em iPhone físico.

## Fase 2 — Personalização e Experiência
- [x] Popup de acentuação PT-BR e símbolos secundários estilo Samsung (long-press deslizante).
- [x] Feedback háptico configurável (Leve/Médio), som de teclas e key pop-up preview estilo Apple.
- [x] Modo cursor/trackpad deslizando na barra de espaço, backspace contínuo por palavra, modo uma mão e altura ajustável.
- [x] Snippets / atalhos rápidos gerenciados no App Container e acessíveis na gaveta da toolbar.
- [ ] Editor avançado de temas customizados (paleta livre pelo usuário).

## Fase 3 — Recursos Inteligentes e Polimento
- [ ] Barra de ferramentas rápida (emojis, snippets, clipboard/ações).
- [ ] Assistente de escrita inteligente (opcional, com opt-in e Full Access).
- [ ] Testes automatizados (unitários em `WoomboardCore` e UI tests no `WoomboardApp`).
- [ ] Acessibilidade completa (VoiceOver, Alto Contraste, Reduce Motion).

## Fase 4 — Beta e Lançamento
- [ ] Distribuição via TestFlight para testes reais em diferentes apps (WhatsApp, Safari, Notas, Instagram).
- [ ] Ajustes de estabilidade, memória e revisão das diretrizes da App Store.
- [ ] Submissão da v1.0 na App Store.

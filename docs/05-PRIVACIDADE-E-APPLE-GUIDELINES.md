# 05 — Privacidade e Diretrizes da Apple (App Store)

Desenvolver um teclado customizado para iOS exige atenção rigorosa às regras da Apple ([App Store Review Guidelines — 4.4 Extensions](https://developer.apple.com/app-store/review/guidelines/#extensions)).

## 1. Requisitos Obrigatórios da Apple

- **Botão de troca de teclado (Next Keyboard / Globo):**
  - Sempre verificar `self.needsInputModeSwitchKey`. Quando `true`, o teclado **deve** exibir o botão de alternância ligado a `handleInputModeList(from:with:)`.
- **Funcionar sem "Acesso Total" (Full Access):**
  - O teclado **deve** ser totalmente utilizável para digitação básica mesmo quando o usuário não concede *Allow Full Access* (`RequestsOpenAccess = YES` no `Info.plist` é opcional, mas se habilitado, o teclado ainda precisa funcionar sem ele).
  - Verificar em tempo de execução com `self.hasFullAccess`.
- **Campos de senha e dados sensíveis:**
  - O iOS substitui automaticamente teclados de terceiros pelo teclado nativo em campos `isSecureTextEntry` (senhas). Nunca tentar contornar ou registrar dados sensíveis.

## 2. O que exige vs. não exige Full Access

| Recurso | Sem Full Access | Com Full Access |
| --- | :---: | :---: |
| Digitação básica e layouts | Sim | Sim |
| Temas embutidos e App Group (leitura) | Parcial* | Sim |
| Haptic feedback / Sons customizados | Limitado | Sim |
| Acesso à rede / IA em nuvem | Não | Sim |
| Compartilhamento completo via App Group | Limitado | Sim |

*\*Nota: Sem Full Access, o sandbox da extensão restringe leitura/escrita em containers compartilhados e acesso à rede. Sempre prever fallback seguro com tema padrão embutido.*

## 3. Compromisso de Privacidade do Woomboard

- **Zero keylogging:** nunca armazenar ou transmitir o que o usuário digita fora de recursos explicitamente acionados por ele (ex.: botão "Reescrever com IA").
- **Transparência:** explicar claramente no Onboarding e nas Configurações por que o Full Access é solicitado e o que funciona sem ele.
- **Política de Privacidade:** obrigatória antes da submissão na App Store, detalhando coleta zero de dados de digitação.

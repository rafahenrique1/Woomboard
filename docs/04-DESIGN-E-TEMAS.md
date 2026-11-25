# 04 — Design e Sistema de Temas

## 1. Princípios de Design

- **Familiaridade iOS:** manter proporções, espaçamentos e áreas de toque previsíveis para evitar erros de digitação.
- **Contraste e legibilidade:** garantir contraste mínimo adequado (WCAG AA) entre o texto da tecla e seu fundo em todos os temas prontos.
- **Micro-interações:** popup de tecla ampliada ao tocar (key pop-up preview) e transição suave de estado pressionado.

## 2. Tokens de Tema (`KeyboardTheme`)

Cada tema é representado por um conjunto serializável (`Codable`) de tokens em `WoomboardCore`:

| Token | Descrição |
| --- | --- |
| `id` | Identificador único do tema |
| `name` | Nome exibido na galeria |
| `backgroundHex` | Cor de fundo do container do teclado |
| `keyBackgroundHex` | Cor das teclas de caracteres |
| `specialKeyBackgroundHex` | Cor das teclas funcionais (Shift, Backspace, Return, 123) |
| `accentHex` | Cor de destaque (botão Return primário, seleção, popup) |
| `textHex` | Cor principal dos rótulos das teclas |
| `secondaryTextHex` | Cor de rótulos secundários / sugestões |
| `keyCornerRadius` | Raio de arredondamento das teclas (ex.: `6.0` a `12.0`) |
| `showKeyShadow` | Define se a tecla exibe sombra sutil inferior |

## 3. Temas Iniciais (Presets)

1. **Woom Light:** estilo limpo inspirado no iOS claro com acento azul/índigo.
2. **Woom Dark:** cinza grafite profundo com teclas elevadas e alto conforto noturno.
3. **Midnight OLED:** preto absoluto (`#000000`) com bordas sutis para telas OLED.
4. **Matcha Soft:** paleta suave esverdeada com teclas arredondadas.

## 4. Acessibilidade

- Respeitar `UIAccessibility.isReduceMotionEnabled` (desativar animações excessivas).
- Suporte a `accessibilityLabel` e `accessibilityTraits = .keyboardKey` em todas as teclas para VoiceOver.
- Respeitar a aparência do sistema (`light` / `dark`) quando o usuário escolher o modo "Automático".

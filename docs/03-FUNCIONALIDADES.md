# 03 — Funcionalidades

## 1. Personalização Visual e Tátil
- **Temas prontos:** Claro, Escuro, Alto Contraste, Minimalista, Gradiente.
- **Editor de tema:** cor de fundo do teclado, cor das teclas, cor do texto, raio das bordas, sombra/elevação.
- **Feedback:**
  - Haptic feedback configurável (`UIImpactFeedbackGenerator` — leve, médio, desligado).
  - Som de clique (quando permitido e ativado pelo usuário).
- **Ergonomia:**
  - Altura ajustável do teclado (Compacto, Padrão, Confortável).
  - Linha numérica fixa opcional no topo.
  - Modo de uma mão (esquerda / direita).

## 2. Digitação e Layouts
- **Layouts suportados inicialmente:** QWERTY (Português BR e Inglês US).
- **Acentuação nativa:** pressionar e segurar (long-press) vogais e `c` para exibir popup de acentos (`á, à, â, ã, ç`, etc.).
- **Atalhos rápidos:**
  - Duplo toque na barra de espaço insere ponto final + espaço.
  - Deslizar na barra de espaço move o cursor (trackpad mode).
  - Segurar Backspace apaga continuamente (com aceleração por palavra).

## 3. Inteligência (Smart Features)
- **Camada 1 (Offline / Sem Full Access):**
  - Autocompletar e correção ortográfica via `UITextChecker`.
  - Sugestão de próxima palavra com base em frequência local.
  - Expansão de snippets/atalhos pessoais (ex.: `@@` → e-mail do usuário).
- **Camada 2 (Opcional / Com Full Access e Consentimento):**
  - Assistente de escrita na barra superior (corrigir gramática, deixar mais formal/casual, resumir, traduzir).
  - Busca rápida de emojis por contexto.

## 4. App Container (`WoomboardApp`)
- **Onboarding interativo:** verifica se o teclado já foi ativado (`UITextInputMode.activeInputModes`) e guia o usuário passo a passo.
- **Playground:** campo de texto integrado para testar alterações de tema e layout instantaneamente.
- **Gerenciador de Snippets:** criar, editar e remover atalhos de texto.
- **Central de Privacidade:** explicação transparente do que funciona offline e do que exige *Full Access*.

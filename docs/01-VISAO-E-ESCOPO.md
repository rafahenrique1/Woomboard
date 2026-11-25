# 01 — Visão e Escopo do Produto

## 1. Proposta de Valor

O **Woomboard** é um teclado inteligente e personalizável para iOS que combina o **design nativo da Apple** com a **ergonomia e produtividade do teclado Samsung**:
- **Dois layouts oficiais (Samsung e Apple):** o usuário escolhe entre a ergonomia completa do Samsung (linha numérica fixa, símbolos no toque longo, vírgula/ponto na base e barra de ferramentas) ou o layout limpo padrão Apple, podendo personalizar cada recurso individualmente.
- **Visual nativo Apple:** tipografia SF Pro, cores e sombras estilo iOS, pop-up de ampliação e transições limpas em ambos os layouts.
- **Produtividade sem atrito:** acentuação PT-BR no toque longo, barra de espaço como trackpad, backspace acelerado por palavra, modo uma mão, altura ajustável e atalhos rápidos (snippets) 100% offline.
- **Privacidade em primeiro lugar:** funcionamento completo offline para digitação básica, sem exigir *Full Access* para recursos essenciais.

## 2. Público-Alvo

- Usuários de iPhone/iPad que desejam personalizar o visual do teclado além do padrão da Apple.
- Profissionais e criadores de conteúdo que usam snippets, respostas rápidas, símbolos frequentes ou reescrita de texto.
- Usuários multilíngues (ex.: Português + Inglês) que querem alternância fluida e previsões inteligentes.

## 3. Escopo do MVP (v0.1)

O que **entra** no MVP:
- Teclado QWERTY (PT-BR / EN) funcional com letras, números, símbolos e acentuação (long-press).
- Alternância de idioma/teclado (botão globo obrigatório pelas diretrizes da Apple quando necessário).
- Barra de sugestões básica (usando `UITextChecker` nativo do iOS + dicionário local).
- Sistema de temas com 3–5 presets prontos (Claro, Escuro, Minimal, Neon/Custom).
- App Container em SwiftUI com:
  - Guia passo a passo de ativação (Onboarding).
  - Galeria de temas e customização básica.
  - Área de teste ("Playground") para experimentar o teclado na hora.
- Sincronização de configurações entre App e Extensão via **App Groups**.

O que fica para **versões futuras** (pós-MVP):
- Editor avançado de temas (imagem de fundo, gradientes, fontes customizadas).
- Digitação por deslize (Swipe / Glide Typing).
- Recursos de IA generativa (reescrita, tradução, ajuste de tom — opcional e com consentimento explícito).
- Sincronização na nuvem via iCloud/CloudKit.
- Snippets inteligentes e área de transferência (clipboard manager).

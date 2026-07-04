# CURRENT_STATE — Balabolka Web
> Última atualização: Fase 2 | 04/07/2026

## Arquitetura Ativa
- Monolito HTML autocontido (HTML + CSS + JS inline) — sem bundler, sem Node.js, sem build
- Web Speech API (SpeechSynthesis) como motor TTS com chunking adaptativo (3000 chars/chunk)
- Sistema de abas internas com persistência via localStorage
- Renderização de Markdown opcional (conversão para HTML inline)
- Leitura com realce sincronizado: tokenização por `split(/(\s+)/)`, spans coloridos inline
- Keep-alive timer (5s pause/resume) para evitar cancelamento automático do Chrome/Edge

## Módulos e Contratos Vigentes
| Módulo | Arquivo | Contrato Público | Desde |
|--------|---------|------------------|-------|
| `state` | `balabolka_web.html` (var) | Objeto global com tabs, texts, activeTab, rate, pitch, volume, selectedVoiceName, colors, font, zoom, buttonSize, isMd, voices, ttsSupported, isPlaying, isPaused, isDirty, isRecording, renaming, findText, replaceText, findCase, activeMenu, dragging, readingTokens, readingStartIdx, currentTokenIdx, originalMdTexts, isRenderedMd, isInReadingView, lastReadTokenIdx, keepAliveTimer | Fase 2 |
| `LS` | `balabolka_web.html` (var) | `get(k, def): any`, `set(k, v): void` — wrapper localStorage com JSON parse/stringify | Fase 1 |
| `$(id)` | `balabolka_web.html` (fn) | `(id: string): HTMLElement` — atalho para `document.getElementById` | Fase 1 |
| `getPlainText()` | `balabolka_web.html` (fn) | `(): string` — texto plano da aba ativa (stripa MD se renderizado) | Fase 1 |
| `getCursorOffset()` | `balabolka_web.html` (fn) | `(): number` — offset do cursor no editor via tree-walk com suporte a `<br>` e blocos | Fase 1 |
| `tokenize(text)` | `balabolka_web.html` (fn) | `(text: string): string[]` — split por `/(\s+)/` preservando espaços/quebras como tokens | Fase 1 |
| `splitTextIntoChunks(text, maxLen)` | `balabolka_web.html` (fn) | `(text: string, maxLen?: number): string[]` — divide em pedaços naturais (pontuação, espaço, limite) | Fase 1 |
| `renderReadingMode(tokens, startIdx)` | `balabolka_web.html` (fn) | `(tokens: string[], startIdx: number): void` — substitui innerHTML por spans `.token` coloridos, preserva scrollTop/scrollHeight, NÃO aplica `.active` antecipadamente (Bug 1 resolvido) | Fase 2 |
| `clearReadingView()` | `balabolka_web.html` (fn) | `(): void` — extrai texto real dos spans antes de limpar; restaura cursor na posição correta via `lastReadTokenIdx`; reativa contentEditable, esconde hint | Fase 2 |
| `restoreEditorMode()` | `balabolka_web.html` (fn) | `(): void` — pós-fala: preserva tokens se `currentTokenIdx >= 0` (modo leitura parada), senão limpa; reativa contentEditable | Fase 1 |
| `highlightToken(idx)` | `balabolka_web.html` (fn) | `(idx: number): void` — marca token[idx] como `.active`, anteriores como `.read`, scrollIntoView se necessário | Fase 1 |
| `playSpeech()` | `balabolka_web.html` (fn) | `(): void` — inicia/resume leitura; constrói tokenMap com string original (inclui `\n`); onboundary usa `chunkOffset + e.charIndex`; usa `skipWhitespaceTokens` para cursor em linha vazia (Bug 2 resolvido) | Fase 2 |
| `stopSpeech()` | `balabolka_web.html` (fn) | `(): void` — cancela síntese, chama restoreEditorMode, limpa keep-alive | Fase 1 |
| `pauseSpeech()` | `balabolka_web.html` (fn) | `(): void` — pausa síntese e keep-alive | Fase 1 |
| `reapplySpeechIfPlaying()` | `balabolka_web.html` (fn) | `(): void` — reaplica voz após mudança de rate/pitch/volume durante fala ativa | Fase 1 |
| `showEditHint(show)` | `balabolka_web.html` (fn) | `(show: boolean): void` — mostra/esconde hint flutuante "✏️ Clique no texto..." no modo leitura parada | Fase 1 |
| `clearKeepAlive()` / `startKeepAlive()` | `balabolka_web.html` (fn) | `(): void` — gerencia timer de 5s para evitar cancelamento automático | Fase 1 |
| `skipWhitespaceTokens(tokens, startIdx)` | `balabolka_web.html` (fn) | `(tokens: string[], startIdx: number): number` — avança índice até primeiro token não-whitespace (`/\S/`); usado quando cursor está em linha vazia/whitespace | Fase 2 |
| `findStartToken(text, cursorOffset)` | `balabolka_web.html` (fn) | `(text: string, cursorOffset: number): number` — mapeia offset de caractere para índice de token considerando `\n` como 1 char | Fase 2 |

## Fluxo Principal
1. Usuário digita/abre texto no editor contenteditable
2. Clicar "Ler" → `playSpeech()` captura cursor (`getCursorOffset()`), tokeniza texto original com `\n`, usa `skipWhitespaceTokens` se cursor em whitespace, renderiza spans coloridos (`renderReadingMode` SEM `.active` antecipado), divide em chunks de ~3000 chars
3. `SpeechSynthesisUtterance.onboundary` → `highlightToken(idx)` usando `chunkOffset + e.charIndex` mapeado via `tokenMap` (primeiro `.active` aparece aqui)
4. `onend` → próximo chunk ou `restoreEditorMode()` (preserva spans se algo foi lido, reativa contentEditable)
5. Modo leitura parada (`isInReadingView === true`): clique em token atualiza `lastReadTokenIdx` sem limpar spans; duplo clique ou digitação (`input`) → `clearReadingView()` extrai texto real dos spans, restaura cursor na posição correta

## Invariantes Globais (nunca violar)
1. `remainingText` enviado à API de voz DEVE ser exatamente `allTokens.slice(startIdx).join('')` — nunca remover `\n`
2. `onboundary` DEVE usar `chunkOffset + e.charIndex` para posição absoluta no texto original
3. `tokenMap` DEVE ser construído com a string original (incluindo `\n`), onde `\n` conta como 1 caractere
4. `clearReadingView()` NUNCA deve ser chamada em eventos de `click`/`focus` no editor — APENAS em `input` (digitação) e ações explícitas (trocar aba, fechar, novo)
5. `renderReadingMode` DEVE preservar `scrollTop` e `scrollHeight` (tolerância 1px) — spans devem ser filhos inline do editor, sem `position: absolute/fixed`
6. Modo leitura parada: `editor.contentEditable = 'false'` durante exibição de tokens; `contentEditable = 'true'` ao restaurar
7. `getCursorOffset()` DEVE tratar `<br>` como 1 caractere (`\n`) e elementos de bloco (div, p, li, h1-6, blockquote, pre) com `\n` implícito entre siblings
8. `renderReadingMode` NUNCA deve aplicar `.active` no token de início — o primeiro highlight deve vir exclusivamente do `onboundary` → `highlightToken` (Bug 1)
9. `skipWhitespaceTokens` DEVE ser usado quando `findStartToken` retorna índice de whitespace — cursor em linha vazia avança para próximo token com `\S` (Bug 2)
10. `clearReadingView` DEVE extrair o texto real dos spans via `.textContent` antes de limpar `innerHTML`, e restaurar o cursor via tree-walk usando `lastReadTokenIdx` como referência (Bug 3)

## Restrições Técnicas Ativas
- Chunk size máximo: 3000 caracteres por utterance
- Keep-alive timer: 5 segundos (pause/resume para evitar cancelamento do Chrome/Edge)
- Tolerância de scrollHeight: 1px entre texto puro e spans
- Vozes: apenas nativas do navegador (Web Speech API) — Chrome/Edge obrigatório
- Editor usa `white-space: pre-wrap` para preservar quebras de linha visuais
- localStorage como única persistência (sem backend)

## Testes Obrigatórios
| Suite | Arquivo | Cobertura Aproximada | Comando |
|-------|---------|----------------------|---------|
| Highlight | `tests/highlight.spec.js` | 8 testes (Persistência, Scroll, Edição limpa realce, Precisão quebra de linha, Retomada por clique, Bug 3 — Edição não reseta texto, Bug 2 — Cursor linha vazia, Bug 1 — Realce prematuro) | `npx playwright test tests/highlight.spec.js` |

## Dependências Externas
| Pacote | Versão | Motivo |
|--------|--------|--------|
| `@playwright/test` | latest | Testes automatizados (mock de SpeechSynthesis, Chromium headless) |
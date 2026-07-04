# Resumo da Fase 2 — Correção de 3 Bugs de Sincronização + Testes de Regressão
> Data: 04/07/2026

## Objetivo
Corrigir 3 bugs críticos de sincronização visual-áudio identificados no comparativo entre Balabolka Desktop (benchmark) e Balabolka Web: (1) realce prematuro de texto não lido, (2) cursor em linha vazia não pulava para próximo token, (3) edição no modo leitura parada resetava texto para o início. Adicionar 3 testes Playwright de regressão sem modificar os 5 testes existentes da Fase 1.

## Entregáveis
- `balabolka_web.html` (modificado) — 3 correções: `renderReadingMode` sem `.active` antecipado, `skipWhitespaceTokens` integrado em `playSpeech`, `clearReadingView` reescrita para extrair texto dos spans e restaurar cursor
- `balabolka_web.html` (novos módulos) — `skipWhitespaceTokens(tokens, startIdx)`, `findStartToken(text, cursorOffset)`
- `dev/tests/highlight.spec.js` (modificado) — 3 novos testes: Bug 3 (edição não reseta), Bug 2 (linha vazia), Bug 1 (verificação síncrona); teste "Edição (input) limpa o realce" corrigido para timing robusto
- `docs/CURRENT_STATE.md` (reescrito) — 10 invariantes, 8 testes, 19 módulos
- `docs/DECISION_LOG.md` (atualizado) — 10 entradas Fase 2
- `docs/BACKLOG_FUTURO.md` (atualizado) — Onda 2 adicionada com 9 itens concluídos + CONTRATOS_DA_ONDA
- `docs/.ai-context` (atualizado) — Fase 2 refletida, próximos módulos
- `docs/.humano` (atualizado) — Fase 2 adicionada ao histórico
- `docs/phase_2_resumo.md` (criado) — este arquivo

## Principais Decisões
- `renderReadingMode` NUNCA aplica `.active` antecipado — primeiro highlight exclusivamente via `onboundary` → `highlightToken`
- `skipWhitespaceTokens` avança até `/\S/` quando cursor em whitespace (linha vazia/espaços)
- `clearReadingView` extrai texto real dos spans via `.textContent` antes de limpar `innerHTML` — evita perda de estado
- `lastReadTokenIdx` usado como referência para restaurar cursor (não `currentTokenIdx`)
- Teste Bug 1 usa verificação síncrona (`window.__activeCountImmediatelyAfterPlay`) para eliminar race condition com mock

## Testes
- Total: 8
- Passando: 8/8 (5 Fase 1 + 3 Fase 2)
- Comando: `npx playwright test tests/highlight.spec.js`

## Riscos Conhecidos
- Mock de `speechSynthesis` pode divergir do comportamento real do Chrome/Edge em edge cases de timing
- Tree-walk de cursor em `clearReadingView` depende de `brCount` e `nodeLength` — verificar com textos multi-parágrafo complexos
- `skipWhitespaceTokens` pode avançar além do último token se texto inteiro for whitespace — truncado em `Math.min(startIdx, tokens.length - 1)`

## Próxima Fase
- Fase 3 — a definir pelo usuário
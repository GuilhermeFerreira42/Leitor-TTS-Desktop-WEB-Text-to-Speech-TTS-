# BACKLOG ESTRATÉGICO — Balabolka Web

## Intenção Original
- **Objetivo:** Leitor de texto em voz alta (TTS) para navegador, inspirado no Balabolka, com realce sincronizado palavra-por-palavra, suporte a múltiplas abas, markdown, e operação 100% offline.
- **Estado Atual:** Após Fase 2 — Cinco bugs críticos corrigidos (Bug A, B da Fase 1 + Bug 1, 2, 3 da Fase 2), suíte de testes automatizados com 8 testes passando, documentação viva atualizada.
- **Meta Final:** Aplicação web completa e robusta, com todos os bugs de sincronização eliminados, cobertura de testes abrangente, e documentação auto-suficiente para qualquer IA ou desenvolvedor retomar o projeto.

---

## Onda 1 — Correção de Bugs Críticos + Testes
> Pré-requisito: Fase 0 (planejamento/projeto inicial)

### Itens

| ID | Entregável | Descrição (entregue ou planejada) | Arquivos Impactados | Critério de Aceite | Status |
|----|------------|-----------------------------------|----------------------|---------------------|--------|
| W1-01 | Correção Bug A: Persistência do realce | `clearReadingView()` removida do handler `click` do editor; agora só chamada no evento `input` (digitação). Clique em token no modo leitura parada apenas atualiza `lastReadTokenIdx` sem limpar spans. Adicionado `dblclick` como atalho para edição, e hint flutuante `showEditHint`. | `balabolka_web.html` | Teste "Persistência ao clicar fora do token (Bug A)" passa consistentemente | CONCLUÍDO |
| W1-02 | Correção Bug B: Precisão com quebras de linha | `remainingText` usa `allTokens.slice(startIdx).join('')` preservando `\n`. `onboundary` usa `chunkOffset + e.charIndex`. `tokenMap` construído com string original. Corrigido `cursorOffset` na retomada (usa `getCursorOffset()`), `.join()` em string no `reapplySpeechIfPlaying`, e `contentEditable` no `restoreEditorMode`. | `balabolka_web.html` | Teste "Precisão com quebra de linha (Bug B)" passa consistentemente | CONCLUÍDO |
| W1-03 | Teste automatizado: Persistência (Bug A) | Preenche editor com "Olá mundo.", clica Ler, espera `.token.active`, clica fora de token, verifica que tokens ainda existem. | `tests/highlight.spec.js` | Passa em todas as execuções | CONCLUÍDO |
| W1-04 | Teste automatizado: Scroll não afetado | Insere 100 linhas, rola ao meio, mede `scrollHeight` antes/depois de aplicar spans. | `tests/highlight.spec.js` | `scrollHeight` não varia mais que 1px | CONCLUÍDO |
| W1-05 | Teste automatizado: Edição limpa realce | Lê texto, espera spans, digita "x" no editor. | `tests/highlight.spec.js` | `innerHTML` do editor não contém `.token` | CONCLUÍDO |
| W1-06 | Teste automatizado: Precisão quebra de linha (Bug B) | Insere "Primeira linha\nSegunda linha", posiciona cursor após `\n`, clica Ler, verifica que `.token.active` contém "Segunda". | `tests/highlight.spec.js` | `.active` textContent contém "Segunda", não "Primeira" | CONCLUÍDO |
| W1-07 | Teste automatizado: Retomada por clique | Lê 10 palavras, espera onend, clica no 5º token ("cinco"), clica Ler novamente. | `tests/highlight.spec.js` | Último `utterance.text` começa com "cinco" | CONCLUÍDO |
| W1-08 | Infraestrutura de testes | Playwright instalado, configurado para Chromium, mock de `speechSynthesis` via `addInitScript`. | `package.json`, `playwright.config.js` | `npx playwright test` executa sem erros de configuração | CONCLUÍDO |
| W1-09 | Documentação viva (CURRENT_STATE, DECISION_LOG, BACKLOG, ARCHIVING_PROTOCOL, .ai-context, .humano) | Protocolo de Arquivamento Progressivo v2.0 executado — 6 artefatos criados. | `docs/CURRENT_STATE.md`, `docs/DECISION_LOG.md`, `docs/BACKLOG_FUTURO.md`, `docs/ARCHIVING_PROTOCOL.md`, `.ai-context`, `.humano` | Todos os 6 artefatos existem e seguem a estrutura do protocolo | CONCLUÍDO |

### Meta da Onda 1
- **Critério binário:** 5/5 testes Playwright passam consistentemente + documentação viva completa
- **Status:** CONCLUÍDO

### CONTRATOS_DA_ONDA 1
```
OUTPUT_SCHEMAS:
  W1-01: Editor contenteditable com spans .token inline, scrollHeight preservado, clearReadingView() só em input/dblclick
  W1-02: tokenMap com string original (inclui \n), onboundary com chunkOffset + e.charIndex, remainingText = tokens.slice.join('')
  W1-03: Teste Playwright — mock speechSynthesis, asserção de persistência de tokens após clique fora
  W1-04: Teste Playwright — 100 linhas, scrollHeight antes/depois com tolerância 1px
  W1-05: Teste Playwright — verificação de ausência de .token após input
  W1-06: Teste Playwright — tree-walk para posicionar cursor após \n, asserção de .active contendo palavra correta
  W1-07: Teste Playwright — mock onend preserva tokens, clique em token[idx], verificação de utterance.text
  W1-08: package.json com @playwright/test, playwright.config.js com Chromium, mock em addInitScript
  W1-09: 6 arquivos do Protocolo v2.0 — CURRENT_STATE (≤1800 tokens), DECISION_LOG (5-15 linhas/fase), BACKLOG_FUTURO (com CONTRATOS_DA_ONDA), ARCHIVING_PROTOCOL (11 passos), .ai-context, .humano

ESCOPO_CONGELADO:
  - Nenhum arquivo fora de balabolka_web.html, tests/, docs/, package.json, playwright.config.js, .ai-context, .humano

ARQUIVOS_A_DELETAR:
  - Nenhum

REESCRITAS:
  - playSpeech(): INCREMENTAL — correção de remainingText, onboundary, tokenMap
  - reapplySpeechIfPlaying(): INCREMENTAL — correção de .join() e tokenMap
  - restoreEditorMode(): INCREMENTAL — adição de contentEditable='true'
  - renderReadingMode(): INCREMENTAL — preservação de scrollTop
  - Editor click handler: TOTAL — reescrito para lógica de modo leitura parada

SPECIALISTS_MVP:
  - Nenhum (projeto monolito sem especialistas)

DECISOES_EXTRAS:
  - Mock de speechSynthesis usa setTimeout encadeados (5ms, 10ms, 20ms) para simular eventos assíncronos
  - Testes usam window.playSpeech() diretamente em vez de click no botão para evitar problemas de seletor
  - Tolerância de scrollHeight: 1px (diferenças de subpixel rendering entre navegadores)
```

---

## Onda 2 — Correção de Bugs de Sincronização Avançados + Testes de Regressão
> Pré-requisito: Onda 1 concluída

### Itens

| ID | Entregável | Descrição (entregue ou planejada) | Arquivos Impactados | Critério de Aceite | Status |
|----|------------|-----------------------------------|----------------------|---------------------|--------|
| W2-01 | Correção Bug 1: Realce prematuro (dessincronia token) | `renderReadingMode` não aplica mais `.active` no token `startIdx` antecipadamente; primeiro highlight vem exclusivamente do `onboundary` → `highlightToken`. | `balabolka_web.html` | Teste "Bug 1: Realce prematuro - .active NÃO aparece antes do onboundary" passa (verificação síncrona) | CONCLUÍDO |
| W2-02 | Correção Bug 2: Cursor em linha vazia (indexação offset) | Adicionada `skipWhitespaceTokens(tokens, startIdx)` que avança até `/\S/`; integrada em ambos branches de `playSpeech` (retomada e início normal). | `balabolka_web.html` | Teste "Bug 2: Cursor em linha vazia pula para próximo token não-whitespace" passa (.active não é whitespace) | CONCLUÍDO |
| W2-03 | Correção Bug 3: Texto escrito no início (persistência estado) | `clearReadingView()` reescrita: extrai texto real dos spans via `.textContent` antes de limpar, calcula `cursorCharOffset` via `lastReadTokenIdx`, restaura cursor via tree-walk, atualiza `state.texts[]`. | `balabolka_web.html` | Teste "Bug 3: Edição no modo leitura NÃO reseta o texto para o início" passa (texto preservado + cursor correto) | CONCLUÍDO |
| W2-04 | Módulo `skipWhitespaceTokens` | Nova função utilitária: avança índice até primeiro token não-whitespace (`/\S/`). | `balabolka_web.html` | Usada por `playSpeech` em ambos branches | CONCLUÍDO |
| W2-05 | Módulo `findStartToken` | Nova função utilitária: mapeia offset de caractere para índice de token (extraído da lógica inline de `playSpeech`). | `balabolka_web.html` | Usada por `playSpeech`; testável isoladamente | CONCLUÍDO |
| W2-06 | Teste automatizado: Bug 3 — Edição não reseta texto | Lê texto, aguarda onend (modo leitura parada), simula keydown+input, verifica texto preservado + cursor na posição + tokens removidos. | `tests/highlight.spec.js` | 3 asserções: texto contém 'X', contém 'Primeira', sem spans .token | CONCLUÍDO |
| W2-07 | Teste automatizado: Bug 2 — Cursor linha vazia pula whitespace | Texto com `\n\n`, posiciona cursor na linha vazia, clica Ler, verifica `.active` não é whitespace e contém "Linha". | `tests/highlight.spec.js` | `.active` textContent não match `^\s+$` e contém "Linha" | CONCLUÍDO |
| W2-08 | Teste automatizado: Bug 1 — Realce prematuro | Verificação síncrona pós-`playSpeech`: 0 `.active`; após `onboundary` mock: 1 `.active` com "Primeira". | `tests/highlight.spec.js` | Sem race condition; valida estado exato | CONCLUÍDO |
| W2-09 | Atualização documentação viva (Fase 2) | CURRENT_STATE (10 invariantes, 8 testes, 2 novos módulos), DECISION_LOG (10 linhas Fase 2), BACKLOG_FUTURO (itens W2), .ai-context, .humano, phase_2_resumo.md | `docs/CURRENT_STATE.md`, `docs/DECISION_LOG.md`, `docs/BACKLOG_FUTURO.md`, `.ai-context`, `.humano`, `docs/phase_2_resumo.md` | Todos artefatos atualizados; testes 8/8 passando | CONCLUÍDO |

### Meta da Onda 2
- **Critério binário:** 8/8 testes Playwright passam consistentemente (5 Fase 1 + 3 Fase 2) + documentação viva atualizada
- **Status:** CONCLUÍDO

### CONTRATOS_DA_ONDA 2
```
OUTPUT_SCHEMAS:
  W2-01: renderReadingMode() SEM .active em startIdx; highlightToken() via onboundary é fonte única de .active
  W2-02: skipWhitespaceTokens(tokens, idx) -> number; playSpeech() chama em ambos branches após findStartToken
  W2-03: clearReadingView() extrai texto via spans.textContent, calcula offset via lastReadTokenIdx, restaura cursor via tree-walk
  W2-04: skipWhitespaceTokens: itera tokens a partir de idx enquanto !/\S/.test(token); retorna novo idx
  W2-05: findStartToken(text, offset): usa tokenMap lógica para mapear char offset -> token index
  W2-06: Teste Playwright — mock onend preserva tokens, keydown+input, 3 asserções (texto, cursor, sem tokens)
  W2-07: Teste Playwright — tree-walk posiciona cursor em \n\n, playSpeech, asserção .active não whitespace
  W2-08: Teste Playwright — verificação síncrona via window.__activeCountImmediatelyAfterPlay; 0 antes, 1 após boundary
  W2-09: CURRENT_STATE: 10 invariantes, 8 testes, 19 módulos; DECISION_LOG: 10 linhas F2; .ai-context/.humano atualizados

ESCOPO_CONGELADO:
  - Nenhum arquivo fora de balabolka_web.html, tests/, docs/, .ai-context, .humano

ARQUIVOS_A_DELETAR:
  - Nenhum

REESCRITAS:
  - renderReadingMode(): INCREMENTAL — remoção de .active antecipado; preservação scrollTop/scrollHeight mantida
  - clearReadingView(): TOTAL — reescrita completa para extrair texto dos spans, restaurar cursor via lastReadTokenIdx
  - playSpeech(): INCREMENTAL — integração skipWhitespaceTokens em ambos branches; extração de findStartToken
  - (Novos) skipWhitespaceTokens(), findStartToken(): TOTAL — criados

SPECIALISTS_MVP:
  - Nenhum (projeto monolito sem especialistas)

DECISOES_EXTRAS:
  - Teste Bug 1 usa verificação síncrona (window.__activeCountImmediatelyAfterPlay) para evitar race condition mock 5ms vs 10ms
  - clearReadingView usa lastReadTokenIdx (não currentTokenIdx) como referência pois modo leitura parada preserva posição onde usuário clicou
  - Invariant 8: renderReadingMode NUNCA aplica .active antecipado
  - Invariant 9: skipWhitespaceTokens obrigatório quando findStartToken retorna whitespace
  - Invariant 10: clearReadingView extrai texto dos spans ANTES de limpar innerHTML
```

---

## Regras do Backlog
1. Itens movem de `PENDENTE` para `CONCLUÍDO` apenas após validação com critério binário
2. Nenhuma Onda inicia sem a anterior concluída
3. Novas técnicas descobertas durante implementação são adicionadas como item novo na Onda apropriada
4. `CONTRATOS_DA_ONDA` deve estar confirmado pelo usuário antes de disparar a execução — nunca durante
5. A IA propõe o `CONTRATOS_DA_ONDA` — o usuário valida
6. Campos que o usuário confirmar sem alteração são tratados como fatos — não serão questionados
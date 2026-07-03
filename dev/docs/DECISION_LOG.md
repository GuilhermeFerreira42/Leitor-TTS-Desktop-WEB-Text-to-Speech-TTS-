# DECISION_LOG — Balabolka Web

## Formato
`[FASE] | [TIPO] | [DECISÃO] | [MOTIVO] | [ARQUIVOS IMPACTADOS]`

Tipos: ADD, MOD, DEL, FREEZE, RULE, CFG, FIX, TECH

---

### Fase 0 — Planejamento
F0 | ADD | Projeto como monolito HTML autocontido (HTML+CSS+JS inline) | Elimina necessidade de Node.js, bundler ou build; compatível com abertura direta no navegador | balabolka_web.html
F0 | TECH | Web Speech API como motor TTS | Única API nativa de síntese de voz disponível em navegadores; funciona offline no Chrome/Edge | balabolka_web.html
F0 | TECH | localStorage como persistência | Sem backend; dados de abas, voz, cores e fonte persistem entre sessões | balabolka_web.html
F0 | RULE | Editor contenteditable com `white-space: pre-wrap` | Preserva quebras de linha visuais sem depender de `<br>` explícitos | balabolka_web.html
F0 | TECH | Chunking de texto em ~3000 caracteres por utterance | Chrome/Edge cancelam utterances muito longas; chunking com keep-alive timer garante leitura contínua | balabolka_web.html
F0 | TECH | Tokenização via `split(/(\s+)/)` para realce sincronizado | Preserva espaços e quebras como tokens separados, permitindo mapeamento preciso entre offset de caractere e posição visual | balabolka_web.html
F0 | TECH | Sistema de abas interno com estado via `state.tabs` e `state.texts` | Interface multi-documento sem depender de múltiplos arquivos ou iframes | balabolka_web.html
F0 | CFG | Keep-alive timer: 5 segundos | Intervalo seguro que evita cancelamento automático sem sobrecarregar o motor de síntese | balabolka_web.html
F0 | FREEZE | Interface pública: `playSpeech()`, `stopSpeech()`, `pauseSpeech()` | Contratos estáveis para controles de UI e hotkeys (F5, F6, Esc) | balabolka_web.html

### Fase 1 — Correção de Bugs Críticos + Testes Automatizados
F1 | FIX | Bug A: `clearReadingView()` chamada indevidamente no `click` do editor — removida; clique em token só atualiza `lastReadTokenIdx` | O clique no editor apagava os spans coloridos; agora só entra em modo edição ao digitar (`input`) ou duplo clique | balabolka_web.html
F1 | FIX | Bug B: `remainingText` removia `\n` ao usar `.replace(/\n/g, ' ')` — corrigido para `allTokens.slice(startIdx).join('')` preservando quebras | Dessincronia entre áudio e cor em textos com quebras de linha; agora `tokenMap` usa string original com `\n` contando como 1 char | balabolka_web.html
F1 | FIX | Bug B: `onboundary` usava apenas `e.charIndex` sem offset do chunk — corrigido para `chunkOffset + e.charIndex` | Em textos com múltiplos chunks, o realce apontava para posição errada após o primeiro chunk | balabolka_web.html
F1 | FIX | `cursorOffset` na branch de retomada calculado sobre innerHTML tokenizado — corrigido para usar `getCursorOffset()` sobre texto original | Ao retomar leitura pós-pausa, o offset do cursor era calculado sobre os spans, não sobre o texto plano | balabolka_web.html
F1 | FIX | `reapplySpeechIfPlaying()` chamava `.join('')` em string (não array) — corrigido para preservar compatibilidade com a branch de retomada | Erro silencioso ao mudar rate/pitch/volume durante fala ativa após retomada | balabolka_web.html
F1 | FIX | `restoreEditorMode()` não restaurava `contentEditable='true'` — corrigido; agora reativa edição após fala terminar | Editor ficava bloqueado após leitura, exigindo recarregar a página | balabolka_web.html
F1 | FIX | `renderReadingMode` sobrescrevia `scrollTop` durante `scrollIntoView` — corrigido para preservar `scrollTop` e `scrollHeight` originais | Scroll do usuário saltava ao iniciar leitura em textos longos | balabolka_web.html
F1 | MOD | Adicionado handler `dblclick` no editor para entrar em modo edição a partir do modo leitura parada | Atalho adicional; duplo clique = editar (além de digitar) | balabolka_web.html
F1 | ADD | Função `showEditHint(show)` para hint flutuante "✏️ Clique no texto..." | Feedback visual quando editor está em modo leitura parada com tokens coloridos | balabolka_web.html
F1 | TECH | Playwright como framework de teste | Suporte nativo a Chromium, injeção de scripts (`addInitScript`), mock de APIs do navegador | package.json, playwright.config.js, tests/highlight.spec.js
F1 | TECH | Mock de `window.speechSynthesis` via `page.addInitScript` | Testes rodam em ms sem áudio real; mock dispara `onboundary`/`onend` sintéticos | tests/highlight.spec.js
F1 | ADD | 5 testes automatizados: Persistência (Bug A), Scroll, Edição limpa realce, Precisão quebra de linha (Bug B), Retomada por clique | Cobertura dos dois bugs críticos + invariantes de scroll; regressão zero garantida | tests/highlight.spec.js
F1 | FREEZE | Invariantes globais documentados em CURRENT_STATE.md (7 regras) | Qualquer modificação futura deve respeitar essas regras; testes validam cada uma | docs/CURRENT_STATE.md
F1 | CFG | Tolerância de scrollHeight: 1px | Margem para diferenças de renderização entre texto puro e spans inline; validado pelo teste de Scroll | balabolka_web.html, tests/highlight.spec.js
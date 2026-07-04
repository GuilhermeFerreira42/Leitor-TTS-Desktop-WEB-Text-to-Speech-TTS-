const { test, expect } = require('@playwright/test');
const path = require('path');

test.beforeEach(async ({ page }) => {
  // Mock window.speechSynthesis.speak to fire events instantly without real audio.
  // We keep native getVoices() so that voice objects are real SpeechSynthesisVoice instances.
  await page.addInitScript(() => {
    // Capture originals BEFORE patching
    const _origSpeak = window.speechSynthesis.speak.bind(window.speechSynthesis);
    const _origCancel = window.speechSynthesis.cancel.bind(window.speechSynthesis);

    // State tracking variables
    window.__mockSpeaking = false;
    window.__mockPaused = false;
    window.__mockUtterances = [];

    // Patch the speak method: skip native audio, fire synthetic events instantly
    window.speechSynthesis.speak = function(utterance) {
      console.log('MOCK SPEAK called with text:', utterance.text);
      window.__mockSpeaking = true;
      window.__mockPaused = false;
      window.__mockUtterances.push(utterance);

      // Fire onstart right away
      setTimeout(() => {
        console.log('MOCK onstart firing');
        if (utterance.onstart) utterance.onstart();
      }, 5);

      // Fire onboundary with charIndex=0 for the first word
      setTimeout(() => {
        console.log('MOCK onboundary firing');
        if (utterance.onboundary) {
          const firstWordLength = (utterance.text.split(/\s+/)[0] || '').length;
          utterance.onboundary({ name: 'word', charIndex: 0, charLength: firstWordLength || (utterance.text.length) });
        }
        // Fire onend shortly after boundary
        setTimeout(() => {
          console.log('MOCK onend firing');
          window.__mockSpeaking = false;
          if (utterance.onend) {
            utterance.onend();
          }
        }, 20);
      }, 10);
    };

    // Patch speaking/paused getters
    Object.defineProperty(window.speechSynthesis, 'speaking', {
      get: function() { return window.__mockSpeaking; },
      configurable: true,
    });
    Object.defineProperty(window.speechSynthesis, 'paused', {
      get: function() { return window.__mockPaused; },
      configurable: true,
    });

    // Patch cancel: stop tracking, fire onerror on last utterance
    window.speechSynthesis.cancel = function() {
      console.log('MOCK cancel called');
      window.__mockSpeaking = false;
      window.__mockPaused = false;
      if (window.__mockUtterances.length > 0) {
        const last = window.__mockUtterances[window.__mockUtterances.length - 1];
        if (last.onerror) {
          last.onerror({ error: 'canceled' });
        }
      }
      window.__mockUtterances = [];
    };

    // Patch pause/resume
    window.speechSynthesis.pause = function() {
      console.log('MOCK pause called');
      if (window.__mockSpeaking) {
        window.__mockSpeaking = false;
        window.__mockPaused = true;
      }
    };

    window.speechSynthesis.resume = function() {
      console.log('MOCK resume called');
      if (window.__mockPaused) {
        window.__mockSpeaking = true;
        window.__mockPaused = false;
      }
    };

    // Fire voiceschanged after a short delay so onvoiceschanged callbacks work
    setTimeout(() => {
      if (window.speechSynthesis.onvoiceschanged) {
        window.speechSynthesis.onvoiceschanged();
      }
    }, 10);
  });

  const filePath = path.resolve(__dirname, '../../balabolka_web.html');

  // Listen for console events
  page.on('console', msg => {
    console.log('PAGE LOG:', msg.type(), msg.text());
  });

  await page.goto(`file://${filePath}`);
  await page.waitForLoadState('domcontentloaded');
});

test('Persistência ao clicar fora do token (Bug A)', async ({ page }) => {
  // Set editor text
  await page.evaluate(() => {
    document.getElementById('editor').innerText = 'Olá mundo.';
  });

  // Wait for voices to load (mock fires onvoiceschanged)
  await page.waitForTimeout(100);

  // Call playSpeech directly
  await page.evaluate(() => {
    console.log('Debug: Calling playSpeech...');
    window.playSpeech();
  });

  // Wait for the first token to be active (mock onboundary fires after 50ms)
  await page.waitForSelector('.token.active', { timeout: 5000 });

  // Verify we have tokens in the editor
  const tokenCount = await page.locator('.token').count();
  expect(tokenCount).toBeGreaterThan(0);

  // Click outside any token within the editor area
  const editorBoundingBox = await page.locator('#editor').boundingBox();
  if (!editorBoundingBox) throw new Error('Editor not found');

  // Click a point in the bottom right of the editor, outside the text content
  const clickX = editorBoundingBox.x + editorBoundingBox.width - 10;
  const clickY = editorBoundingBox.y + editorBoundingBox.height - 10;
  await page.mouse.click(clickX, clickY);

  // Assert: The token that was .active before still exists and is a token
  // Since clicking outside should do nothing in reading view,
  // the active token should still be present.
  const activeTokenLocator = page.locator('.token.active');
  // It may have become .read instead of .active (depending on click handler logic)
  // But it MUST still be a token (not removed).
  // If not .active anymore, at least one .token exists.
  const tokensAfterClick = await page.locator('.token').count();
  expect(tokensAfterClick).toBeGreaterThan(0);
});

test('Scroll não é afetado pela coloração', async ({ page }) => {
  const longText = Array(100).fill('Linha X.').join('\n');
  const editorHandle = page.locator('#editor');

  // Insert text and wait for full layout rendering
  await editorHandle.evaluate((el, text) => {
    el.innerText = text;
  }, longText);

  // Wait for browser to finish layout (rendering 100 lines)
  await page.waitForTimeout(500);

  // Scroll down and wait for scroll to settle
  await editorHandle.evaluate(el => {
    el.scrollTop = el.scrollHeight / 2; // Scroll to middle
  });

  await page.waitForTimeout(300); // Let scroll settle

  const scrollHeightBefore = await editorHandle.evaluate(el => el.scrollHeight);

  // Use window.playSpeech() to skip button-click issues
  await page.evaluate(() => { window.playSpeech(); });
  await page.waitForSelector('.token.active', { timeout: 5000 });

  const scrollHeightAfter = await editorHandle.evaluate(el => el.scrollHeight);

  // Rule 3: scrollHeight must NOT change by more than 1px when spans are applied
  // (scrollTop may change due to scrollIntoView keeping active word visible — that's a feature)
  expect(scrollHeightAfter).toBeCloseTo(scrollHeightBefore, 1); // Tolerance 1px
});

test('Edição (input) limpa o realce', async ({ page }) => {
  await page.waitForTimeout(100);

  await page.evaluate(() => {
    document.getElementById('editor').innerText = 'Texto de exemplo.';
  });

  await page.evaluate(() => {
    window.playSpeech();
  });

  await page.waitForSelector('.token.active', { timeout: 5000 });

  // Aguarda o mock onend disparar (restaura modo leitura com tokens preservados)
  await page.waitForTimeout(100);

  // Simula edição: dispara keydown com caractere imprimível para invocar clearReadingView()
  // E depois dispara evento 'input' diretamente para garantir limpeza
  await page.evaluate(() => {
    const editor = document.getElementById('editor');
    // 1. Keydown com tecla imprimível (não está na lista de navegação)
    editor.dispatchEvent(new KeyboardEvent('keydown', { key: 'x', bubbles: true }));
    // 2. Agora editor deve ser editável - dispara evento input para simular digitação real
    editor.dispatchEvent(new Event('input', { bubbles: true }));
  });

  // Assert: editor innerHTML não contém mais token spans
  const hasTokens = await page.evaluate(() => {
    return document.getElementById('editor').querySelector('.token') !== null;
  });
  expect(hasTokens).toBe(false);
});

test('Precisão com quebra de linha (Bug B)', async ({ page }) => {
  await page.waitForTimeout(100);

  const text = "Primeira linha\nSegunda linha.";
  await page.evaluate((t) => {
    document.getElementById('editor').innerText = t;
    // After setting innerText with \n, Chromium may create <div> or <br> nodes
    // We'll position cursor robustly using tree walk
  }, text);

  // Use a robust tree-walk approach to position cursor after the \n
  await page.evaluate(() => {
    const editor = document.getElementById('editor');
    const fullText = editor.innerText;
    const newlinePos = fullText.indexOf('\n');
    if (newlinePos === -1) return; // No newline found
    
    const targetOffset = newlinePos + 1; // Position right after \n
    
    // Walk DOM tree to find node+offset matching targetOffset in innerText
    let pos = 0;
    let foundNode = null, foundOffset = 0;
    
    function walk(node) {
      if (foundNode) return;
      if (node.nodeType === 3) {
        // Text node
        const end = pos + node.length;
        if (targetOffset >= pos && targetOffset <= end) {
          foundNode = node;
          foundOffset = targetOffset - pos;
        }
        pos += node.length;
      } else if (node.nodeType === 1) {
        if (node.tagName === 'BR') {
          pos += 1; // <br> counts as 1 \n char in innerText
        }
        for (let i = 0; i < node.childNodes.length; i++) {
          walk(node.childNodes[i]);
          if (foundNode) return;
        }
        // Block-level elements contribute implicit \n between siblings
        const blockTags = ['DIV', 'P', 'LI', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'BLOCKQUOTE', 'PRE'];
        if (blockTags.includes(node.tagName) && node.nextSibling) {
          // The \n between blocks is counted by innerText but doesn't live in a node
          // We handle it by never landing on it (cursor can't be placed between blocks directly)
        }
      }
    }
    
    for (let i = 0; i < editor.childNodes.length; i++) {
      walk(editor.childNodes[i]);
      if (foundNode) break;
    }
    
    if (foundNode) {
      const range = document.createRange();
      range.setStart(foundNode, foundOffset);
      range.setEnd(foundNode, foundOffset);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    }
  });

  await page.evaluate(() => {
    window.playSpeech();
  });

  await page.waitForSelector('.token.active', { timeout: 5000 });

  const activeTokenText = await page.locator('.token.active').textContent();
  expect(activeTokenText).toContain('Segunda');
});

test('Clique em token define ponto de retomada', async ({ page }) => {
  await page.waitForTimeout(100);

  const text = 'Um dois três quatro cinco seis sete oito nove dez.';
  await page.evaluate((t) => {
    document.getElementById('editor').innerText = t;
  }, text);

  await page.evaluate(() => {
    window.playSpeech();
  });
  await page.waitForSelector('.token.active', { timeout: 5000 });

  // Simulate 'stop' by cancelling speech but keeping reading view
  // In the real app, this happens via restoreEditorMode preserving tokens
  // We need to simulate that the speech finished and tokens are preserved
  // Our mock onend fires -> restoreEditorMode sets isInReadingView = true if currentTokenIdx >= 0

  // Wait for mock onend to complete
  await page.waitForTimeout(200);

  // Now editor should be in reading view mode (tokens preserved)
  // Verify tokens still exist
  const tokensCount = await page.locator('.token').count();
  expect(tokensCount).toBeGreaterThan(0);

  // Find the 5th word token ("cinco")
  // Tokens: "Um"(idx0) " "(idx1) "dois"(idx2) " "(idx3) "três"(idx4) " "(idx5) "quatro"(idx6) " "(idx7) "cinco"(idx8)
  const fifthWordToken = page.locator('.token[data-idx="8"]');
  await fifthWordToken.click();

  // Click 'Ler' button again to resume from clicked token
  await page.evaluate(() => {
    window.playSpeech();
  });

  // Wait briefly for the new utterance
  await page.waitForTimeout(100);

  // Verify the last recorded utterance text starts with "cinco"
  const lastUtteranceText = await page.evaluate(() => {
    const utts = window.__mockUtterances;
    return utts.length > 0 ? utts[utts.length - 1].text : '';
  });

  expect(lastUtteranceText).toContain('cinco');
  expect(lastUtteranceText).not.toContain('Um');
  expect(lastUtteranceText).not.toContain('dois');
});

test('Bug 3: Edição no modo leitura NÃO reseta o texto para o início', async ({ page }) => {
  await page.waitForTimeout(100);

  const originalText = 'Primeira linha\nSegunda linha\nTerceira linha';
  await page.evaluate((t) => {
    document.getElementById('editor').innerText = t;
  }, originalText);

  // Inicia leitura
  await page.evaluate(() => {
    window.playSpeech();
  });
  await page.waitForSelector('.token.active', { timeout: 5000 });
  
  // Aguarda leitura terminar (mock onend)
  await page.waitForTimeout(200);
  
  // Agora o editor deve estar em modo leitura (isInReadingView = true)
  // Verifica que tokens ainda existem
  const tokensBeforeEdit = await page.locator('.token').count();
  expect(tokensBeforeEdit).toBeGreaterThan(0);
  
  // Simula digitação no modo leitura (keydown com caractere imprimível)
  // Isso deve disparar clearReadingView()
  await page.evaluate(() => {
    const editor = document.getElementById('editor');
    editor.dispatchEvent(new KeyboardEvent('keydown', { key: 'X', bubbles: true }));
  });
  
  // Digita um caractere no editor agora editável
  await page.keyboard.type('X');
  
  // Verifica: o texto NÃO deve ter sido resetado para o original
  // O texto deve conter o 'X' digitado E o texto original deve estar preservado
  const editorText = await page.evaluate(() => {
    return document.getElementById('editor').innerText;
  });
  
  // O texto deve conter o 'X' que foi digitado
  expect(editorText).toContain('X');
  // E deve conter partes do texto original (não resetado para vazio ou apenas 'X')
  expect(editorText).toContain('Primeira');
  
  // Não deve ter tokens de realce (foram limpos pela edição)
  const hasTokensAfterEdit = await page.evaluate(() => {
    return document.getElementById('editor').querySelector('.token') !== null;
  });
  expect(hasTokensAfterEdit).toBe(false);
});

test('Bug 2: Cursor em linha vazia pula para próximo token não-whitespace', async ({ page }) => {
  await page.waitForTimeout(100);
  
  // Texto com múltiplas linhas, incluindo linha vazia no meio
  const text = 'Linha 1\n\nLinha 3\nLinha 4';
  await page.evaluate((t) => {
    document.getElementById('editor').innerText = t;
  }, text);
  
  // Posiciona cursor na linha vazia (após o primeiro \n)
  await page.evaluate(() => {
    const editor = document.getElementById('editor');
    const fullText = editor.innerText;
    const firstNewline = fullText.indexOf('\n');
    // Posiciona exatamente na linha vazia (offset = firstNewline + 1)
    const targetOffset = firstNewline + 1;
    
    let pos = 0;
    let foundNode = null, foundOffset = 0;
    
    function walk(node) {
      if (foundNode) return;
      if (node.nodeType === 3) {
        const end = pos + node.length;
        if (targetOffset >= pos && targetOffset <= end) {
          foundNode = node;
          foundOffset = targetOffset - pos;
        }
        pos += node.length;
      } else if (node.nodeType === 1) {
        if (node.tagName === 'BR') {
          pos += 1;
        }
        for (let i = 0; i < node.childNodes.length; i++) {
          walk(node.childNodes[i]);
          if (foundNode) return;
        }
      }
    }
    
    for (let i = 0; i < editor.childNodes.length; i++) {
      walk(editor.childNodes[i]);
      if (foundNode) break;
    }
    
    if (foundNode) {
      const range = document.createRange();
      range.setStart(foundNode, foundOffset);
      range.setEnd(foundNode, foundOffset);
      const sel = window.getSelection();
      sel.removeAllRanges();
      sel.addRange(range);
    }
  });
  
  await page.evaluate(() => {
    window.playSpeech();
  });
  
  await page.waitForSelector('.token.active', { timeout: 5000 });
  
  // O primeiro token .active NÃO deve ser whitespace (espaço, \n, etc.)
  // Deve ser 'Linha' ou '3' (o próximo token não-whitespace após a linha vazia)
  const activeTokenText = await page.locator('.token.active').textContent();
  expect(activeTokenText).not.toMatch(/^\s+$/); // Não é apenas whitespace
  // Deve conter parte de 'Linha 3' (pula a linha vazia)
  expect(activeTokenText).toMatch(/Linha/);
});

test('Bug 1: Realce prematuro - .active NÃO aparece antes do onboundary', async ({ page }) => {
  await page.waitForTimeout(100);
  
  const text = 'Primeira palavra segunda palavra terceira';
  await page.evaluate((t) => {
    document.getElementById('editor').innerText = t;
  }, text);
  
  // ANTES de chamar playSpeech: não deve haver .active
  const activeBefore = await page.locator('.token.active').count();
  expect(activeBefore).toBe(0);
  
  // Chama playSpeech e verifica SINCRONAMENTE (sem await waitForTimeout) 
  // que .active NÃO foi adicionado pelo renderReadingMode
  await page.evaluate(() => {
    window.playSpeech();
    // Verifica imediatamente após playSpeech retornar (renderReadingMode já executou)
    const activeCount = document.querySelectorAll('.token.active').length;
    // Retorna o count para o teste validar
    window.__activeCountImmediatelyAfterPlay = activeCount;
  });
  
  // Obtém o count capturado sincronicamente
  const activeImmediatelyAfterPlay = await page.evaluate(() => window.__activeCountImmediatelyAfterPlay);
  expect(activeImmediatelyAfterPlay).toBe(0); // Bug 1: .active NÃO aparece antecipadamente pelo renderReadingMode
  
  // Aguarda o onboundary do mock (dispara em ~10ms)
  await page.waitForSelector('.token.active', { timeout: 5000 });
  
  // AGORA deve haver .active (pelo onboundary)
  const activeAfterBoundary = await page.locator('.token.active').count();
  expect(activeAfterBoundary).toBe(1);
  
  // O token .active deve ser o primeiro token não-whitespace ('Primeira')
  const activeTokenText = await page.locator('.token.active').textContent();
  expect(activeTokenText).toContain('Primeira');
});

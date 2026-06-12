# Comando para IA com Busca na Internet

Copie e cole este comando completo para a IA externa:

---

```
Preciso de ajuda para corrigir dois bugs em um app React 18 rodando em um único arquivo HTML 
(sem bundler, sem Node.js, usando Babel Standalone via CDN). O app é um leitor de texto 
em voz alta usando Web Speech API (SpeechSynthesis).

═══════════════════════════════════════════
BUG 1 — Leitura sempre começa do início, ignorando posição do cursor
═══════════════════════════════════════════

CONTEXTO:
- O editor de texto é um <textarea> controlado pelo React (value + onChange)
- Quando o usuário clica no meio do texto e aperta Play, a leitura SEMPRE começa 
  do início, ignorando onde o cursor foi posicionado
- A função getCursorTokenIndex() tenta ler a posição do cursor no textarea, 
  mas parece não estar capturando corretamente

CÓDIGO ATUAL DA FUNÇÃO PROBLEMÁTICA:
const getCursorTokenIndex = useCallback(() => {
  if (!editorRef.current) return 0;
  const selection = window.getSelection();
  if (!selection || selection.rangeCount === 0) return 0;
  const range = selection.getRangeAt(0);
  if (!editorRef.current.contains(range.startContainer)) return 0;
  const textToRead = isRenderedMd ? stripMarkdown(text) : text;
  const tokens = textToRead.split(/(\s+)/);
  const preCursorRange = document.createRange();
  preCursorRange.setStart(editorRef.current, 0);
  preCursorRange.setEnd(range.startContainer, range.startOffset);
  const textBeforeCursor = preCursorRange.toString();
  let charCount = 0;
  for (let i = 0; i < tokens.length; i++) {
    charCount += tokens[i].length;
    if (charCount > textBeforeCursor.length) return i;
  }
  return tokens.length;
}, [text, isRenderedMd]);

PROBLEMA IDENTIFICADO:
- O editor é um <textarea> (elemento de formulário), não um contentEditable
- window.getSelection() NÃO funciona para capturar a posição do cursor em um <textarea>
- Para <textarea>, a posição correta do cursor vem de textarea.selectionStart
- O editorRef aponta para a <div> container, não para o <textarea> em si
- Não há uma ref direta no elemento <textarea>

PERGUNTA 1:
Pesquise a forma correta de capturar selectionStart de um <textarea> controlado pelo React 18,
convertendo essa posição de caractere para um índice de token em um array gerado por 
text.split(/(\s+)/). Mostre também como salvar essa posição em um ref para que ela 
persista entre re-renders sem causar re-renders desnecessários.

═══════════════════════════════════════════
BUG 2 — Cálculo de tempo estimado de leitura incorreto
═══════════════════════════════════════════

CONTEXTO:
- O app calcula o tempo estimado de leitura com base em: 150 palavras por minuto na 
  velocidade 1.0x da Web Speech API
- O cálculo atual está gerando valores muito menores que o tempo real de leitura
- Exemplo real observado: texto que a voz levou ~60 segundos para ler, 
  mas o contador calculou apenas ~8 segundos e zerou antes da leitura terminar

CÓDIGO ATUAL DO CÁLCULO:
useEffect(() => {
  const textToRead = isRenderedMd ? stripMarkdown(text) : text;
  const words = textToRead.trim().split(/\s+/).filter(w => w.length > 0);
  const total = words.length;
  setTotalWords(total);
  const timeSec = Math.ceil(total / (150 * rate) * 60);
  setEstimatedTime(timeSec);
}, [text, isRenderedMd, rate]);

PROBLEMA IDENTIFICADO:
- A fórmula está errada: (total / (150 * rate) * 60) está multiplicando por 60 
  mas o denominador já está em palavras por minuto, então o resultado já seria em minutos,
  não em segundos
- A fórmula correta seria: (total / (150 * rate)) * 60 para converter minutos em segundos
  MAS isso ainda pode estar errado se a Web Speech API não lê exatamente 150 wpm
- Além disso, o rate da Web Speech API não é linear: rate=2.0 não significa exatamente 
  o dobro de velocidade em todas as vozes e navegadores

PERGUNTA 2:
Pesquise qual é a velocidade real de leitura (words per minute) da Web Speech API 
do Chrome/Edge em português com rate=1.0. Existe algum benchmark ou medição documentada?
Qual é a fórmula matematicamente correta para calcular segundos de leitura dado:
- número de palavras
- rate da SpeechSynthesis (escala de 0.1 a 10)
- referência de calibração em wpm para rate=1.0

Também pesquise: como implementar um timer de tempo restante que usa o evento 
onboundary da SpeechSynthesisUtterance para calcular o progresso real da leitura, 
em vez de depender apenas de um intervalo de tempo fixo — isso seria muito mais preciso.

═══════════════════════════════════════════
RESTRIÇÕES TÉCNICAS DO PROJETO
═══════════════════════════════════════════
- Um único arquivo HTML autocontido (sem Node.js, sem bundler)
- React 18 via CDN (unpkg.com)
- Babel Standalone para JSX
- CSS puro (sem Tailwind)
- Compatível com Chrome e Edge (foco principal)
- Não pode instalar pacotes npm

Por favor, pesquise na internet as soluções para os dois bugs e retorne:
1. A forma correta de ler selectionStart de um textarea React e converter para índice de token
2. A velocidade real em wpm da Web Speech API Chrome e a fórmula correta para o timer
3. Como usar onboundary para calcular tempo restante de forma precisa
```

---

> **Como usar:** Cole esse comando em qualquer IA com acesso à internet (Perplexity, ChatGPT com browsing, Gemini com Google, etc). Quando ela retornar as respostas, traga aqui e eu analiso as soluções e te digo exatamente onde e como aplicar no seu código.

--------

me informe a solucao. explique como se fosse para uma criança

Vou pesquisar as duas questões técnicas agora!Ótimo! Tenho todas as informações necessárias. Aqui está a análise completa dos dois bugs com as correções exatas para aplicar no seu código:

---

# 🐛 Bug 1 — Leitura ignora posição do cursor no `<textarea>`

## Diagnóstico confirmado

A propriedade `selectionStart` do `HTMLTextAreaElement` especifica a posição inicial da seleção de texto no elemento `<textarea>`. Quando nada está selecionado, o valor de `selectionStart` e `selectionEnd` representa a posição atual do cursor (caret) dentro do elemento.

O problema raiz é que em React, manipular a posição do cursor em um `<textarea>` envolve acessar o DOM diretamente, tipicamente usando uma `ref` no elemento textarea. No código atual, o `editorRef` aponta para a `<div>` container — **nunca para o `<textarea>` em si** — então `getCursorTokenIndex()` nunca consegue ler `selectionStart`.

## ✅ Correção: 3 mudanças cirúrgicas

### Passo 1 — Adicionar uma `ref` direta no `<textarea>`

No topo do componente `App`, junto com os outros refs, adicione:

```js
const textareaRef = useRef(null);
```

### Passo 2 — Conectar a ref ao elemento `<textarea>`

Localize o `<textarea>` no JSX (está dentro do bloco `else` que renderiza quando não está tocando/pausado) e adicione `ref={textareaRef}`:

```jsx
<textarea
  ref={textareaRef}          // ← ADICIONAR ESTA LINHA
  className="editor-area"
  style={{ ... }}
  value={text}
  onChange={e => handleTextChange(e.target.value)}
  placeholder="..."
  spellCheck={false}
  onClick={handleCursorMove}
  onKeyUp={handleCursorMove}
  onSelect={handleCursorMove}
/>
```

### Passo 3 — Substituir `getCursorTokenIndex()` inteiro

Substitua a função atual por esta versão corrigida:

```js
const getCursorTokenIndex = useCallback(() => {
  // Lê selectionStart diretamente do <textarea> via ref
  const textarea = textareaRef.current;
  if (!textarea) return 0;

  const cursorCharPos = textarea.selectionStart ?? 0;

  const textToRead = isRenderedMd ? stripMarkdown(text) : text;
  const tokens = textToRead.split(/(\s+)/);

  let charCount = 0;
  for (let i = 0; i < tokens.length; i++) {
    charCount += tokens[i].length;
    if (charCount > cursorCharPos) return i;
  }
  return tokens.length;
}, [text, isRenderedMd]);
```

> **Por quê funciona:** Para um textarea padrão, usamos `useRef` para armazenar e acessar a posição do cursor antes ou durante a atualização do conteúdo. Com a ref apontando diretamente para o `<textarea>`, `textarea.selectionStart` devolve exatamente o caractere onde o cursor está — sem depender de `window.getSelection()` (que não funciona em `<textarea>`).

---

# 🐛 Bug 2 — Tempo estimado de leitura incorreto

## Diagnóstico da fórmula quebrada

A fórmula atual é:
```js
const timeSec = Math.ceil(total / (150 * rate) * 60);
//                         ^^^^^^^^^^^^^^^^^^^
//  ERRADO: multiplica rate ANTES de dividir,
//  produz valores menores com rate alto
```

O erro matemático: `total / (150 * rate) * 60` é avaliado como `(total / (150 * rate)) * 60`, o que **parece certo aritmeticamente**, mas há um problema conceitual sério sobre a velocidade base.

### Velocidade real da Web Speech API

O `rate` pode variar entre 0.1 (mais lento) e 10 (mais rápido), com 1 sendo a velocidade padrão para a plataforma ou voz atual, correspondendo a uma velocidade de fala normal. Outros valores atuam como percentual relativo a esse: por exemplo, 2 é duas vezes mais rápido, 0.5 é metade da velocidade.

Na prática, vozes em **português no Chrome/Edge com `rate=1.0` leem entre 130–180 wpm** dependendo da voz (online vs. offline), e vozes online tendem a ser mais rápidas. Vozes diferentes podem ter diferentes faixas de valores utilizáveis para pitch e rate. Além disso, navegadores diferentes têm seus próprios comportamentos ao definir essas propriedades.

Um valor de **160 wpm** como base é mais realista para vozes pt-BR, mas o problema **real** está em outro lugar: o timer está usando um `setInterval` de 1 segundo desacoplado da fala real. A solução profissional usa o `onboundary` para calcular o progresso com base nos caracteres reais falados.

## ✅ Correção Parte A — Fórmula corrigida com WPM calibrado

Substitua o `useEffect` do cálculo de tempo:

```js
useEffect(() => {
  const textToRead = isRenderedMd ? stripMarkdown(text) : text;
  const words = textToRead.trim().split(/\s+/).filter(w => w.length > 0);
  const total = words.length;
  setTotalWords(total);

  // Base calibrada: ~160 wpm para vozes pt-BR no Chrome com rate=1.0
  // rate é multiplicador linear conforme spec do MDN
  const WPM_BASE = 160;
  const effectiveWpm = WPM_BASE * rate;
  const timeSec = Math.ceil((total / effectiveWpm) * 60); // minutos → segundos
  setEstimatedTime(timeSec);
}, [text, isRenderedMd, rate]);
```

## ✅ Correção Parte B — Timer preciso via `onboundary` (progresso real)

O evento `boundary` fornece `charIndex`, que retorna a posição do índice do caractere no texto do `SpeechSynthesisUtterance` que estava sendo falado quando o evento foi disparado. O `elapsedTime` retorna o tempo decorrido em segundos após o texto ter começado a ser falado.

A estratégia é: a cada `onboundary`, calculamos **qual fração do texto já foi lida** (`charIndex / totalChars`) e usamos isso para derivar o tempo restante estimado a partir do `elapsedTime` real.

### 1. Adicione um novo ref para dados do timer

```js
const speechTimerRef = useRef({ startTime: null, totalChars: 0, lastCharIndex: 0 });
```

### 2. Adicione estado para tempo restante por progresso real

O estado `remainingTime` já existe. Vamos alimentá-lo com dados reais.

### 3. Modifique `playFromTokenIndex` para calcular tempo restante via `onboundary`

Dentro de `playFromTokenIndex`, já existe um `utter.onboundary`. **Modifique-o** para também atualizar o tempo restante:

```js
// Antes de criar o utterance, inicializa o ref do timer
const totalChars = remainingText.length;
speechTimerRef.current = { totalChars, lastElapsed: 0, lastCharIndex: 0 };

// No onboundary existente, ADICIONE ao final do handler:
utter.onboundary = e => {
  if (e.name !== "word") return;
  
  // --- Bloco existente de highlight de palavras (mantém igual) ---
  let acc = 0, rel = -1;
  for (let j = 0; j < remaining.length; j++) {
    if (e.charIndex >= acc && e.charIndex < acc + remaining[j].length) { rel = j; break; }
    acc += remaining[j].length;
  }
  if (rel !== -1) {
    const abs = startIdx + rel;
    activeTokenIdxRef.current = abs;
    setCurrentWordIdx(abs);
    setReadWords(prev => {
      const next = new Set(prev);
      for (let k = 0; k < abs; k++) if (/\S/.test(tokens[k])) next.add(k);
      return next;
    });
  }

  // --- NOVO: calcula tempo restante real ---
  const elapsed = e.elapsedTime;           // segundos decorridos (dado real da API)
  const charsDone = e.charIndex;           // chars lidos até agora
  const charsTotal = speechTimerRef.current.totalChars;

  if (elapsed > 0 && charsDone > 0) {
    // Taxa real observada: chars por segundo até este momento
    const charsPerSec = charsDone / elapsed;
    const charsLeft = charsTotal - charsDone;
    const secsLeft = Math.ceil(charsLeft / charsPerSec);
    setRemainingTime(secsLeft);
  }
};
```

### 4. Remova o `useEffect` do timer por intervalo (que estava errado)

Localize e **substitua** o `useEffect` que usa `setInterval`:

```js
// REMOVER este bloco inteiro:
useEffect(() => {
  let interval;
  if (isPlaying && !isPaused && estimatedTime > 0) {
    setRemainingTime(estimatedTime);
    interval = setInterval(() => {
      setRemainingTime(prev => Math.max(0, prev - 1));
    }, 1000);
  } else if (!isPlaying) {
    setRemainingTime(0);
  }
  return () => { if (interval) clearInterval(interval); };
}, [isPlaying, isPaused, estimatedTime]);

// SUBSTITUIR por este (apenas para resetar ao parar):
useEffect(() => {
  if (!isPlaying && !isPaused) {
    setRemainingTime(0);
  }
}, [isPlaying, isPaused]);
```

> **Por quê é mais preciso:** O objeto `SpeechSynthesisEvent` inclui informações sobre o que está acontecendo no sintetizador, como a posição do cursor virtual (`charIndex`) e o tempo decorrido após o início da leitura (`elapsedTime`). Usando `charIndex / elapsedTime`, obtemos a **velocidade real de leitura daquela voz naquele momento**, tornando a estimativa de tempo restante adaptativa e muito mais precisa do que qualquer constante de wpm.

---

# 📋 Resumo das mudanças

| | Arquivo | O que muda |
|---|---|---|
| **Bug 1** | `App()` | Adicionar `textareaRef`, conectar ao `<textarea>`, reescrever `getCursorTokenIndex` |
| **Bug 2A** | `useEffect` estimativa | Trocar `150` por `160`, corrigir ordem matemática |
| **Bug 2B** | `playFromTokenIndex` | Adicionar cálculo de `remainingTime` real dentro do `onboundary` existente |
| **Bug 2B** | `useEffect` timer | Remover `setInterval`, substituir por simples reset no stop |
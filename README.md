# Balabolka Web TTS Reader

Um leitor de texto em voz alta (Text-to-Speech) para navegador, inspirado no Balabolka. Implementado como um **único arquivo HTML autocontido** — sem Node.js, sem bundler, sem build.

## ✨ Funcionalidades

### 🎤 Leitura em Voz Alta (Web Speech API)
- **SpeechSynthesis** nativo do navegador (Chrome/Edge/Firefox)
- Controles: Play / Pause / Stop
- Velocidade (rate), tom (pitch), volume ajustáveis
- Seleção de voz (pt-BR, en-US, etc.)
- Destaque de palavra em tempo real (`onboundary`)
- **Leitura a partir da posição do cursor** — clique no meio do texto e aperte Play

### 📝 Editor Duplo
- **Modo Texto** (`<textarea>`) — edição pura, posicionamento de cursor via `selectionStart`
- **Modo Renderizado** (`contentEditable`) — visualização Markdown com formatação
- Alternância instantânea entre modos (mantém posição/scroll)

### 🔍 Busca Avançada (Bloco 4)
- Localizar / Substituir com suporte a *case-sensitive*
- **Navegação por ocorrências**: contador "1 de 5", botões ◀ ▶
- Atalhos: **F3** (próxima), **Shift+F3** (anterior)
- Destaque e scroll automático no textarea

### 📑 Abas / Documentos
- Múltiplos documentos simultâneos
- Clique duplo no título da aba para renomear (Enter/Escape/Blur para confirmar)
- Fechar aba (protege última aba)
- Persistência no `localStorage` (texto por aba, aba ativa, zoom, modo renderizado)

### 🖱️ Zoom & Acessibilidade
- Zoom 50%–200% (botões +/−, **Ctrl+Scroll**, atalhos `Ctrl++` / `Ctrl+-` / `Ctrl+0`)
- Persiste preferência no `localStorage`

### 📄 Importação de Arquivos
- **PDF** (via PDF.js CDN — extração de texto por página)
- **HTML/HTM** (remove tags, mantém texto)
- **TXT/MD** (texto puro)
- Drag-and-drop ou botão "Abrir Arquivo"

### 💾 Exportação
- **Salvar como .txt** (download direto)
- **Salvar como Áudio** (WebM/Opus via `MediaRecorder` + `getDisplayMedia` — captura áudio da aba)

### ⌨️ Atalhos Globais
| Atalho | Ação |
|--------|------|
| `Space` | Play / Pause |
| `Escape` | Stop (fecha modais primeiro) |
| `Ctrl+Z` / `Ctrl+Y` | Undo / Redo |
| `Ctrl+F` | Abrir Localizar |
| `F3` / `Shift+F3` | Próxima / Anterior ocorrência |
| `Ctrl++` / `Ctrl+-` / `Ctrl+0` | Zoom in / out / reset |
| `Ctrl+Scroll` | Zoom suave |
| `Ctrl+S` | Salvar .txt |
| `Ctrl+O` | Abrir arquivo |
| `Ctrl+N` | Novo documento |
| `Ctrl+A` | Selecionar tudo |
| `Ctrl+C` / `Ctrl+V` | Copiar / Colar |

### 🪟 Modais Arrastáveis + ESC (Bloco 3)
- Todos os modais (Fontes, Localizar, Sobre, Salvar, Tamanho Botões) são **arrastáveis pela barra de título**
- **ESC fecha o modal** (não para a leitura se modal aberto)
- Implementado via *capture-phase listener* + `stopPropagation` no modal

### 📋 Painel de Área de Transferência
- Painel lateral (não-modal) com botões: Copiar tudo, Colar, Selecionar tudo, Limpar marcações MD, Restaurar original

## 🚀 Como Usar

1. Baixe `balabolka_web.html`
2. Abra no **Chrome** ou **Edge** (duplo-clique)
3. Cole ou digite texto no editor
4. Aperte **Espaço** ou clique em **Play ▶**

> **Nota:** Requer HTTPS ou `localhost` para `getDisplayMedia` (gravação de áudio). Em `file://` a gravação falhará — use um servidor local:
> ```bash
> npx serve .   # ou python -m http.server
> ```

## 🏗️ Arquitetura

```
balabolka_web.html (single file, ~105 KB)
├── React 18 + Babel Standalone (CDN unpkg)
├── CSS puro (sem Tailwind, sem framework)
├── Web Speech API (SpeechSynthesis)
├── PDF.js 2.16 (CDN cdnjs)
└── localStorage persistence
```

### Estrutura de Código (%%SECTION:)
```
CONSTANTS          → WPM_BASE=160, DEFAULT_COLORS, STORAGE_KEYS
STATE              → Core TTS, Find/Replace, Recording
REFS               → textareaRef, editorRef, speechTimerRef, historyRef...
UTILITIES          → PDF.js (loadPdfJs, processFile), Markdown (strip/render)
EFFECTS (18 blocos)→ Voice loading, History sync, Auto-save, Tab sync,
                     UI scroll, Hotkeys (F3, ESC guard), Zoom, Modals
HANDLERS (28 fns)  → Tab, Text, Undo/Redo, Find, File, Export, Playback
```

### Padrões Importantes
- **`useCallback` + JSDoc** em todos os handlers (estabilidade + documentação)
- **Refs para DOM direto** (`textareaRef` → `selectionStart` para cursor)
- **Timer preciso via `onboundary`** — usa `e.elapsedTime` + `e.charIndex` para calcular tempo restante real (não `setInterval`)
- **ESC priority**: modal captura no *capture phase* + `stopPropagation`; global hotkey verifica `hasModalOpen` antes de `handleStop()`

## 🐛 Bugs Corrigidos (Histórico)

| Bloco | Bug | Causa | Fix |
|-------|-----|-------|-----|
| 2 | Leitura sempre do início | `window.getSelection()` não funciona em `<textarea>` | `textareaRef.current.selectionStart` + conversão char→token |
| 2 | Tempo estimado errado | Fórmula `150 wpm` + `setInterval` desacoplado | Base 160 wpm (pt-BR Chrome) + `onboundary` progresso real |
| 3 | ESC não fecha modal | Global handler chamava `handleStop()` sem checar modais | `hasModalOpen` guard + modal `capture:true` + `stopPropagation` |

## 📦 Dependências (CDN)

| Lib | Versão | URL |
|-----|--------|-----|
| React | 18.2.0 | `unpkg.com/react@18/umd/react.production.min.js` |
| ReactDOM | 18.2.0 | `unpkg.com/react-dom@18/umd/react-dom.production.min.js` |
| Babel Standalone | 7.23.x | `unpkg.com/@babel/standalone/babel.min.js` |
| PDF.js | 2.16.105 | `cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js` |

## 🌐 Compatibilidade

| Navegador | SpeechSynthesis | getDisplayMedia | PDF.js |
|-----------|-----------------|-----------------|--------|
| Chrome 100+ | ✅ Completo | ✅ (HTTPS/localhost) | ✅ |
| Edge 100+ | ✅ Completo | ✅ (HTTPS/localhost) | ✅ |
| Firefox 90+ | ✅ Completo | ⚠️ Parcial | ✅ |
| Safari 15+ | ✅ Básico | ❌ | ✅ |

## 📄 Licença

MIT — uso livre, modificação e distribuição.

---

**Desenvolvido com** React 18, Web Speech API, PDF.js e muito ☕.
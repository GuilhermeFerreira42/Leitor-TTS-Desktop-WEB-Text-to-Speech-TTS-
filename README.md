# Balabolka Web TTS Reader

Um leitor de texto em voz alta (Text-to-Speech) para navegador, inspirado no Balabolka. Implementado como um **único arquivo HTML autocontido** — sem Node.js, sem bundler, sem build.

## ✨ Funcionalidades

### 🎤 Leitura em Voz Alta (Web Speech API)
- **SpeechSynthesis** nativo do navegador (Chrome/Edge/Firefox)
- Controles: Play / Pause / Stop
- Velocidade (rate), tom (pitch), volume ajustáveis
- Seleção de voz (pt-BR, en-US, etc.)
- Destaque de palavra em tempo real (`onboundary`)
- **Leitura Inteligente**: Inicia exatamente da posição do cursor ou retoma de onde parou.
- **Áudio Robusto**: Integração com `AudioContext` para garantir que o som respeite o dispositivo padrão do sistema (como fones de ouvido).

### 📝 Editor de Camada Única (Moderno)
- **Arquitetura contentEditable**: Abandona o uso de `textarea` sobreposto para eliminar problemas de rastro visual (ghosting).
- **Sincronização Nativa**: Scroll e edição acontecem em uma única camada, garantindo performance e precisão.
- **Modo Renderizado**: Visualização Markdown com formatação opcional.
- **Seleção Estável**: Algoritmos avançados de preservação de cursor que evitam "pulos" ou inversão de texto durante a digitação.

### 🔍 Busca Avançada
- Localizar / Substituir com suporte a *case-sensitive*
- **Navegação por ocorrências**: contador "1 de 5", botões ◀ ▶
- Atalhos: **F3** (próxima), **Shift+F3** (anterior)

### 📑 Abas / Documentos
- Múltiplos documentos simultâneos
- Clique duplo no título da aba para renomear
- Persistência automática no `localStorage` (texto, aba ativa, configurações)

### 🖱️ Zoom & Acessibilidade
- Zoom 50%–200% (botões +/−, **Ctrl+Scroll**, atalhos `Ctrl++` / `Ctrl+-` / `Ctrl+0`)

### 📄 Importação de Arquivos
- **PDF** (via PDF.js CDN — extração de texto por página)
- **HTML/HTM** (extração inteligente de texto)
- **TXT/MD** (texto puro)
- Drag-and-drop completo

### 💾 Exportação
- **Salvar como .txt**
- **Salvar como Áudio** (WebM/Opus via `MediaRecorder` + `getDisplayMedia` — captura áudio da aba)

### ⌨️ Atalhos Globais
| Atalho | Ação |
|--------|------|
| `F5` / `Space` | Play / Pause |
| `Esc` | Stop / Fechar Modais |
| `Ctrl+Z` / `Ctrl+Y` | Undo / Redo |
| `Ctrl+F` | Localizar |
| `F3` / `Shift+F3` | Próxima / Anterior ocorrência |
| `Ctrl++` / `Ctrl+-` | Zoom |
| `Ctrl+S` | Salvar .txt |
| `Ctrl+O` | Abrir arquivo |

## 🚀 Como Usar

1. Baixe `balabolka_web.html`
2. Abra no **Chrome** ou **Edge**
3. Cole o texto e clique em **Play ▶**

## 🏗️ Arquitetura

```
balabolka_web.html
├── React 18 + Babel Standalone (Single-Layer logic)
├── Uncontrolled contentEditable Pattern (Estabilidade de cursor)
├── Manual DOM Sync via useLayoutEffect (Performance)
└── Web Speech API + AudioContext (Som estável)
```

### Padrões de Implementação
- **Uncontrolled Editor**: O componente de edição é tratado como não-controlado durante a digitação para evitar o reset do cursor pelo React.
- **Debounced Highlighting**: Atualizações visuais (karaoke) são processadas a cada 50ms para reduzir o uso de CPU e evitar travamentos.
- **Recursive Node Traversal**: `saveSelection` e `restoreSelection` percorrem a árvore DOM recursivamente para manter o cursor preciso entre múltiplos `<span>` de destaque.

## 🐛 Histórico de Correções Críticas

| Bug | Causa | Solução |
|-----|-------|---------|
| **Ghosting no Scroll** | Duas camadas sobrepostas (textarea + div) | Migração para **Camada Única contentEditable**. |
| **Texto Invertido ao Digitar** | `dangerouslySetInnerHTML` resetando o cursor | Implementação do **Padrão Não-Controlado** + Manual Sync. |
| **Leitura Ignorando Cursor** | `window.getSelection()` falhando no modo anterior | Mapeamento recursivo de offset de caracteres em tempo real. |
| **Áudio não sai no Fone** | `speechSynthesis` ignora sink de áudio | Inicialização via `AudioContext` para forçar o dispositivo padrão. |

## 🌐 Compatibilidade

- ✅ **Chrome/Edge**: Recomendado (suporte completo a todas as APIs).
- ⚠️ **Firefox**: Suporte parcial para gravação de áudio.
- ❌ **Safari**: Limitações na gravação e algumas APIs de áudio.

## 📄 Licença

MIT — uso livre, modificação e distribuição.

---

**Desenvolvido com** React 18, Web Speech API e foco em performance.
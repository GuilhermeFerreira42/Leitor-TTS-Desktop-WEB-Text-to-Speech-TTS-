# Checklist de Funcionalidades — Balabolka Web TTS

Este documento serve como guia para validação manual de todas as funcionalidades implementadas no sistema.

---

## 🎤 1. Requisitos Funcionais: Leitura e Áudio (TTS)
- [ ] **Play/Pause/Stop**: Botões e atalhos (`F5`, `Space`, `F6`, `Esc`) funcionam corretamente.
- [ ] **Leitura de Posição Específica**: Ao clicar no meio do texto e dar Play, a leitura inicia da palavra clicada.
- [ ] **Destaque em Tempo Real (Karaoke)**: A palavra sendo falada é destacada visualmente.
- [ ] **Histórico de Leitura**: Palavras já lidas permanecem com a cor de "texto lido" ao pausar/retomar ou pular trechos.
- [ ] **Controles de Voz**: Ajuste de Velocidade (0.1x a 10x), Tonalidade e Volume refletem na voz imediatamente.
- [ ] **Seleção de Voz**: Lista de vozes do sistema carrega e permite troca (pt-BR, en-US, etc.).
- [ ] **Teste de Voz**: Botão "Testar" reproduz frase de exemplo com as configurações atuais.
- [ ] **Roteamento de Áudio**: O áudio sai corretamente em fones de ouvido (validado via inicialização de `AudioContext`).
- [ ] **Cálculo de Tempo**: Exibição precisa do tempo estimado total e tempo restante na barra de status.

---

## 📝 2. Requisitos Funcionais: Editor e Texto
- [ ] **Edição Fluida**: Digitação sem atrasos, inversão de caracteres ou saltos de cursor (Arquitetura contentEditable).
- [ ] **Preservação de Cursor**: O cursor permanece na posição correta mesmo quando o destaque (karaoke) é atualizado.
- [ ] **Markdown Renderizado**: Alternância entre modo edição e visualização formatada (Markdown).
- [ ] **Limpar Marcações**: Opção para remover permanentemente símbolos de Markdown (#, **, [], etc.).
- [ ] **Restaurar Original**: Capacidade de voltar ao texto Markdown original após a limpeza.
- [ ] **Undo/Redo**: Desfazer e refazer edições via botões ou `Ctrl+Z` / `Ctrl+Y`.
- [ ] **Seleção Total**: Atalho `Ctrl+A` seleciona todo o conteúdo do editor.

---

## 📑 3. Requisitos Funcionais: Abas e Arquivos
- [ ] **Múltiplas Abas**: Criar novas abas e alternar entre elas sem perder o texto.
- [ ] **Renomear Abas**: Clique duplo no título da aba permite renomear com confirmação (Enter) ou cancelamento (Esc).
- [ ] **Fechar Abas**: Botão "X" remove a aba (bloqueado se for a única aberta).
- [ ] **Importação Drag-and-Drop**: Arrastar arquivos para o editor abre-os em novas abas automaticamente.
- [ ] **Suporte a PDF**: Extração de texto de PDFs via PDF.js.
- [ ] **Suporte a HTML/TXT/MD**: Carregamento correto de arquivos de texto e remoção de tags HTML.

---

## 💾 4. Requisitos Funcionais: Exportação
- [ ] **Salvar Texto**: Exportação do conteúdo atual como arquivo `.txt`.
- [ ] **Salvar Áudio**: Gravação da narração em arquivo `.webm` (requer permissão de captura de áudio da aba).

---

## 🔍 5. Requisitos Funcionais: Busca e UI
- [ ] **Localizar/Substituir**: Busca por texto com opção de diferenciação de maiúsculas (*case-sensitive*).
- [ ] **Navegação de Ocorrências**: Botões de próximo/anterior e contador (ex: "2 de 10").
- [ ] **Modais Arrastáveis**: Janelas de configuração podem ser movidas pela barra de título.
- [ ] **Fechar via ESC**: Tecla `Esc` fecha modais ativos prioritariamente.
- [ ] **Zoom**: Ajuste de zoom (50% a 200%) via interface, `Ctrl+Scroll` ou atalhos de teclado.
- [ ] **Barra de Status**: Informações de linhas, palavras, caracteres e status do TTS atualizadas em tempo real.

---

## ⚙️ 6. Requisitos Não Funcionais (Qualidade e Técnica)
- [ ] **Zero Ghosting**: Sem rastro visual ou duplicata de texto durante o scroll (Single-Layer Sync).
- [ ] **Persistência Local**: Textos, configurações de voz, zoom e abas são salvos no `localStorage` e restaurados ao recarregar a página.
- [ ] **Performance (Debounce)**: Atualização de destaques visual a cada 50ms para evitar alto consumo de CPU.
- [ ] **Estabilidade de DOM**: Uso de padrão "Não-Controlado" para evitar que o React interfira no cursor nativo do browser durante a digitação.
- [ ] **Portabilidade**: O sistema funciona como um único arquivo HTML sem dependências de instalação (Node.js/npm).
- [ ] **Responsividade**: Interface se ajusta ao redimensionamento da janela do navegador.
- [ ] **Compatibilidade**: Suporte pleno em Chrome e Edge (Web Speech API + getDisplayMedia).

---
*Checklist gerado para validação da versão estável do Balabolka Web.*

---

## 📂 Contexto Histórico e Técnico (JSON)

```json
{
  "meta": {
    "id": "CP-2026-06-12-1900",
    "created_at": "2026-06-12T19:00:00Z",
    "source": "Arquitetura e Otimização do Balabolka Web",
    "domain": "software",
    "summary": "Migração para contentEditable single-layer, resolução de ghosting e estabilização de cursor via padrão de componente não-controlado."
  },
  "objective": {
    "goal": "Eliminar definitivamente problemas de scroll ghosting e instabilidade do cursor durante a digitação e leitura TTS.",
    "non_goals": ["Migração para frameworks pesados", "Uso de APIs pagas"],
    "success_criteria": [
      "Scroll sincronizado sem rastro visual",
      "Cursor estável sem inversão de texto ao digitar",
      "Início de leitura respeitando a posição exata do clique"
    ]
  },
  "decisions": [
    {
      "id": "D-001",
      "what": "Abandono da arquitetura de duas camadas (textarea + overlay) em favor de uma camada única contentEditable.",
      "why": "Elimina a latência de sincronização entre elementos e o bug de reset de scroll nativo do dangerouslySetInnerHTML.",
      "alternatives_rejected": ["Sincronização via CSS transforms", "Bi-directional scroll locking"],
      "reversible": true,
      "confidence": "high"
    },
    {
      "id": "D-002",
      "what": "Implementação do padrão 'Uncontrolled Component' para o editor durante a digitação.",
      "why": "Evita que as re-renderizações do React destruam e recriem os nós de texto enquanto o usuário digita, prevenindo a inversão de caracteres.",
      "alternatives_rejected": ["Controlled contentEditable com Selection API agressiva"],
      "reversible": true,
      "confidence": "high"
    },
    {
      "id": "D-003",
      "what": "Sincronização manual do DOM via innerHTML dentro de useLayoutEffect.",
      "why": "Garante que os destaques (spans) sejam aplicados apenas quando seguro e com restauração imediata de cursor.",
      "alternatives_rejected": ["useEffect padrão (causa flicker)"],
      "reversible": true,
      "confidence": "high"
    },
    {
      "id": "D-004",
      "what": "Uso de AudioContext para forçar o roteamento de áudio para o dispositivo padrão.",
      "why": "Workaround necessário para browsers que ignoram fones de ouvido na SpeechSynthesis nativa.",
      "alternatives_rejected": ["Navegador gerenciar dispositivo sozinho"],
      "reversible": true,
      "confidence": "medium"
    }
  ],
  "facts": [
    {
      "id": "F-001",
      "statement": "O React reseta a posição de scroll de um elemento ao atualizar seu dangerouslySetInnerHTML.",
      "source": "Observação técnica e documentação React",
      "verified": true
    },
    {
      "id": "F-002",
      "statement": "A SpeechSynthesisUtterance.onboundary fornece o charIndex exato em relação ao texto falado.",
      "source": "Web Speech API Spec",
      "verified": true
    },
    {
      "id": "F-003",
      "statement": "A propriedade innerText preserva quebras de linha em contentEditable melhor que textContent.",
      "source": "Testes de compatibilidade cross-browser",
      "verified": true
    }
  ],
  "constraints": [
    {
      "id": "C-001",
      "rule": "Nenhuma alteração do innerHTML durante o estado isTyping.",
      "reason": "Prevenir a perda de foco e posição do cursor nativo.",
      "negotiable": false
    }
  ],
  "open_items": [
    {
      "id": "O-001",
      "question": "Otimizar PDF.js para arquivos de centenas de páginas?",
      "context": "Atualmente carrega tudo na memória principal.",
      "blocking": false,
      "suggested_next_step": "Implementar carregamento sob demanda (lazy-loading) por página."
    }
  ],
  "artifacts": [
    {
      "id": "A-001",
      "name": "balabolka_web.html",
      "type": "código",
      "status": "final",
      "location": "root",
      "summary": "Implementação final estável com arquitetura single-layer."
    }
  ],
  "current_state": {
    "where_we_stopped": "Arquitetura migrada para contentEditable uncontrolled com sucesso. Cursor e playback estabilizados.",
    "next_actions": ["Validação manual via Checklist", "Teste de estresse com textos longos"],
    "blockers": []
  }
}
```


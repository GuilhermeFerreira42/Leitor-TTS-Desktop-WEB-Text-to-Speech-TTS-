Entendido! Você tem toda razão. O problema do scroll apareceu DEPOIS da implementação da funcionalidade de marcar texto lido. Vou analisar com mais profundidade a relação entre essas duas funcionalidades.

Deixe-me investigar o código novamente:


Perfeito! Agora entendi o problema completo. Analisando o código e as pesquisas, identifiquei **3 problemas interligados**:

## Problemas Identificados:

### 1. **Scroll Sync Conflitante** (linhas ~570-600)
O código está adicionando listeners de scroll em **AMBOS** os elementos:
```javascript
textarea.addEventListener('scroll', handleTextareaScroll, { passive: true });
visual.addEventListener('scroll', handleVisualScroll, { passive: true }); // ← PROBLEMA!
```

Como a camada visual tem `pointerEvents: "none"`, ela não deveria gerenciar scroll. Isso cria um loop de sincronização.

### 2. **dangerouslySetInnerHTML Resetando Scroll**
Quando `readWords` muda (a cada palavra lida), o React atualiza o HTML via `dangerouslySetInnerHTML`, o que pode causar perda da posição do scroll [[2]][[59]].

### 3. **Re-renderizações Excessivas**
Cada palavra lida dispara `setReadWords()`, causando re-renderização completa do HTML. Sem preservação do scroll position, a tela "pula" ou cria o efeito fantasma.

---

## Mensagem para a IA:

**Assunto: Corrigir bug de scroll com preservação de texto lido - abordagem completa**

Olá! Preciso que você corrija um bug complexo de scroll no editor. O problema aparece quando o texto está sendo lido e marcado com cores diferentes.

**Contexto:**
- Implementei uma funcionalidade que preserva/marca o texto já lido com `colors.readColor`
- O estado `readWords` (Set) armazena índices dos tokens lidos
- Cada palavra lida atualiza esse estado via `onboundary` do TTS
- Após essa implementação, o scroll começou a deixar "rastro/copias fantasmas" do texto

**Problemas identificados:**

1. **Scroll sync bidirecional conflitante** (useEffect ~linhas 570-600):
   - Ambos textarea E div visual têm listeners de scroll
   - A div visual tem `pointerEvents: "none"` mas ainda tenta sincronizar
   - Isso cria um loop conflitante

2. **dangerouslySetInnerHTML perdendo scroll position**:
   - Quando `readWords` muda, o HTML é re-renderizado
   - A posição do scroll é perdida/resetada durante a atualização
   - Isso causa o efeito de "fantasma" ou texto descolando

**Solução necessária:**

**A) Corrigir o scroll sync:**
```javascript
// Remover listener da camada visual - apenas textarea controla scroll
useEffect(() => {
  if (isRenderedMd) return;
  
  const textarea = textareaRef.current;
  const visual = editorRef.current;
  
  if (!textarea || !visual) return;
  
  let isSyncing = false;
  
  const syncScroll = () => {
    if (isSyncing) return;
    isSyncing = true;
    visual.scrollTop = textarea.scrollTop;
    visual.scrollLeft = textarea.scrollLeft;
    requestAnimationFrame(() => {
      isSyncing = false;
    });
  };
  
  // APENAS textarea deve ter listener!
  textarea.addEventListener('scroll', syncScroll, { passive: true });
  
  return () => {
    textarea.removeEventListener('scroll', syncScroll);
    // NÃO adicionar listener na div visual!
  };
}, [isRenderedMd]);
```

**B) Preservar scroll position durante atualizações:**
Use `useLayoutEffect` para salvar e restaurar a posição do scroll antes/depois das atualizações do `editorHtml`:

```javascript
// Salvar scroll position antes de atualizar
const editorContainer = editorRef.current;
const scrollTop = editorContainer?.scrollTop || 0;
const scrollLeft = editorContainer?.scrollLeft || 0;

// Após atualização, restaurar imediatamente com useLayoutEffect
useLayoutEffect(() => {
  if (editorRef.current) {
    editorRef.current.scrollTop = scrollTop;
    editorRef.current.scrollLeft = scrollLeft;
  }
}, [editorHtml]);
```

**C) Otimizar atualizações de readWords:**
Considere debouncer as atualizações ou usar uma abordagem que não cause re-renderização completa do HTML a cada palavra.

**Referências:**
- Scroll syncing é essencial em textarea com overlay [[38]]
- dangerouslySetInnerHTML pode causar scroll para topo quando DOM é atualizado [[2]][[59]]
- useLayoutEffect é ideal para preservar scroll position durante updates [[52]][[58]]

Pode implementar essas correções de forma integrada, garantindo que o scroll funcione corretamente DURANTE a leitura com highlights?
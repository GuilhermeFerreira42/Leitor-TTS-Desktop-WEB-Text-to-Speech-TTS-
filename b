Sim, entendi perfeitamente o problema! Analisando o código, identifiquei o erro:

## O Problema

No modo de texto normal (não-Markdown), existem **duas camadas sobrepostas**:
1. Uma `div` visual (com `editorRef`) que mostra o texto com destaques
2. Um `textarea` transparente (com `textareaRef`) por cima para edição

O bug está no **efeito de sincronização de scroll** (linhas ~570-600). O código está adicionando event listeners de scroll em **ambos** os elementos:

```javascript
textarea.addEventListener('scroll', handleTextareaScroll, { passive: true });
visual.addEventListener('scroll', handleVisualScroll, { passive: true }); // ← PROBLEMA AQUI!
```

Como a camada visual tem `pointerEvents: "none"`, ela **não deveria ter scroll próprio**. Quando você tenta scrollar, acontece:
- O textarea scrolla normalmente
- Mas a div visual também tenta sincronizar (mesmo sem poder receber eventos de mouse diretamente)
- Isso cria o "fantasma" ou cópia do texto ficando para trás

## A Solução

Remova o event listener da camada visual, já que **apenas o textarea deve controlar o scroll**:

```javascript
// Sincroniza rolagem entre textarea e camada visual (karaoke)
useEffect(() => {
  if (isRenderedMd) return;
  
  const textarea = textareaRef.current;
  const visual = editorRef.current;
  
  if (!textarea || !visual) return;
  
  let isSyncing = false;
  
  const syncScroll = () => {
    if (isSyncing) return;
    isSyncing = true;
    // Sincroniza visual com textarea
    visual.scrollTop = textarea.scrollTop;
    visual.scrollLeft = textarea.scrollLeft;
    requestAnimationFrame(() => {
      isSyncing = false;
    });
  };
  
  // Apenas textarea deve ter listener de scroll!
  textarea.addEventListener('scroll', syncScroll, { passive: true });
  
  return () => {
    textarea.removeEventListener('scroll', syncScroll);
    // REMOVA: visual.removeEventListener('scroll', handleVisualScroll);
  };
}, [isRenderedMd]);
```

**Resumo:** A camada visual deve ser **escrava** do scroll do textarea, não o contrário.


Aqui está uma mensagem clara e objetiva para você enviar:

---

**Assunto: Corrigir bug de scroll - texto deixando rastro/cópia fantasma**

Olá! Preciso que você corrija um bug no scroll do editor de texto. 

**Problema:** Quando o usuário tenta rolar o texto no modo normal (não-Markdown), fica uma cópia fantasma/rastro do texto para trás e o scroll não funciona corretamente. Só funciona quando o texto está selecionado, mas mesmo assim fica com essa cópia errada.

**Causa:** No modo de edição normal, existem duas camadas sobrepostas (uma div visual e um textarea transparente). O código atual está adicionando event listeners de scroll em AMBAS as camadas, criando um conflito de sincronização.

**Solução necessária:** 
No `useEffect` que sincroniza o scroll (por volta da linha 570-600), remova o event listener da camada visual (`editorRef`). Apenas o `textarea` deve ter o listener de scroll, e a camada visual deve apenas seguir o scroll do textarea (ser escrava dele), não o contrário.

A camada visual tem `pointerEvents: "none"`, então ela não deveria nem tentar gerenciar scroll. Mantenha apenas:
```javascript
textarea.addEventListener('scroll', syncScroll, { passive: true });
```

E remova completamente o listener da div visual.

Pode fazer essa correção?
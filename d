O ghosting vem de duas camadas com `position: absolute` sobre `editor-area` (que tem `overflow-y: auto`), cada uma com seu próprio scroll container. Quando a textarea rola, ela rola dentro de si mesma, mas a div visual por baixo tem seu próprio scrollbox que só é atualizado via JS no `syncScroll` — há um frame de defasagem onde o browser já pintou a textarea na nova posição mas a div visual ainda está na posição antiga (ou vice-versa), gerando o "rastro".

Piora durante TTS porque cada `setReadWords` força `dangerouslySetInnerHTML` a recriar o DOM interno da div visual. Recriar innerHTML reseta `scrollTop` para 0 momentaneamente antes do `useLayoutEffect` reaplicar o valor salvo — esse reset+reaplicação no meio de um scroll ativo (rodinha do mouse disparando múltiplos eventos) cria o efeito de cópia descolada, porque o repaint da div ocorre em timing diferente do repaint da textarea.

Correção raiz: eliminar o scroll duplo. Em vez de cada camada ter seu próprio `overflow-y: auto`, deixe **apenas a textarea** com `overflow-y: auto` e a div visual com `overflow: hidden` + altura/scroll controlados via `transform: translateY()` sincronizado, ou simplesmente:

1. Tire `overflow-y: auto` da div visual (deixe `overflow: hidden`).
2. No `syncScroll`, em vez de setar `visual.scrollTop`, aplique `visual.style.transform = `translateY(-${textarea.scrollTop}px)`` — transform não dispara reflow/repaint do scrollbox interno, eliminando a defasagem.
3. Adicione `will-change: transform` na div visual.
4. Garanta que o `useLayoutEffect` que reaplica scroll após `editorHtml` mudar também reaplique o transform (não o scrollTop), na mesma lógica.

Código ajustado:

```css
.editor-area.visual-layer {
  overflow: hidden;
  will-change: transform;
}
```

```javascript
// syncScroll
const syncScroll = () => {
  if (!visual) return;
  visual.style.transform = `translateY(-${textarea.scrollTop}px) translateX(-${textarea.scrollLeft}px)`;
};
```

```javascript
// useLayoutEffect ao mudar editorHtml
useLayoutEffect(() => {
  if (editorRef.current && textareaRef.current && !isRenderedMd) {
    const t = textareaRef.current;
    editorRef.current.style.transform = `translateY(-${t.scrollTop}px) translateX(-${t.scrollLeft}px)`;
  }
}, [editorHtml, isRenderedMd]);
```

Isso remove totalmente o `scrollTop`/`scrollLeft` da div visual do equation — ela passa a ser um elemento estático posicionado via transform, sempre em sincronia 1:1 com a textarea, sem scrollbox próprio que possa "vazar" conteúdo antigo.

Secundário (recomendado também): debounce do `setReadWords` para não recriar o innerHTML a cada palavra — acumule num ref e faça flush a cada ~150ms ou a cada N palavras, reduzindo a frequência de `dangerouslySetInnerHTML`.
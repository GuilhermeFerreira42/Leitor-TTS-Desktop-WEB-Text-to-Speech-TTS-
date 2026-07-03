# PROTOCOLO DE ARQUIVAMENTO PÓS-FASE — Balabolka Web

## Quando Executar
Após a conclusão e validação de cada nova fase do projeto, mediante instrução explícita do usuário.

## Pré-condição Obrigatória
Antes de iniciar, CONFIRMAR que:
- [ ] A suíte de testes em `tests/` passa integralmente
- [ ] Nenhum arquivo de código-fonte está em estado inconsistente
- [ ] O blueprint da fase foi fornecido pelo usuário ou existe em `docs/archive/`

Se qualquer item falhar: PARAR e reportar ao usuário antes de continuar.

## Passos Obrigatórios

### Passo 1 — Verificar Testes
Confirmar que a suíte de testes passa. Reportar explicitamente:
- Número total de testes encontrados
- Número de testes passando
- Qualquer falha identificada

Não arquivar se houver falha não documentada.

### Passo 2 — Arquivar Blueprint
- Salvar o blueprint em `docs/archive/phase_XX_nome.resolved`
- Extensão `.resolved` sinaliza: auditoria humana, não leitura de IA
- Este arquivo NUNCA será lido automaticamente pela IA

### Passo 3 — Reescrever CURRENT_STATE.md
- Abrir `docs/CURRENT_STATE.md`
- SUBSTITUIR (não acumular) com o estado atual
- Atualizar: arquitetura, tabela de módulos, fluxo, invariantes, restrições, testes com comandos
- **Novo:** incluir a seção "Módulos e Contratos Vigentes" com todos os contratos públicos implementados
- Target: ≤ 1800 tokens — se ultrapassar, comprimir, não expandir

### Passo 4 — Append ao DECISION_LOG.md
- Adicionar seção `### Fase N — [nome]` ao final
- 1 linha por decisão: `FN | TIPO | DECISÃO | MOTIVO | ARQUIVOS`
- Entre **5 e 15 linhas por fase**
- Incluir decisões técnicas concretas (TECH) — ex: escolha de biblioteca, padrão de teste, estratégia de validação
- Incluir `FIX` para bugs estruturais corrigidos durante a fase

### Passo 5 — Compressão Progressiva (quando DECISION_LOG > 3000 tokens)
- Consolidar fases antigas em sumário de 1 linha por fase
- Manter as 10 fases mais recentes no formato detalhado

### Passo 6 — Atualizar BACKLOG_FUTURO.md
- Localizar o item da fase recém-concluída
- Alterar `Status` de `PENDENTE` para `CONCLUÍDO`
- **Atualizar a descrição do entregável** para refletir **o que foi realmente entregue**, não apenas o que foi planejado
- Se última fase de uma Onda: verificar se a Meta da Onda foi atingida e atualizar seu status
- Se novas técnicas foram descobertas: adicionar como item novo na Onda apropriada
- **NÃO preencher** `CONTRATOS_DA_ONDA` de ondas futuras — isso é responsabilidade do usuário

### Passo 7 — Criar/Atualizar PHASE_SUMMARY.md (NOVO)
- Gerar um arquivo `docs/phase_N_resumo.md` para a fase recém-concluída
- Este arquivo é **opcional**, mas altamente recomendado para projetos complexos
- Estrutura:
  ```markdown
  # Resumo da Fase {N} — {NOME_DA_FASE}
  > Data: {DATA}

  ## Objetivo
  [1 parágrafo]

  ## Entregáveis
  - Arquivo1 (criado/modificado)
  - Arquivo2 ...

  ## Principais Decisões
  - Decisão 1
  - Decisão 2

  ## Testes
  - Total: X
  - Passando: X

  ## Riscos Conhecidos
  - Risco 1
  - Risco 2

  ## Próxima Fase
  - {NOME_DA_PROXIMA_FASE}
  ```

### Passo 8 — Atualizar .ai-context
- Atualizar o resumo do estado atual
- Refletir a fase concluída e a próxima fase
- Manter a lista de leitura obrigatória

### Passo 9 — Atualizar .humano
- Adicionar entrada com a fase concluída
- Indicar que o projeto aguarda aprovação para a próxima fase

### Passo 10 — Limpeza do Projeto
- Mover scripts de verificação temporários para `docs/archive/phase_XX/`
- Remover arquivos `.tmp`, `.bak`, `.old` gerados durante a fase
- Mover o blueprint da fase para `docs/archive/phase_XX/`

### Passo 11 — Sugerir Mensagem de Commit
Ao final, sugerir no formato:
```
[FASE N] DESCRIÇÃO CURTA EM MAIÚSCULO — resumo do que foi entregue
```

## Regras de Leitura para a IA
- **SEMPRE ler antes de qualquer tarefa:** `docs/CURRENT_STATE.md`
- **Ler no início de cada onda:** `docs/BACKLOG_FUTURO.md`
- **Ler sob demanda:** `docs/DECISION_LOG.md` (para entender "por quê")
- **Ler para contexto rápido:** `docs/PHASE_SUMMARY.md` (se existir)
- **NUNCA ler automaticamente:** `docs/archive/*`
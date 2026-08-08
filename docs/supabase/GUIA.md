# AnalisadorFinanceiro — Guia Multi-Agent com Supabase

## Como os 3 agentes se comunicam

```
AGY (terminal 1)  ─┐
Claude (terminal 2) ├── Supabase MCP ──► banco compartilhado
Codex (OpenCode)  ─┘                    (tasks, messages, artifacts)
```

## Setup inicial (só uma vez)

### 1. Crie o projeto no Supabase
Acesse [supabase.com](https://supabase.com) → New Project → anote a URL e a Service Role Key.

### 2. Aplique o schema SQL
Abra o SQL Editor no painel do Supabase e execute o conteúdo de:
`docs/supabase/schema.sql`

### 3. Rode o script de configuração
```bash
cd ~/Documentos/AnalisadorFinanceiro
chmod +x docs/supabase/setup-supabase.sh
./docs/supabase/setup-supabase.sh
```

Ele vai pedir a URL e a Key e configurar o MCP nos 3 agentes automaticamente.

### 4. Reinicie os terminais
Feche e reabra cada terminal para os MCPs ativarem.

---

## Como usar no dia a dia

### Fluxo padrão — você fala só com o AGY:

```
Você → AGY: "Implemente a tela de banco local"

AGY:
  1. Consulta Supabase: quais agentes estão idle?
  2. Cria tasks na tabela tasks:
     - task A → claude: "modela a entidade BancoLocal"
     - task B → codex: "cria o widget BancoLocalCard"
  3. Envia mensagens via tabela messages

Claude lê sua task → implementa → escreve resultado em artifacts
Codex  lê sua task → implementa → commita na branch certa

AGY monitora → integra → reporta para você
```

### Comandos úteis dentro de cada agente

```
# Ver tarefas pendentes
"Quais tasks estão me atribuídas no Supabase?"

# Marcar tarefa como concluída
"Marque a task <id> como done com resultado: <resultado>"

# Enviar mensagem para outro agente
"Envie uma mensagem para o claude dizendo que a task X está pronta"
```

---

## Tabelas disponíveis via MCP

| Tabela | Para que serve |
|---|---|
| `agents` | Status de cada agente (idle/working/blocked) |
| `tasks` | Fila de tarefas com atribuição e status |
| `messages` | Canal de comunicação entre agentes |
| `artifacts` | Código e arquivos produzidos |
| `progress_log` | Histórico completo do que cada agente fez |

---

## Isolamento de branches (anti-conflito)

Cada task tem o campo `branch` indicando qual worktree usar.
O AGY garante que 2 tasks nunca apontem para a mesma branch.

```
banco-local-mobile  → worktree principal (AGY/você)
settings-screen     → .worktrees/settings-screen (já ativo)
nova-feature        → git worktree add .worktrees/nova-feature nova-feature
```

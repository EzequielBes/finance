# Autocomplete de Transações Repetidas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sugerir, conforme o usuário digita a descrição de uma nova transação, lançamentos parecidos já feitos antes — clicar preenche descrição, valor, categoria e tipo automaticamente.

**Architecture:** Um endpoint novo no backend (`GET /transactions/suggestions`) agrupa o histórico de transações do usuário por descrição, retornando a mais recente de cada grupo que combina com o texto buscado. O frontend adiciona um `watch` com debounce sobre o campo de descrição do formulário existente em `TransactionsView.vue`, mostrando um dropdown de sugestões que, ao ser clicado, preenche os campos relevantes do formulário.

**Tech Stack:** FastAPI + SQLAlchemy async + SQLite (backend), Vue 3 Composition API + Pinia + Vite (frontend). Sem bibliotecas novas.

## Global Constraints

- `GET /transactions/suggestions` deve ser declarado **antes** de `GET /transactions/{transaction_id}` no arquivo do router — FastAPI casa rotas na ordem de declaração, e "suggestions" seria capturado como valor de `transaction_id` (erro 422) se a ordem estiver errada.
- Parâmetro `q` é obrigatório com mínimo de 2 caracteres (`Query(min_length=2)`).
- Busca por substring case-insensitive na descrição, restrita ao usuário autenticado (`Transaction.user_id == current_user.id`).
- Agrupamento por descrição exata: para cada valor distinto de `description` que combina, retorna só a transação mais recente daquele grupo (por `date`).
- Limite de 5 descrições distintas no resultado.
- Response usa um schema novo e menor (`TransactionSuggestion`), não o `TransactionResponse` completo — expõe só `description`, `amount`, `category_id`, `type`.
- No frontend: debounce de 300ms, busca só dispara com 2+ caracteres no campo de descrição.
- Clicar numa sugestão preenche `description`, `amount`, `category_id`, `type` — **não** mexe em `date`, `is_recurring`, `recurrence_period`, `installments_total` (usuário decide esses de novo a cada lançamento).
- Sem testes automatizados de frontend neste projeto (confirmado em specs anteriores) — verificação do frontend é manual via browser. Backend usa `pytest` + `httpx`, seguindo o padrão de `backend/tests/test_transactions.py` (fixture `client`, helper `register_and_login` de `backend/tests/helpers.py`).
- Fora de escopo: sugestões em `IncomeView.vue`, aprendizado por frequência de uso, navegação por teclado no dropdown, edição de transação existente ganhando autocomplete.

---

### Task 1: Endpoint `GET /transactions/suggestions`

**Files:**
- Create: `backend/app/schemas/transaction.py` (modify — adiciona `TransactionSuggestion`)
- Modify: `backend/app/routers/transactions.py`
- Test: `backend/tests/test_transactions.py`

**Interfaces:**
- Produces: `GET /transactions/suggestions?q=<texto>` → `list[TransactionSuggestion]`, onde `TransactionSuggestion` tem os campos `description: str`, `amount: float`, `category_id: int | None`, `type: str`. Consumido pela Task 3 (store do frontend).
- Consumes: nada de tasks anteriores (task inicial). Usa o modelo `Transaction` já existente (`backend/app/models/transaction.py`).

- [ ] **Step 1: Escrever os testes primeiro**

Adicione ao final de `backend/tests/test_transactions.py` (a função helper `get_category_id` já existe no topo do arquivo, reaproveite):

```python
@pytest.mark.asyncio
async def test_suggestions_returns_most_recent_per_description(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Mercado", "amount": 980.0,
        "date": "2026-06-01", "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Mercado", "amount": 1200.0,
        "date": "2026-07-15", "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/transactions/suggestions?q=merc", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["description"] == "Mercado"
    assert data[0]["amount"] == 1200.0


@pytest.mark.asyncio
async def test_suggestions_case_insensitive(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Conta de Luz", "amount": 250.0,
        "date": "2026-07-01", "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/transactions/suggestions?q=CONTA", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["description"] == "Conta de Luz"


@pytest.mark.asyncio
async def test_suggestions_limits_to_five_distinct_descriptions(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    for i in range(7):
        await client.post("/transactions", json={
            "category_id": cat_id, "description": f"Assinatura {i}", "amount": 10.0 + i,
            "date": "2026-07-01", "type": "expense", "is_recurring": False
        }, headers=headers)

    response = await client.get("/transactions/suggestions?q=assinatura", headers=headers)
    assert response.status_code == 200
    assert len(response.json()) == 5


@pytest.mark.asyncio
async def test_suggestions_only_own_transactions(client):
    token_a = await register_and_login(client)
    headers_a = {"Authorization": f"Bearer {token_a}"}
    cat_id_a = await get_category_id(client, headers_a)
    await client.post("/transactions", json={
        "category_id": cat_id_a, "description": "Aluguel", "amount": 1200.0,
        "date": "2026-07-01", "type": "expense", "is_recurring": False
    }, headers=headers_a)

    token_b = await register_and_login(client, email="userb@email.com", name="User B", password="senhaB999")
    headers_b = {"Authorization": f"Bearer {token_b}"}

    response = await client.get("/transactions/suggestions?q=aluguel", headers=headers_b)
    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_suggestions_requires_min_two_chars(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/transactions/suggestions?q=a", headers=headers)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_suggestions_route_does_not_collide_with_transaction_id(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/transactions/suggestions?q=xx", headers=headers)
    assert response.status_code == 200
    assert response.json() == []
```

- [ ] **Step 2: Rodar os testes para confirmar que falham**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_transactions.py -k suggestions -v`
Expected: FAIL (rota não existe ainda — 404 ou 422 incorreto).

- [ ] **Step 3: Adicionar o schema `TransactionSuggestion`**

Em `backend/app/schemas/transaction.py`, adicione ao final do arquivo:

```python
class TransactionSuggestion(BaseModel):
    description: str
    amount: float
    category_id: Optional[int]
    type: TransactionType

    model_config = {"from_attributes": True}
```

- [ ] **Step 4: Implementar o endpoint**

Em `backend/app/routers/transactions.py`, adicione o import do novo schema na linha de imports existente (atualmente `from app.schemas.transaction import TransactionCreate, TransactionUpdate, TransactionResponse, TransactionListResponse`):

```python
from app.schemas.transaction import TransactionCreate, TransactionUpdate, TransactionResponse, TransactionListResponse, TransactionSuggestion
```

Adicione o endpoint **imediatamente após** `list_transactions` (a função que trata `GET ""`) e **antes** de `get_transaction` (a função que trata `GET "/{transaction_id}"`) — a ordem no arquivo é a ordem de roteamento do FastAPI:

```python
@router.get("/suggestions", response_model=list[TransactionSuggestion])
async def get_suggestions(
    q: str = Query(..., min_length=2),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Transaction)
        .where(
            and_(
                Transaction.user_id == current_user.id,
                Transaction.description.ilike(f"%{q}%"),
            )
        )
        .order_by(Transaction.date.desc())
    )
    transactions = result.scalars().all()

    seen_descriptions = {}
    for tx in transactions:
        if tx.description not in seen_descriptions:
            seen_descriptions[tx.description] = tx
        if len(seen_descriptions) >= 5:
            break

    return list(seen_descriptions.values())
```

Nota: `Column.ilike()` é o operador case-insensitive do SQLAlchemy — funciona tanto em SQLite quanto em Postgres, mais portável que depender do comportamento padrão do `LIKE` do SQLite (que só é case-insensitive para ASCII e pode variar).

- [ ] **Step 5: Rodar os testes de novo**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_transactions.py -k suggestions -v`
Expected: PASS nos 6 testes.

- [ ] **Step 6: Rodar a suite inteira do arquivo pra garantir que a ordem de rotas não quebrou nada**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_transactions.py -v`
Expected: todos os testes passam, incluindo os já existentes que usam `GET /transactions/{id}` (confirma que a nova rota `/suggestions` não interceptou chamadas com um ID numérico real).

- [ ] **Step 7: Commit**

```bash
cd backend
git add app/schemas/transaction.py app/routers/transactions.py tests/test_transactions.py
git commit -m "feat(transactions): add suggestions endpoint for repeated transaction autocomplete"
```

---

### Task 2: Store — ação `fetchSuggestions`

**Files:**
- Modify: `frontend/src/stores/transactions.js`

**Interfaces:**
- Produces: `useTransactionsStore().fetchSuggestions(query: string): Promise<Array<{description, amount, category_id, type}>>`. Consumido pela Task 3.
- Consumes: `api` de `frontend/src/services/api.js` (já existe).

- [ ] **Step 1: Adicionar a ação ao store**

Em `frontend/src/stores/transactions.js`, adicione a função `fetchSuggestions` após `fetchCategories` (antes de `createTransaction`):

```js
  async function fetchSuggestions(query) {
    const { data } = await api.get('/transactions/suggestions', { params: { q: query } })
    return data
  }
```

Atualize o `return` do store (última linha da função `defineStore`) para incluir a nova ação:

```js
  return { items, total, categories, loading, fetchTransactions, fetchCategories, createTransaction, deleteTransaction, createCategory, fetchSuggestions }
```

- [ ] **Step 2: Verificar que o build não quebra**

Run: `cd frontend && npm run build`
Expected: build succeeds (a ação ainda não é chamada por nenhum componente, só valida sintaxe).

- [ ] **Step 3: Commit**

```bash
cd frontend
git add src/stores/transactions.js
git commit -m "feat(transactions): add fetchSuggestions action to transactions store"
```

---

### Task 3: Dropdown de sugestões em `TransactionsView.vue`

**Files:**
- Modify: `frontend/src/views/TransactionsView.vue`

**Interfaces:**
- Consumes: `useTransactionsStore().fetchSuggestions(query)` (Task 2).
- Produces: nenhuma interface nova para outras tasks (última task deste sub-projeto).

- [ ] **Step 1: Adicionar estado e lógica de busca com debounce**

Em `frontend/src/views/TransactionsView.vue`, no `<script setup>`, adicione as declarações de estado logo após `const categoryError = ref('')`:

```js
const suggestions = ref([])
const showSuggestions = ref(false)
let debounceTimer = null

watch(() => form.value.description, (newVal) => {
  clearTimeout(debounceTimer)
  if (!newVal || newVal.length < 2) {
    suggestions.value = []
    showSuggestions.value = false
    return
  }
  debounceTimer = setTimeout(async () => {
    suggestions.value = await store.fetchSuggestions(newVal)
    showSuggestions.value = suggestions.value.length > 0
  }, 300)
})

function applySuggestion(suggestion) {
  form.value.description = suggestion.description
  form.value.amount = suggestion.amount
  form.value.category_id = suggestion.category_id
  form.value.type = suggestion.type
  showSuggestions.value = false
  suggestions.value = []
}
```

Este `watch` fica ao lado do `watch` já existente sobre `form.value.is_recurring` (linhas 23-27 do arquivo atual) — Vue suporta múltiplos `watch` no mesmo componente sem conflito.

- [ ] **Step 2: Adicionar o dropdown ao template**

No `<template>`, o campo de Descrição atualmente é:

```html
        <div class="form-group" style="grid-column:1/-1">
          <label class="form-label">Descrição</label>
          <input v-model="form.description" class="form-input" required placeholder="Ex: Conta de luz" />
        </div>
```

Substitua por (adiciona `position:relative` no wrapper para o dropdown se posicionar, `@focus`/`@blur` para mostrar/esconder ao interagir com o campo, e o bloco do dropdown):

```html
        <div class="form-group" style="grid-column:1/-1;position:relative">
          <label class="form-label">Descrição</label>
          <input
            v-model="form.description" class="form-input" required placeholder="Ex: Conta de luz"
            @focus="showSuggestions = suggestions.length > 0"
            @blur="setTimeout(() => showSuggestions = false, 150)"
          />
          <div v-if="showSuggestions" class="suggestions-dropdown">
            <div
              v-for="(s, i) in suggestions" :key="i"
              class="suggestion-item"
              @mousedown.prevent="applySuggestion(s)"
            >
              {{ s.description }} — {{ formatCurrency(s.amount) }}
            </div>
          </div>
        </div>
```

Nota: `@mousedown.prevent` (em vez de `@click`) é usado no item da sugestão porque o evento `blur` do input dispara antes de um `click` normal completar, fechando o dropdown antes do clique ser registrado — `mousedown` dispara antes do `blur`, e `.prevent` evita que o input perca o foco de um jeito que atrapalhe a seleção. O `setTimeout` de 150ms no `@blur` do input é a mesma técnica: dá tempo do `mousedown` do item processar antes do dropdown sumir.

- [ ] **Step 3: Adicionar os estilos do dropdown**

No `<style scoped>` de `TransactionsView.vue`, adicione ao final (antes do fechamento `</style>`):

```css
.suggestions-dropdown {
  position: absolute; top: 100%; left: 0; right: 0; z-index: 10;
  background: var(--bg-input); border: 1px solid var(--border-subtle);
  border-radius: var(--radius-sm); margin-top: 0.25rem;
  max-height: 220px; overflow-y: auto;
}
.suggestion-item {
  padding: 0.625rem 0.875rem; font-size: var(--font-size-sm); cursor: pointer;
  transition: background var(--transition-fast);
}
.suggestion-item:hover { background: var(--bg-card-hover); }
.suggestion-item:not(:last-child) { border-bottom: 1px solid var(--border-subtle); }
```

- [ ] **Step 4: Verificar visualmente no browser**

Com `docker compose up -d --build` (ou dev server local), na tela de Transações: criar uma transação "Mercado" R$980. Abrir o formulário de nova transação de novo, digitar "merc" no campo Descrição — confirmar que o dropdown aparece com "Mercado — R$ 980,00" após ~300ms. Clicar na sugestão — confirmar que descrição, valor, categoria e tipo são preenchidos, e que data/recorrência não mudam. Digitar só 1 caractere — confirmar que nenhuma busca é feita (sem dropdown). Clicar fora do campo — confirmar que o dropdown fecha.

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/views/TransactionsView.vue
git commit -m "feat(transactions): add repeated-transaction autocomplete dropdown"
```

---

### Task 4: Verificação final end-to-end

**Files:**
- Nenhum arquivo novo — apenas verificação manual via Chrome automation.

**Interfaces:**
- Consumes: todas as tasks anteriores.
- Produces: nada (task de verificação).

- [ ] **Step 1: Rodar a suite de testes do backend inteira**

Run: `cd backend && source .venv/bin/activate && pytest -v`
Expected: todos os testes passam, incluindo os 6 novos deste plano. (Nota: se `test_income.py::test_income_summary_average` falhar, isso é uma falha pré-existente não relacionada a este plano — sensível à data corrente do sistema, já documentada como débito técnico separado.)

- [ ] **Step 2: Rebuild e subir o ambiente completo**

```bash
docker compose up -d --build
```

Expected: backend e frontend sobem sem erro.

- [ ] **Step 3: Percorrer o fluxo completo no browser**

1. Login em uma conta existente (ou criar uma nova).
2. Criar duas transações com a mesma descrição em datas diferentes e valores diferentes (ex: "Uber" R$25 em uma data, "Uber" R$40 em outra data mais recente).
3. Abrir o formulário de nova transação, digitar "uber" — confirmar que a sugestão mostrada é a mais recente (R$40, não R$25).
4. Clicar na sugestão — confirmar preenchimento de descrição/valor/categoria/tipo, sem alterar a data (que deve continuar sendo a data padrão de hoje ou a que já estava selecionada).
5. Testar com uma categoria de receita: criar uma transação de receita "Freela" R$500, digitar "freela" no formulário — confirmar que ao clicar na sugestão o campo Tipo muda para "Receita" e a lista de categorias do dropdown de categoria (que já filtra por tipo) atualiza para mostrar só categorias de receita.

- [ ] **Step 4: Checar console do browser por erros**

Usando `read_console_messages` (Chrome automation) com `onlyErrors: true` na tela de Transações — nenhum erro de JS deve aparecer.

- [ ] **Step 5: Rodar build de produção uma última vez**

```bash
cd frontend && npm run build
```

Expected: build succeeds sem warnings novos.

- [ ] **Step 6: Commit final (se houver ajustes desta verificação)**

Se a verificação não encontrar nada para corrigir, não é necessário commit nesta task. Se algum ajuste pontual for necessário, commitar separadamente com mensagem descritiva do que foi ajustado.

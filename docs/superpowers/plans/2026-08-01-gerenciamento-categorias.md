# Gerenciamento de Categorias Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar seed de categorias padrão e limite de gasto mensal por categoria (com medidor visual de uso), primeiro de quatro sub-projetos do conjunto de planejamento financeiro solicitado pelo usuário.

**Architecture:** Backend ganha um campo novo em `Category` (`monthly_limit`), um endpoint de seed idempotente, e o `GET /categories` passa a incluir o uso agregado do mês corrente por categoria (uma query `GROUP BY`, sem N+1). Frontend ganha uma view nova (`CategoriesView.vue`) com duas seções — lista geral com modal de edição, e cards de orçamento com barra de progresso — seguindo os padrões visuais e de store já estabelecidos no app (tokens CSS do redesign, Pinia store por domínio, `AppIcon` para ícones).

**Tech Stack:** FastAPI + SQLAlchemy async + SQLite (backend), Vue 3 Composition API + Pinia + Vite (frontend). Sem bibliotecas novas.

## Global Constraints

- O projeto não usa Alembic — `create_all_tables()` no lifespan da app só cria tabelas que não existem, não altera tabelas existentes. Adicionar a coluna `monthly_limit` em `categories` (tabela que já existe em bancos com dados) precisa de uma migração leve manual, separada do `create_all`.
- `monthly_limit` é nullable e só tem edição exposta na UI para categorias `type == 'expense'` — o campo existe no modelo para ambos os tipos (simplicidade, não vale um segundo modelo), mas a UI nunca oferece essa edição para `type == 'income'`.
- `current_month_usage` (uso do mês corrente) soma **todas** as transações da categoria no período (sem filtrar por `Transaction.type`) — decisão explícita do usuário durante o brainstorm, não filtrar só expense mesmo que o caso de uso prático seja quase sempre expense.
- Período do mês corrente: do dia 1 do mês calendário atual até hoje (mesmo padrão já usado em `backend/app/routers/dashboard.py`: `date(ref_year, ref_month, 1)` até `date.today()`, sem depender de `monthrange` para o fim, já que "até hoje" não é o último dia do mês).
- Seed de categorias é idempotente: nunca duplica por nome (comparação case-insensitive) por usuário.
- Sem alerta/notificação quando o limite é ultrapassado — só mudança de cor na barra de progresso (três faixas: verde até 80%, terracota de 80% a 100%, terracota escuro acima de 100%).
- Sem testes automatizados de frontend neste projeto (confirmado nos specs anteriores) — verificação do frontend é manual via browser. Backend usa `pytest` + `httpx`, seguindo o padrão de `backend/tests/test_categories.py` (fixture `client`, helper `register_and_login`).
- Cores da paleta atual do frontend (para as categorias-seed, já que precisam de alguma cor): usar tons dentro da família aprovada do redesign — `#c17a54` (terracota principal), `#b8563a` (terracota escuro), `#7a9b7e` (verde envelhecido), `#8a9bb0` (azul acinzentado), variando entre as 11 categorias para dar alguma distinção visual em gráficos.

---

### Task 1: Campo `monthly_limit` no modelo, schema e migração manual

**Files:**
- Modify: `backend/app/models/category.py`
- Modify: `backend/app/schemas/category.py`
- Create: `backend/app/migrations/__init__.py` (pacote vazio, se `backend/app/migrations/` não existir)
- Create: `backend/app/migrations/add_monthly_limit.py`
- Modify: `backend/app/main.py`
- Test: `backend/tests/test_categories.py` (adiciona um teste ao arquivo existente)

**Interfaces:**
- Produces: `Category.monthly_limit: float | None` no modelo SQLAlchemy. `CategoryResponse.monthly_limit: float | None` e `CategoryUpdate.monthly_limit: float | None = None` nos schemas Pydantic — consumidos pela Task 2 (endpoint de uso) e pelas tasks de frontend.
- Consumes: nada de tasks anteriores (task inicial).

- [ ] **Step 1: Adicionar o campo ao modelo**

Em `backend/app/models/category.py`, adicione a linha do campo novo dentro da classe `Category`, após `icon`:

```python
    icon: Mapped[str] = mapped_column(String(50), nullable=False, default="tag")
    monthly_limit: Mapped[float | None] = mapped_column(Float, nullable=True)
```

Adicione `Float` ao import do topo do arquivo (atualmente `from sqlalchemy import Integer, String, ForeignKey, Enum as SAEnum`):

```python
from sqlalchemy import Integer, String, Float, ForeignKey, Enum as SAEnum
```

- [ ] **Step 2: Atualizar os schemas Pydantic**

Em `backend/app/schemas/category.py`, o arquivo inteiro deve ficar:

```python
from pydantic import BaseModel
from app.models.category import CategoryType


class CategoryCreate(BaseModel):
    name: str
    type: CategoryType
    color: str = "#6C63FF"
    icon: str = "tag"
    monthly_limit: float | None = None


class CategoryUpdate(BaseModel):
    name: str
    type: CategoryType
    color: str
    icon: str
    monthly_limit: float | None = None


class CategoryResponse(BaseModel):
    id: int
    user_id: int
    name: str
    type: CategoryType
    color: str
    icon: str
    monthly_limit: float | None
    current_month_usage: float = 0.0

    model_config = {"from_attributes": True}
```

Note que `current_month_usage` tem default `0.0` e não vem do modelo SQLAlchemy diretamente (não existe essa coluna no banco) — é um campo calculado que os endpoints vão popular manualmente antes de serializar (Task 2 faz isso no `GET /categories`; os demais endpoints que retornam `CategoryResponse` — `create_category`, `update_category` — vão precisar passar esse campo explicitamente também, ou ele fica `0.0` por default nesses casos, o que é aceitável: uma categoria recém-criada/editada não precisa refletir uso agregado na mesma resposta).

- [ ] **Step 3: Criar a migração manual**

Crie o diretório `backend/app/migrations/` se não existir, com um `__init__.py` vazio.

Crie `backend/app/migrations/add_monthly_limit.py`:

```python
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine


async def add_monthly_limit_column(engine: AsyncEngine) -> None:
    """Adiciona a coluna monthly_limit a categories se ela ainda não existir.

    Necessário porque o projeto não usa Alembic — create_all_tables()
    só cria tabelas novas, não altera tabelas existentes.
    """
    async with engine.connect() as conn:
        result = await conn.execute(text("PRAGMA table_info(categories)"))
        columns = [row[1] for row in result.fetchall()]
        if "monthly_limit" not in columns:
            await conn.execute(text("ALTER TABLE categories ADD COLUMN monthly_limit FLOAT"))
            await conn.commit()
```

- [ ] **Step 4: Rodar a migração no startup da aplicação**

Em `backend/app/main.py`, modifique a função `lifespan` para chamar a migração logo após `create_all_tables()`:

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_all_tables, engine
from app.migrations.add_monthly_limit import add_monthly_limit_column
from app.routers import auth as auth_router, categories as categories_router, transactions as transactions_router, income as income_router, plans as plans_router, dashboard as dashboard_router
from app.models import user  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_all_tables()
    await add_monthly_limit_column(engine)
    yield
```

(mantenha o resto do arquivo — CORS, `app.include_router(...)` — inalterado; só a função `lifespan` e os imports do topo mudam). Confira que `engine` já é exportado por `backend/app/database.py` (é uma variável de módulo criada via `create_async_engine` — se o nome de import não bater, ajuste para o nome real da variável do engine nesse arquivo).

- [ ] **Step 5: Escrever o teste da migração e do campo novo**

Adicione ao final de `backend/tests/test_categories.py`:

```python
@pytest.mark.asyncio
async def test_create_category_with_monthly_limit(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.post("/categories", json={
        "name": "Alimentação",
        "type": "expense",
        "color": "#c17a54",
        "icon": "tag",
        "monthly_limit": 1000.0
    }, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["monthly_limit"] == 1000.0
    assert data["current_month_usage"] == 0.0


@pytest.mark.asyncio
async def test_update_category_monthly_limit(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Transporte", "type": "expense", "color": "#c17a54", "icon": "tag"
    }, headers=headers)
    cat_id = create.json()["id"]
    assert create.json()["monthly_limit"] is None

    response = await client.put(f"/categories/{cat_id}", json={
        "name": "Transporte", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 300.0
    }, headers=headers)
    assert response.status_code == 200
    assert response.json()["monthly_limit"] == 300.0
```

- [ ] **Step 6: Rodar os testes**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_categories.py -v`
Expected: todos os testes do arquivo passam, incluindo os 2 novos (o banco de teste é recriado do zero via `Base.metadata.create_all` no `conftest.py`, então já nasce com a coluna nova — a migração manual só é exercitada de fato contra o banco real de dev/prod, não nos testes).

- [ ] **Step 7: Commit**

```bash
cd backend
git add app/models/category.py app/schemas/category.py app/migrations/ app/main.py tests/test_categories.py
git commit -m "feat(categories): add monthly_limit field with manual sqlite migration"
```

---

### Task 2: Endpoint de seed de categorias padrão

**Files:**
- Modify: `backend/app/routers/categories.py`
- Test: `backend/tests/test_categories.py`

**Interfaces:**
- Produces: `POST /categories/seed-defaults` → `list[CategoryResponse]` (só as categorias efetivamente criadas, categorias já existentes por nome são puladas). Consumido pela Task 5 (botão "Usar categorias padrão" no frontend).
- Consumes: `CategoryCreate`, `CategoryResponse` (Task 1).

- [ ] **Step 1: Escrever os testes primeiro**

Adicione ao final de `backend/tests/test_categories.py`:

```python
@pytest.mark.asyncio
async def test_seed_defaults_creates_eleven_categories(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.post("/categories/seed-defaults", headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert len(data) == 11
    names = {c["name"] for c in data}
    assert "Moradia" in names
    assert "Salário" in names


@pytest.mark.asyncio
async def test_seed_defaults_is_idempotent(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    await client.post("/categories/seed-defaults", headers=headers)
    response = await client.post("/categories/seed-defaults", headers=headers)
    assert response.status_code == 201
    assert response.json() == []

    list_response = await client.get("/categories", headers=headers)
    assert len(list_response.json()) == 11


@pytest.mark.asyncio
async def test_seed_defaults_skips_existing_by_name_case_insensitive(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    await client.post("/categories", json={
        "name": "moradia", "type": "expense", "color": "#000000", "icon": "tag"
    }, headers=headers)

    response = await client.post("/categories/seed-defaults", headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert len(data) == 10
    names = {c["name"] for c in data}
    assert "Moradia" not in names

    list_response = await client.get("/categories", headers=headers)
    assert len(list_response.json()) == 11
```

- [ ] **Step 2: Rodar os testes para confirmar que falham**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_categories.py -k seed_defaults -v`
Expected: FAIL com 404 (rota não existe ainda).

- [ ] **Step 3: Implementar o endpoint**

Em `backend/app/routers/categories.py`, adicione a constante da lista padrão logo após os imports (antes de `router = APIRouter(...)`):

```python
DEFAULT_CATEGORIES = [
    {"name": "Moradia", "type": "expense", "color": "#c17a54", "icon": "bank"},
    {"name": "Alimentação", "type": "expense", "color": "#7a9b7e", "icon": "tag"},
    {"name": "Transporte", "type": "expense", "color": "#8a9bb0", "icon": "transactions"},
    {"name": "Saúde", "type": "expense", "color": "#b8563a", "icon": "tag"},
    {"name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag"},
    {"name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet"},
    {"name": "Educação", "type": "expense", "color": "#8a9bb0", "icon": "tag"},
    {"name": "Contas fixas", "type": "expense", "color": "#b8563a", "icon": "bank"},
    {"name": "Salário", "type": "income", "color": "#7a9b7e", "icon": "trending-up"},
    {"name": "Freelance", "type": "income", "color": "#c17a54", "icon": "trending-up"},
    {"name": "Outros rendimentos", "type": "income", "color": "#8a9bb0", "icon": "trending-up"},
]
```

Adicione o endpoint logo após `create_category` (antes de `list_categories`):

```python
@router.post("/seed-defaults", response_model=list[CategoryResponse], status_code=201)
async def seed_default_categories(
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    existing_result = await session.execute(
        select(Category.name).where(Category.user_id == current_user.id)
    )
    existing_names = {name.lower() for (name,) in existing_result.all()}

    created = []
    for default in DEFAULT_CATEGORIES:
        if default["name"].lower() in existing_names:
            continue
        cat = Category(**default, user_id=current_user.id)
        session.add(cat)
        created.append(cat)

    if created:
        await session.commit()
        for cat in created:
            await session.refresh(cat)

    return created
```

Nota: `CategoryResponse` requer `current_month_usage` — como o schema tem `default=0.0` (Task 1, Step 2), FastAPI popula automaticamente esse valor ao serializar um objeto `Category` do banco que não tem esse atributo, então nenhuma mudança adicional é necessária aqui.

- [ ] **Step 4: Rodar os testes de novo**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_categories.py -k seed_defaults -v`
Expected: PASS nos 3 testes.

- [ ] **Step 5: Rodar a suite inteira do arquivo pra garantir que nada quebrou**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_categories.py -v`
Expected: todos passam (os 4 antigos + 2 da Task 1 + 3 desta task = 9 testes).

- [ ] **Step 6: Commit**

```bash
cd backend
git add app/routers/categories.py tests/test_categories.py
git commit -m "feat(categories): add idempotent default-categories seed endpoint"
```

---

### Task 3: Uso do mês corrente por categoria em `GET /categories`

**Files:**
- Modify: `backend/app/routers/categories.py`
- Test: `backend/tests/test_categories.py`

**Interfaces:**
- Produces: `GET /categories` agora popula `current_month_usage` em cada item da resposta com a soma real de transações do mês corrente. Consumido pela Task 6 (seção B do frontend, cards de orçamento).
- Consumes: `Category.monthly_limit`, `CategoryResponse.current_month_usage` (Task 1). Modelo `Transaction` (já existente em `backend/app/models/transaction.py`, campos `category_id`, `amount`, `date`, `user_id`).

- [ ] **Step 1: Escrever os testes primeiro**

Adicione ao final de `backend/tests/test_categories.py`. Este teste precisa criar transações, então importe `date` no topo do arquivo se ainda não estiver importado:

```python
from datetime import date
```

```python
@pytest.mark.asyncio
async def test_list_categories_includes_current_month_usage(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}

    cat = await client.post("/categories", json={
        "name": "Alimentação", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 1000.0
    }, headers=headers)
    cat_id = cat.json()["id"]

    today = date.today()
    await client.post("/transactions", json={
        "description": "Mercado", "amount": 300.0, "date": today.isoformat(),
        "type": "expense", "category_id": cat_id, "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "description": "Mercado 2", "amount": 150.0, "date": today.isoformat(),
        "type": "expense", "category_id": cat_id, "is_recurring": False
    }, headers=headers)

    response = await client.get("/categories", headers=headers)
    assert response.status_code == 200
    data = response.json()
    found = next(c for c in data if c["id"] == cat_id)
    assert found["current_month_usage"] == 450.0


@pytest.mark.asyncio
async def test_list_categories_usage_excludes_previous_month(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}

    cat = await client.post("/categories", json={
        "name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag"
    }, headers=headers)
    cat_id = cat.json()["id"]

    old_date = date.today().replace(day=1) - __import__("datetime").timedelta(days=5)
    await client.post("/transactions", json={
        "description": "Cinema mês passado", "amount": 80.0, "date": old_date.isoformat(),
        "type": "expense", "category_id": cat_id, "is_recurring": False
    }, headers=headers)

    response = await client.get("/categories", headers=headers)
    found = next(c for c in response.json() if c["id"] == cat_id)
    assert found["current_month_usage"] == 0.0
```

- [ ] **Step 2: Rodar os testes para confirmar que falham**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_categories.py -k current_month_usage -v`
Expected: FAIL (`current_month_usage` sempre `0.0`, teste do primeiro caso espera `450.0`).

- [ ] **Step 3: Implementar o cálculo no endpoint**

Substitua a função `list_categories` inteira em `backend/app/routers/categories.py`:

```python
@router.get("", response_model=list[CategoryResponse])
async def list_categories(
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(select(Category).where(Category.user_id == current_user.id))
    categories = result.scalars().all()

    today = date.today()
    month_start = today.replace(day=1)

    usage_result = await session.execute(
        select(Transaction.category_id, func.sum(Transaction.amount))
        .where(
            and_(
                Transaction.user_id == current_user.id,
                Transaction.date >= month_start,
                Transaction.date <= today,
            )
        )
        .group_by(Transaction.category_id)
    )
    usage_by_category = {cat_id: total for cat_id, total in usage_result.all() if cat_id is not None}

    response = []
    for cat in categories:
        item = CategoryResponse.model_validate(cat)
        item.current_month_usage = round(usage_by_category.get(cat.id, 0.0) or 0.0, 2)
        response.append(item)
    return response
```

Adicione os imports necessários no topo de `backend/app/routers/categories.py` (o arquivo hoje só importa `select` do SQLAlchemy):

```python
from datetime import date
from sqlalchemy import select, func, and_
from app.models.transaction import Transaction
```

(mantenha os imports já existentes — `APIRouter`, `Depends`, `HTTPException`, `AsyncSession`, `get_async_session`, `get_current_user`, `User`, `Category`, os schemas — e apenas acrescente estes três).

- [ ] **Step 4: Rodar os testes de novo**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_categories.py -k current_month_usage -v`
Expected: PASS nos 2 testes.

- [ ] **Step 5: Rodar a suite inteira**

Run: `cd backend && source .venv/bin/activate && pytest -v`
Expected: todos os testes do projeto passam (não só `test_categories.py` — confirma que a mudança na query de `list_categories` não quebrou nada em `test_transactions.py` ou `test_dashboard.py`, que podem chamar `GET /categories` indiretamente).

- [ ] **Step 6: Commit**

```bash
cd backend
git add app/routers/categories.py tests/test_categories.py
git commit -m "feat(categories): compute current_month_usage per category via aggregated query"
```

---

### Task 4: Store e ícone novo no frontend

**Files:**
- Create: `frontend/src/stores/categories.js`
- Modify: `frontend/src/components/common/AppIcon.vue`

**Interfaces:**
- Produces: Pinia store `useCategoriesStore` com estado `{ items: Ref<Category[]>, loading: Ref<boolean> }` e ações `fetchCategories()`, `seedDefaults()`, `updateCategory(id, payload)`. Formato de `Category` no `items`: `{ id, user_id, name, type, color, icon, monthly_limit, current_month_usage }`. Consumido pelas Tasks 5 e 6.
- Consumes: `api` de `frontend/src/services/api.js` (já existe, injeta token JWT automaticamente).

Este é um store novo e independente — não reutiliza `stores/transactions.js` (que também tem uma cópia de `categories`/`fetchCategories`/`createCategory` usada só pelo formulário de transação). São dois consumidores diferentes do mesmo recurso de API; manter stores separados evita acoplar a tela de gerenciamento ao store de transações.

- [ ] **Step 1: Criar o store**

```js
import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useCategoriesStore = defineStore('categories', () => {
  const items = ref([])
  const loading = ref(false)

  async function fetchCategories() {
    loading.value = true
    try {
      const { data } = await api.get('/categories')
      items.value = data
    } finally {
      loading.value = false
    }
  }

  async function seedDefaults() {
    const { data } = await api.post('/categories/seed-defaults')
    if (data.length) {
      await fetchCategories()
    }
    return data
  }

  async function updateCategory(id, payload) {
    const { data } = await api.put(`/categories/${id}`, payload)
    const index = items.value.findIndex((c) => c.id === id)
    if (index !== -1) items.value[index] = data
    return data
  }

  return { items, loading, fetchCategories, seedDefaults, updateCategory }
})
```

- [ ] **Step 2: Adicionar ícone de categoria ao `AppIcon.vue`**

Em `frontend/src/components/common/AppIcon.vue`, adicione uma entrada `categories` ao objeto `paths` (um ícone de etiqueta/tag simples, distinto do `tag` genérico já usado como default de categoria no backend — aqui é o ícone de navegação da sidebar, não da categoria em si):

```js
  categories: 'M20.59 13.41L13.42 20.58a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82zM7 7h.01',
```

Adicione essa linha ao objeto `paths` existente (após a linha de `logout`, por exemplo — a ordem não importa).

- [ ] **Step 3: Verificar que o store não quebra o build**

Run: `cd frontend && npm run build`
Expected: build succeeds (o store ainda não é importado por nenhuma view, então isso só valida sintaxe).

- [ ] **Step 4: Commit**

```bash
cd frontend
git add src/stores/categories.js src/components/common/AppIcon.vue
git commit -m "feat(categories): add categories store and sidebar icon"
```

---

### Task 5: View de Categorias — Seção A (lista + seed + modal de edição)

**Files:**
- Create: `frontend/src/views/CategoriesView.vue`
- Modify: `frontend/src/router/index.js`
- Modify: `frontend/src/components/layout/AppSidebar.vue`

**Interfaces:**
- Consumes: `useCategoriesStore` (Task 4: `items`, `loading`, `fetchCategories`, `seedDefaults`, `updateCategory`), `AppIcon` (ícone `categories` da Task 4), `AppLayout` (já existe, `frontend/src/components/layout/AppLayout.vue`).
- Produces: rota `/categories` (`name: 'Categories'`), consumida como link de navegação; nenhuma interface de código nova para outras tasks (Task 6 estende o mesmo arquivo `CategoriesView.vue`, não importa nada desta task além do que já está no mesmo arquivo).

- [ ] **Step 1: Adicionar a rota**

Em `frontend/src/router/index.js`, adicione a nova rota ao array `routes`, entre `/plans` e `/reports`:

```js
  { path: '/categories', name: 'Categories', component: () => import('@/views/CategoriesView.vue') },
```

- [ ] **Step 2: Adicionar o item de navegação na sidebar**

Em `frontend/src/components/layout/AppSidebar.vue`, adicione ao array `navItems`, entre o item de Planos e o de Relatórios:

```js
  { path: '/categories', icon: 'categories', label: 'Categorias' },
```

- [ ] **Step 3: Criar a view com a Seção A**

Crie `frontend/src/views/CategoriesView.vue`. Esta task implementa só a Seção A (lista + seed + modal) — a Seção B (cards de orçamento) é adicionada na Task 6 no mesmo arquivo.

```vue
<script setup>
import { ref, onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useCategoriesStore } from '@/stores/categories'

const store = useCategoriesStore()

const editingCategory = ref(null)
const editForm = ref({ name: '', type: 'expense', color: '#c17a54', icon: 'tag', monthly_limit: '' })
const editError = ref('')
const seeding = ref(false)

function openEdit(category) {
  editingCategory.value = category
  editForm.value = {
    name: category.name,
    type: category.type,
    color: category.color,
    icon: category.icon,
    monthly_limit: category.monthly_limit != null ? String(category.monthly_limit) : '',
  }
  editError.value = ''
}

function closeEdit() {
  editingCategory.value = null
}

async function saveEdit() {
  editError.value = ''
  try {
    const payload = {
      name: editForm.value.name,
      type: editForm.value.type,
      color: editForm.value.color,
      icon: editForm.value.icon,
      monthly_limit: editForm.value.type === 'expense' && editForm.value.monthly_limit
        ? parseFloat(editForm.value.monthly_limit)
        : null,
    }
    await store.updateCategory(editingCategory.value.id, payload)
    closeEdit()
  } catch (e) {
    editError.value = e.response?.data?.detail || 'Erro ao salvar categoria'
  }
}

async function handleSeed() {
  seeding.value = true
  try {
    await store.seedDefaults()
  } finally {
    seeding.value = false
  }
}

onMounted(() => store.fetchCategories())
</script>

<template>
  <AppLayout>
    <div class="page-header" style="display:flex;justify-content:space-between;align-items:flex-start">
      <div>
        <h1 class="page-title">Categorias</h1>
        <p class="page-subtitle">Gerencie suas categorias e limites de gasto mensal</p>
      </div>
      <button class="btn btn-secondary" @click="handleSeed" :disabled="seeding">
        {{ seeding ? 'Adicionando...' : '+ Usar categorias padrão' }}
      </button>
    </div>

    <div class="card" style="margin-bottom:1.5rem">
      <h3 class="font-semibold" style="margin-bottom:1rem">Todas as categorias</h3>
      <div v-if="store.loading" style="text-align:center;padding:2rem;color:var(--text-muted)">Carregando...</div>
      <div v-else-if="!store.items.length" style="text-align:center;padding:2rem;color:var(--text-muted)">
        Nenhuma categoria cadastrada. Use o botão acima para começar com sugestões prontas.
      </div>
      <table v-else class="cat-table">
        <thead>
          <tr><th>Nome</th><th>Tipo</th><th>Limite mensal</th><th></th></tr>
        </thead>
        <tbody>
          <tr v-for="cat in store.items" :key="cat.id" class="cat-row" @click="openEdit(cat)">
            <td>
              <span class="cat-color-dot" :style="{ background: cat.color }" />
              {{ cat.name }}
            </td>
            <td>
              <span :class="['badge', cat.type === 'income' ? 'badge-success' : 'badge-info']">
                {{ cat.type === 'income' ? 'Receita' : 'Gasto' }}
              </span>
            </td>
            <td class="text-muted">
              {{ cat.type === 'expense' && cat.monthly_limit != null
                  ? new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(cat.monthly_limit)
                  : '—' }}
            </td>
            <td class="text-muted text-sm">Editar</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="editingCategory" class="modal-backdrop" @click.self="closeEdit">
      <div class="card modal-content animate-fade-in">
        <h3 class="font-semibold" style="margin-bottom:1rem">Editar categoria</h3>
        <form @submit.prevent="saveEdit" style="display:flex;flex-direction:column;gap:1rem">
          <div class="form-group">
            <label class="form-label">Nome</label>
            <input v-model="editForm.name" class="form-input" required />
          </div>
          <div class="form-group">
            <label class="form-label">Tipo</label>
            <select v-model="editForm.type" class="form-input">
              <option value="expense">Gasto</option>
              <option value="income">Receita</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Cor</label>
            <input v-model="editForm.color" class="form-input" type="color" />
          </div>
          <div class="form-group" v-if="editForm.type === 'expense'">
            <label class="form-label">Limite mensal (R$) — opcional</label>
            <input v-model="editForm.monthly_limit" class="form-input" type="number" step="0.01" min="0" placeholder="Sem limite" />
          </div>
          <div v-if="editError" class="error-msg">{{ editError }}</div>
          <div style="display:flex;gap:0.75rem">
            <button type="submit" class="btn btn-primary">Salvar</button>
            <button type="button" class="btn btn-secondary" @click="closeEdit">Cancelar</button>
          </div>
        </form>
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
.cat-table { width: 100%; border-collapse: collapse; }
.cat-table th { text-align: left; padding: 0.5rem 0.75rem; font-size: var(--font-size-xs); color: var(--text-muted); font-weight: 600; border-bottom: 1px solid var(--border-subtle); }
.cat-table td { padding: 0.75rem; border-bottom: 1px solid var(--border-subtle); font-size: var(--font-size-sm); }
.cat-table tr:last-child td { border-bottom: none; }
.cat-row { cursor: pointer; transition: background var(--transition-fast); }
.cat-row:hover { background: var(--bg-card-hover); }
.cat-color-dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 0.5rem; vertical-align: middle; }
.modal-backdrop {
  position: fixed; inset: 0; background: rgba(0,0,0,0.6);
  display: flex; align-items: center; justify-content: center; z-index: 100;
}
.modal-content { width: 100%; max-width: 420px; margin: 1rem; }
</style>
```

Nota: `.error-msg` já é uma classe global definida em `frontend/src/assets/main.css` (promovida lá durante o redesign visual) — não precisa de estilo scoped adicional neste arquivo.

- [ ] **Step 4: Verificar visualmente no browser**

Com `docker compose up -d --build` (ou dev server local), navegar até `/categories`, confirmar: link "Categorias" aparece na sidebar com ícone, lista vazia mostra estado vazio, clicar em "Usar categorias padrão" popula a lista com 11 categorias, clicar de novo no botão não duplica, clicar em uma categoria abre o modal, editar e salvar reflete a mudança na lista sem reload de página.

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/views/CategoriesView.vue src/router/index.js src/components/layout/AppSidebar.vue
git commit -m "feat(categories): add categories management view with seed and edit modal"
```

---

### Task 6: Seção B — cards de orçamento com medidor de progresso

**Files:**
- Modify: `frontend/src/views/CategoriesView.vue`

**Interfaces:**
- Consumes: `useCategoriesStore.items` (Task 4/5) — usa os campos `monthly_limit` e `current_month_usage` já presentes em cada item.
- Produces: nenhuma interface nova para outras tasks (última task deste sub-projeto).

- [ ] **Step 1: Adicionar a computed de categorias com orçamento**

Em `frontend/src/views/CategoriesView.vue`, no `<script setup>`, adicione o import de `computed` (altere a linha `import { ref, onMounted } from 'vue'` para `import { ref, computed, onMounted } from 'vue'`) e adicione, após a declaração de `store`:

```js
const budgetedCategories = computed(() =>
  store.items.filter((c) => c.type === 'expense' && c.monthly_limit != null && c.monthly_limit > 0)
)

function usagePercent(cat) {
  return Math.round((cat.current_month_usage / cat.monthly_limit) * 100)
}

function usageColorClass(percent) {
  if (percent > 100) return 'usage-over'
  if (percent >= 80) return 'usage-warning'
  return 'usage-ok'
}

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}
```

- [ ] **Step 2: Adicionar a Seção B ao template**

No `<template>`, insira o bloco abaixo depois do `<div class="card" style="margin-bottom:1.5rem">...</div>` da Seção A (o card "Todas as categorias") e antes do `<div v-if="editingCategory" ...>` (o modal):

```html
    <div class="card">
      <h3 class="font-semibold" style="margin-bottom:1rem">Orçamento do mês</h3>
      <div v-if="!budgetedCategories.length" style="text-align:center;padding:2rem;color:var(--text-muted)">
        Nenhuma categoria com limite definido ainda. Clique em uma categoria de gasto acima para definir um limite mensal.
      </div>
      <div v-else class="budget-grid">
        <div v-for="cat in budgetedCategories" :key="cat.id" class="budget-card">
          <div class="budget-header">
            <span class="cat-color-dot" :style="{ background: cat.color }" />
            <span class="font-semibold text-sm">{{ cat.name }}</span>
          </div>
          <div class="progress-bar" style="margin:0.5rem 0">
            <div
              :class="['progress-fill', usageColorClass(usagePercent(cat))]"
              :style="{ width: Math.min(usagePercent(cat), 100) + '%' }"
            />
          </div>
          <div class="budget-footer text-muted text-sm">
            <span>{{ formatCurrency(cat.current_month_usage) }} / {{ formatCurrency(cat.monthly_limit) }}</span>
            <span :class="usageColorClass(usagePercent(cat))">{{ usagePercent(cat) }}%</span>
          </div>
        </div>
      </div>
    </div>
```

- [ ] **Step 3: Adicionar os estilos das faixas de cor**

No `<style scoped>` de `CategoriesView.vue`, adicione ao final:

```css
.budget-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1rem; }
.budget-card { background: var(--bg-input); border: 1px solid var(--border-subtle); border-radius: var(--radius-sm); padding: 1rem; }
.budget-header { display: flex; align-items: center; gap: 0.5rem; }
.budget-footer { display: flex; justify-content: space-between; }
.usage-ok { color: var(--accent-success); }
.usage-warning { color: var(--accent-primary); }
.usage-over { color: var(--accent-danger); }
.progress-fill.usage-ok { background: var(--accent-success); }
.progress-fill.usage-warning { background: var(--accent-primary); }
.progress-fill.usage-over { background: var(--accent-danger); }
```

Nota: `.progress-fill` e `.progress-bar` já são classes globais em `main.css` com um `background` padrão (`var(--accent-primary)`) e `transition: width`; as regras `.progress-fill.usage-*` acima sobrescrevem só a cor de fundo por especificidade de classe composta, sem conflito com a regra global.

- [ ] **Step 4: Verificar visualmente no browser**

Definir um limite mensal em uma categoria (via modal da Seção A), lançar transações nessa categoria (via `/transactions`) somando menos de 80%, depois mais de 80%, depois mais de 100% do limite — confirmar que a barra muda de verde para terracota para terracota escuro nos thresholds certos, e que o texto de porcentagem mostra o valor real mesmo acima de 100% (ex: "134%").

- [ ] **Step 5: Commit**

```bash
cd frontend
git add src/views/CategoriesView.vue
git commit -m "feat(categories): add monthly budget cards with usage meter"
```

---

### Task 7: Verificação final end-to-end

**Files:**
- Nenhum arquivo novo — apenas verificação manual via Chrome automation.

**Interfaces:**
- Consumes: todas as tasks anteriores.
- Produces: nada (task de verificação).

- [ ] **Step 1: Rodar a suite de testes do backend inteira**

Run: `cd backend && source .venv/bin/activate && pytest -v`
Expected: todos os testes passam, incluindo os 7 novos deste plano (2 da Task 1, 3 da Task 2, 2 da Task 3).

- [ ] **Step 2: Rebuild e subir o ambiente completo**

```bash
docker compose up -d --build
```

Expected: backend e frontend sobem sem erro.

- [ ] **Step 3: Percorrer o fluxo completo no browser**

1. Login em uma conta existente (ou criar uma nova).
2. Ir em "Categorias" — clicar "Usar categorias padrão", confirmar 11 categorias aparecem, clicar de novo confirma que não duplica.
3. Abrir o modal de uma categoria de gasto (ex: "Alimentação"), definir limite mensal de R$1000, salvar.
4. Ir em "Transações", lançar uma transação de R$300 na categoria "Alimentação".
5. Voltar em "Categorias" — confirmar que a Seção B mostra o card de "Alimentação" com "R$ 300,00 / R$ 1.000,00" e barra verde em ~30%.
6. Lançar mais transações na mesma categoria até passar de R$800 (80%) — confirmar mudança de cor pra terracota.
7. Lançar mais uma até passar de R$1000 (100%) — confirmar cor terracota escuro e percentual mostrando acima de 100%.
8. Confirmar que uma categoria de receita (ex: "Salário") não mostra nenhum campo de limite mensal no modal de edição.

- [ ] **Step 4: Checar console do browser por erros**

Usando `read_console_messages` (Chrome automation) com `onlyErrors: true` em cada tela visitada — nenhum erro de JS deve aparecer.

- [ ] **Step 5: Rodar build de produção uma última vez**

```bash
cd frontend && npm run build
```

Expected: build succeeds sem warnings novos.

- [ ] **Step 6: Commit final (se houver ajustes desta verificação)**

Se a verificação não encontrar nada para corrigir, não é necessário commit nesta task. Se algum ajuste pontual for necessário, commitar separadamente com mensagem descritiva do que foi ajustado.

# Algoritmo de Análise de Economia Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Comparar o gasto do mês corrente de cada categoria contra uma referência (limite cadastrado ou média histórica), classificar categorias como essenciais ou cortáveis, e exibir a análise com sugestões de corte na tela de Relatórios (hoje um stub vazio).

**Architecture:** Um novo router de backend (`GET /reports/savings-analysis`) calcula referência por categoria, aplica a regra de threshold/classificação, e retorna uma lista ordenada. `ReportsView.vue` consome esse endpoint e renderiza cards reutilizando o esquema visual de 3 faixas de cor já usado no medidor de orçamento (sub-projeto 1).

**Tech Stack:** FastAPI + SQLAlchemy async + SQLite (backend), Vue 3 Composition API + Pinia + Vite (frontend). Sem bibliotecas novas.

## Global Constraints

- Classificação essencial vs cortável é fixa em código (sem campo novo no banco, sem migração): nome da categoria bate case-insensitive com `"Moradia"`, `"Saúde"` ou `"Contas fixas"` → essencial; qualquer outro nome → cortável (inclui categorias criadas pelo usuário).
- Referência por categoria: `monthly_limit` se definido; senão, média do gasto nos 3 meses calendário **fechados** anteriores ao mês corrente (M-1, M-2, M-3 inteiros — não inclui o mês corrente, diferente do padrão de "últimos 3 meses corridos" já usado em `backend/app/routers/income.py`'s `/income/summary`); senão, categoria fica fora da análise. Um mês só entra no cálculo da média se teve pelo menos uma transação de gasto naquela categoria.
- Threshold de inclusão: `percent = (gasto_atual / referencia) * 100`; `percent < 80` não aparece na análise.
- Essencial acima de 80%: aparece só como aviso, `suggested_cut` sempre `null`.
- Cortável entre 80-100%: aparece como aviso, `suggested_cut` ainda `null` (não excedeu).
- Cortável acima de 100%: `suggested_cut = gasto_atual - referencia` (o excedente exato).
- Ordenação da lista: por `gasto_atual - referencia` decrescente (maior excedente absoluto primeiro).
- Só categorias `type == 'expense'`.
- Sem testes automatizados de frontend neste projeto — verificação manual via browser. Backend usa `pytest` + `httpx`, padrão de `backend/tests/test_categories.py` e `backend/tests/test_income.py` (fixture `client`, helper `register_and_login` de `backend/tests/helpers.py`).

---

### Task 1: Função de classificação essencial/cortável + testes unitários

**Files:**
- Create: `backend/app/services/savings_analysis.py`
- Test: `backend/tests/test_savings_analysis.py`

**Interfaces:**
- Produces: `is_essential_category(name: str) -> bool` em `backend/app/services/savings_analysis.py`. Consumido pela Task 2.
- Consumes: nada (task inicial, função pura sem dependência de banco).

Este módulo hospeda toda a lógica de negócio da análise (classificação, cálculo de referência, montagem do item de resultado) separada do router HTTP, seguindo o padrão já estabelecido no projeto de `backend/app/services/plan_simulator.py` e `backend/app/services/timeline_builder.py` — lógica pura e testável em `app/services/`, o router HTTP só orquestra queries e chama o service.

- [ ] **Step 1: Escrever o teste primeiro**

Crie `backend/tests/test_savings_analysis.py`:

```python
from app.services.savings_analysis import is_essential_category


def test_is_essential_category_matches_known_names():
    assert is_essential_category("Moradia") is True
    assert is_essential_category("Saúde") is True
    assert is_essential_category("Contas fixas") is True


def test_is_essential_category_case_insensitive():
    assert is_essential_category("moradia") is True
    assert is_essential_category("SAÚDE") is True
    assert is_essential_category("contas FIXAS") is True


def test_is_essential_category_unknown_name_is_not_essential():
    assert is_essential_category("Alimentação") is False
    assert is_essential_category("Pet") is False
    assert is_essential_category("Assinaturas") is False
```

- [ ] **Step 2: Rodar o teste para confirmar que falha**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_savings_analysis.py -v`
Expected: FAIL com `ModuleNotFoundError: No module named 'app.services.savings_analysis'`.

- [ ] **Step 3: Implementar a função**

Crie `backend/app/services/savings_analysis.py`:

```python
ESSENTIAL_CATEGORY_NAMES = {"moradia", "saúde", "contas fixas"}


def is_essential_category(name: str) -> bool:
    return name.strip().lower() in ESSENTIAL_CATEGORY_NAMES
```

- [ ] **Step 4: Rodar o teste de novo**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_savings_analysis.py -v`
Expected: PASS nos 3 testes.

- [ ] **Step 5: Commit**

```bash
cd backend
git add app/services/savings_analysis.py tests/test_savings_analysis.py
git commit -m "feat(reports): add essential-category classification helper"
```

---

### Task 2: Cálculo de referência por categoria (limite ou média histórica)

**Files:**
- Modify: `backend/app/services/savings_analysis.py`
- Test: `backend/tests/test_savings_analysis.py`

**Interfaces:**
- Produces: `async def get_category_reference(session: AsyncSession, user_id: int, category: Category, today: date) -> tuple[float | None, str | None]` em `backend/app/services/savings_analysis.py` — retorna `(valor_referencia, fonte)` onde `fonte` é `"limit"` ou `"average"`, ou `(None, None)` se não há referência válida. Consumido pela Task 3.
- Consumes: `is_essential_category` (Task 1, não usado diretamente aqui mas mesmo módulo). Modelos `Category` (`backend/app/models/category.py`) e `Transaction` (`backend/app/models/transaction.py`, campos `category_id`, `amount`, `date`, `user_id`, `type`).

- [ ] **Step 1: Escrever os testes primeiro**

Adicione ao final de `backend/tests/test_savings_analysis.py`. Este teste precisa de sessão de banco — importe a fixture `client` só para criar dados via API, mas a função em si é testada chamando-a diretamente com a sessão de teste. Como o projeto não expõe a sessão diretamente nos testes de router (eles só usam `client`), a abordagem mais simples e consistente com o resto do projeto é testar via um teste de integração leve, direto no arquivo de serviço, usando o mesmo padrão de fixture do `conftest.py`:

```python
import pytest
from datetime import date
from dateutil.relativedelta import relativedelta
from tests.helpers import register_and_login
from app.services.savings_analysis import get_category_reference
from app.models.category import Category
from app.models.transaction import Transaction, TransactionType
from sqlalchemy import select


async def _get_test_session(client):
    """Reaproveita o override de sessão já configurado em conftest.py."""
    from app.main import app
    from app.database import get_async_session
    override = app.dependency_overrides[get_async_session]
    async for session in override():
        return session


@pytest.mark.asyncio
async def test_reference_uses_monthly_limit_when_set(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Alimentação", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 1000.0
    }, headers=headers)
    cat_id = create.json()["id"]

    session = await _get_test_session(client)
    result = await session.execute(select(Category).where(Category.id == cat_id))
    category = result.scalar_one()

    ref, source = await get_category_reference(session, category.user_id, category, date.today())
    assert ref == 1000.0
    assert source == "limit"


@pytest.mark.asyncio
async def test_reference_uses_three_month_average_when_no_limit(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag"
    }, headers=headers)
    cat_id = create.json()["id"]

    today = date.today()
    month_1 = (today.replace(day=1) - relativedelta(months=1)).isoformat()
    month_2 = (today.replace(day=1) - relativedelta(months=2)).isoformat()
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Cinema", "amount": 100.0,
        "date": month_1, "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Show", "amount": 200.0,
        "date": month_2, "type": "expense", "is_recurring": False
    }, headers=headers)

    session = await _get_test_session(client)
    result = await session.execute(select(Category).where(Category.id == cat_id))
    category = result.scalar_one()

    ref, source = await get_category_reference(session, category.user_id, category, today)
    assert ref == 150.0
    assert source == "average"


@pytest.mark.asyncio
async def test_reference_excludes_current_month_from_average(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#c17a54", "icon": "tag"
    }, headers=headers)
    cat_id = create.json()["id"]

    today = date.today()
    month_1 = (today.replace(day=1) - relativedelta(months=1)).isoformat()
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Roupa mês passado", "amount": 100.0,
        "date": month_1, "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Roupa este mês", "amount": 9999.0,
        "date": today.isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    session = await _get_test_session(client)
    result = await session.execute(select(Category).where(Category.id == cat_id))
    category = result.scalar_one()

    ref, source = await get_category_reference(session, category.user_id, category, today)
    assert ref == 100.0
    assert source == "average"


@pytest.mark.asyncio
async def test_reference_none_without_limit_or_history(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Categoria Nova", "type": "expense", "color": "#c17a54", "icon": "tag"
    }, headers=headers)
    cat_id = create.json()["id"]

    session = await _get_test_session(client)
    result = await session.execute(select(Category).where(Category.id == cat_id))
    category = result.scalar_one()

    ref, source = await get_category_reference(session, category.user_id, category, date.today())
    assert ref is None
    assert source is None
```

- [ ] **Step 2: Rodar os testes para confirmar que falham**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_savings_analysis.py -v`
Expected: FAIL nos 4 testes novos (`get_category_reference` não existe ainda; `ImportError`).

- [ ] **Step 3: Implementar a função**

Adicione ao final de `backend/app/services/savings_analysis.py`:

```python
from datetime import date
from dateutil.relativedelta import relativedelta
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.category import Category
from app.models.transaction import Transaction


async def get_category_reference(
    session: AsyncSession, user_id: int, category: Category, today: date
) -> tuple[float | None, str | None]:
    if category.monthly_limit is not None and category.monthly_limit > 0:
        return category.monthly_limit, "limit"

    current_month_start = today.replace(day=1)
    three_months_back_start = current_month_start - relativedelta(months=3)

    result = await session.execute(
        select(
            func.strftime("%Y-%m", Transaction.date).label("month"),
            func.sum(Transaction.amount).label("total"),
        )
        .where(
            and_(
                Transaction.user_id == user_id,
                Transaction.category_id == category.id,
                Transaction.date >= three_months_back_start,
                Transaction.date < current_month_start,
            )
        )
        .group_by("month")
    )
    monthly_totals = [row.total for row in result.all()]

    if not monthly_totals:
        return None, None

    average = sum(monthly_totals) / len(monthly_totals)
    return round(average, 2), "average"
```

Nota: `func.strftime("%Y-%m", ...)` é uma função específica do SQLite (o banco usado neste projeto) para extrair ano-mês de uma coluna `Date`, usada aqui para agrupar por mês calendário e calcular a média só sobre meses que de fato tiveram gasto (em vez de somar tudo e dividir por 3 fixo, o que diluiria a média com zeros de meses sem dado).

- [ ] **Step 4: Rodar os testes de novo**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_savings_analysis.py -v`
Expected: PASS nos 7 testes (3 da Task 1 + 4 desta task).

- [ ] **Step 5: Commit**

```bash
cd backend
git add app/services/savings_analysis.py tests/test_savings_analysis.py
git commit -m "feat(reports): compute per-category reference from limit or 3-month average"
```

---

### Task 3: Montagem do item de análise + endpoint `GET /reports/savings-analysis`

**Files:**
- Modify: `backend/app/services/savings_analysis.py`
- Create: `backend/app/schemas/report.py`
- Create: `backend/app/routers/reports.py`
- Modify: `backend/app/main.py`
- Test: `backend/tests/test_savings_analysis.py` (testes de serviço)
- Test: `backend/tests/test_reports.py` (testes de endpoint)

**Interfaces:**
- Produces:
  - `SavingsAnalysisItem` (Pydantic, em `backend/app/schemas/report.py`): `category_id: int`, `category_name: str`, `category_color: str`, `is_essential: bool`, `current_amount: float`, `reference_amount: float`, `reference_source: str`, `percent: float`, `suggested_cut: float | None`.
  - `async def build_savings_analysis(session: AsyncSession, user_id: int) -> list[SavingsAnalysisItem]` em `backend/app/services/savings_analysis.py` — consumido pelo router.
  - `GET /reports/savings-analysis` → `list[SavingsAnalysisItem]`. Consumido pela Task 4 (frontend).
- Consumes: `is_essential_category`, `get_category_reference` (Tasks 1-2). Modelos `Category`, `Transaction`.

- [ ] **Step 1: Escrever os testes de endpoint primeiro**

Crie `backend/tests/test_reports.py`:

```python
import pytest
from datetime import date
from tests.helpers import register_and_login


@pytest.mark.asyncio
async def test_savings_analysis_excludes_categories_below_eighty_percent(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Educação", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 1000.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Curso", "amount": 500.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    names = [item["category_name"] for item in response.json()]
    assert "Educação" not in names


@pytest.mark.asyncio
async def test_savings_analysis_essential_category_has_no_suggested_cut(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Saúde", "type": "expense", "color": "#b8563a", "icon": "tag", "monthly_limit": 500.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Consulta", "amount": 800.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    item = next(i for i in response.json() if i["category_name"] == "Saúde")
    assert item["is_essential"] is True
    assert item["suggested_cut"] is None


@pytest.mark.asyncio
async def test_savings_analysis_cuttable_category_over_limit_has_suggested_cut(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet", "monthly_limit": 500.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Roupas", "amount": 800.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    item = next(i for i in response.json() if i["category_name"] == "Compras")
    assert item["is_essential"] is False
    assert item["suggested_cut"] == 300.0


@pytest.mark.asyncio
async def test_savings_analysis_cuttable_between_eighty_and_hundred_has_no_cut(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 1000.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Cinema", "amount": 850.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    item = next(i for i in response.json() if i["category_name"] == "Lazer")
    assert item["suggested_cut"] is None
    assert item["percent"] == pytest.approx(85.0, rel=0.01)


@pytest.mark.asyncio
async def test_savings_analysis_ordered_by_largest_overage_first(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_a = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet", "monthly_limit": 500.0
    }, headers=headers)
    cat_b = await client.post("/categories", json={
        "name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 500.0
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_a.json()["id"], "description": "Roupas", "amount": 600.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_b.json()["id"], "description": "Show", "amount": 1000.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    data = response.json()
    assert data[0]["category_name"] == "Lazer"
    assert data[1]["category_name"] == "Compras"


@pytest.mark.asyncio
async def test_savings_analysis_only_own_categories(client):
    token_a = await register_and_login(client)
    headers_a = {"Authorization": f"Bearer {token_a}"}
    cat = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet", "monthly_limit": 100.0
    }, headers=headers_a)
    await client.post("/transactions", json={
        "category_id": cat.json()["id"], "description": "Item", "amount": 200.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers_a)

    token_b = await register_and_login(client, email="userb@email.com", name="User B", password="senhaB999")
    headers_b = {"Authorization": f"Bearer {token_b}"}

    response = await client.get("/reports/savings-analysis", headers=headers_b)
    assert response.status_code == 200
    assert response.json() == []
```

- [ ] **Step 2: Rodar os testes para confirmar que falham**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_reports.py -v`
Expected: FAIL (rota não existe, 404).

- [ ] **Step 3: Criar o schema**

Crie `backend/app/schemas/report.py`:

```python
from pydantic import BaseModel


class SavingsAnalysisItem(BaseModel):
    category_id: int
    category_name: str
    category_color: str
    is_essential: bool
    current_amount: float
    reference_amount: float
    reference_source: str
    percent: float
    suggested_cut: float | None
```

- [ ] **Step 4: Implementar `build_savings_analysis` no service**

Adicione ao final de `backend/app/services/savings_analysis.py`:

```python
from app.schemas.report import SavingsAnalysisItem


async def build_savings_analysis(session: AsyncSession, user_id: int) -> list[SavingsAnalysisItem]:
    today = date.today()
    month_start = today.replace(day=1)

    cats_result = await session.execute(
        select(Category).where(Category.user_id == user_id, Category.type == "expense")
    )
    categories = cats_result.scalars().all()

    usage_result = await session.execute(
        select(Transaction.category_id, func.sum(Transaction.amount))
        .where(
            and_(
                Transaction.user_id == user_id,
                Transaction.date >= month_start,
                Transaction.date <= today,
            )
        )
        .group_by(Transaction.category_id)
    )
    usage_by_category = {cat_id: total for cat_id, total in usage_result.all() if cat_id is not None}

    items = []
    for category in categories:
        reference, source = await get_category_reference(session, user_id, category, today)
        if reference is None or reference <= 0:
            continue

        current_amount = round(usage_by_category.get(category.id, 0.0) or 0.0, 2)
        percent = round((current_amount / reference) * 100, 2)
        if percent < 80:
            continue

        essential = is_essential_category(category.name)
        suggested_cut = None
        if not essential and current_amount > reference:
            suggested_cut = round(current_amount - reference, 2)

        items.append(SavingsAnalysisItem(
            category_id=category.id,
            category_name=category.name,
            category_color=category.color,
            is_essential=essential,
            current_amount=current_amount,
            reference_amount=reference,
            reference_source=source,
            percent=percent,
            suggested_cut=suggested_cut,
        ))

    items.sort(key=lambda i: i.current_amount - i.reference_amount, reverse=True)
    return items
```

- [ ] **Step 5: Criar o router**

Crie `backend/app/routers/reports.py`:

```python
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.schemas.report import SavingsAnalysisItem
from app.services.savings_analysis import build_savings_analysis

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/savings-analysis", response_model=list[SavingsAnalysisItem])
async def get_savings_analysis(
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    return await build_savings_analysis(session, current_user.id)
```

- [ ] **Step 6: Registrar o router em `main.py`**

Em `backend/app/main.py`, adicione `reports` ao import de routers (linha 7) e registre o router (após a linha `app.include_router(dashboard_router.router)`):

```python
from app.routers import auth as auth_router, categories as categories_router, transactions as transactions_router, income as income_router, plans as plans_router, dashboard as dashboard_router, reports as reports_router
```

```python
app.include_router(reports_router.router)
```

- [ ] **Step 7: Rodar os testes de novo**

Run: `cd backend && source .venv/bin/activate && pytest tests/test_reports.py -v`
Expected: PASS nos 6 testes.

- [ ] **Step 8: Rodar a suite inteira**

Run: `cd backend && source .venv/bin/activate && pytest -v`
Expected: todos os testes passam (nota: `test_income.py::test_income_summary_average` é uma falha pré-existente conhecida e não relacionada, sensível à data corrente do sistema — não bloqueia esta task).

- [ ] **Step 9: Commit**

```bash
cd backend
git add app/schemas/report.py app/routers/reports.py app/services/savings_analysis.py app/main.py tests/test_reports.py
git commit -m "feat(reports): add savings analysis endpoint"
```

---

### Task 4: Conteúdo de `ReportsView.vue`

**Files:**
- Create: `frontend/src/stores/reports.js`
- Modify: `frontend/src/views/ReportsView.vue`

**Interfaces:**
- Produces: Pinia store `useReportsStore` com estado `{ items: Ref<Item[]>, loading: Ref<boolean> }` e ação `fetchSavingsAnalysis()`. Nenhuma interface nova consumida por outras tasks (última task deste sub-projeto).
- Consumes: `api` de `frontend/src/services/api.js` (já existe). Formato de item retornado por `GET /reports/savings-analysis` (Task 3): `{ category_id, category_name, category_color, is_essential, current_amount, reference_amount, reference_source, percent, suggested_cut }`.

- [ ] **Step 1: Criar o store**

Crie `frontend/src/stores/reports.js`:

```js
import { ref } from 'vue'
import { defineStore } from 'pinia'
import api from '@/services/api'

export const useReportsStore = defineStore('reports', () => {
  const items = ref([])
  const loading = ref(false)

  async function fetchSavingsAnalysis() {
    loading.value = true
    try {
      const { data } = await api.get('/reports/savings-analysis')
      items.value = data
    } finally {
      loading.value = false
    }
  }

  return { items, loading, fetchSavingsAnalysis }
})
```

- [ ] **Step 2: Reescrever `ReportsView.vue`**

Substitua o arquivo inteiro de `frontend/src/views/ReportsView.vue`:

```vue
<script setup>
import { onMounted } from 'vue'
import AppLayout from '@/components/layout/AppLayout.vue'
import { useReportsStore } from '@/stores/reports'

const store = useReportsStore()

function formatCurrency(val) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val || 0)
}

function usageColorClass(percent) {
  if (percent > 100) return 'usage-over'
  if (percent >= 80) return 'usage-warning'
  return 'usage-ok'
}

onMounted(() => store.fetchSavingsAnalysis())
</script>

<template>
  <AppLayout>
    <div class="page-header">
      <h1 class="page-title">Relatórios</h1>
      <p class="page-subtitle">Análise de onde você pode economizar este mês</p>
    </div>

    <div class="card">
      <div v-if="store.loading" style="text-align:center;padding:2rem;color:var(--text-muted)">Carregando...</div>
      <div v-else-if="!store.items.length" style="text-align:center;padding:2rem;color:var(--text-muted)">
        Nenhuma categoria fora do esperado este mês.
      </div>
      <div v-else class="analysis-list">
        <div v-for="item in store.items" :key="item.category_id" class="analysis-item">
          <div class="analysis-header">
            <span class="cat-color-dot" :style="{ background: item.category_color }" />
            <span class="font-semibold">{{ item.category_name }}</span>
            <span v-if="item.is_essential" class="badge badge-info">Essencial</span>
          </div>
          <div class="progress-bar" style="margin:0.5rem 0">
            <div
              :class="['progress-fill', usageColorClass(item.percent)]"
              :style="{ width: Math.min(item.percent, 100) + '%' }"
            />
          </div>
          <div class="analysis-footer text-muted text-sm">
            <span>{{ formatCurrency(item.current_amount) }} / {{ formatCurrency(item.reference_amount) }}
              ({{ item.reference_source === 'limit' ? 'limite' : 'média histórica' }})</span>
            <span :class="usageColorClass(item.percent)">{{ item.percent }}%</span>
          </div>
          <div v-if="item.suggested_cut" class="suggested-cut">
            Sugestão: economize {{ formatCurrency(item.suggested_cut) }} nesta categoria
          </div>
          <div v-else-if="item.is_essential" class="essential-notice text-muted text-sm">
            Categoria essencial — acima do esperado, mas sem sugestão de corte.
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
.analysis-list { display: flex; flex-direction: column; gap: 1.25rem; }
.analysis-item { padding-bottom: 1.25rem; border-bottom: 1px solid var(--border-subtle); }
.analysis-item:last-child { border-bottom: none; padding-bottom: 0; }
.analysis-header { display: flex; align-items: center; gap: 0.5rem; }
.analysis-footer { display: flex; justify-content: space-between; }
.cat-color-dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; }
.suggested-cut {
  margin-top: 0.5rem; padding: 0.5rem 0.75rem; border-radius: var(--radius-sm);
  background: rgba(122,155,126,0.12); color: var(--accent-success); font-size: var(--font-size-sm); font-weight: 600;
}
.essential-notice { margin-top: 0.5rem; }
.usage-ok { color: var(--accent-success); }
.usage-warning { color: var(--accent-primary); }
.usage-over { color: var(--accent-danger); }
.progress-fill.usage-ok { background: var(--accent-success); }
.progress-fill.usage-warning { background: var(--accent-primary); }
.progress-fill.usage-over { background: var(--accent-danger); }
</style>
```

Nota: `.progress-bar`/`.progress-fill` são classes globais já existentes em `frontend/src/assets/main.css`; as regras `.progress-fill.usage-*` seguem exatamente o mesmo padrão de sobrescrita de cor já usado em `frontend/src/views/CategoriesView.vue` (sub-projeto 1) — mesma técnica, arquivo diferente, sem duplicar a definição base.

- [ ] **Step 3: Verificar visualmente no browser**

Com `docker compose up -d --build` (ou dev server local): criar uma categoria com limite baixo, lançar uma transação que ultrapasse o limite, navegar até "Relatórios" e confirmar que a categoria aparece com o valor de corte sugerido em destaque verde. Testar com "Saúde" (nome essencial) ultrapassando o limite — confirmar que aparece só o aviso, sem valor de corte. Confirmar que categoria dentro do esperado (abaixo de 80%) não aparece na lista.

- [ ] **Step 4: Commit**

```bash
cd frontend
git add src/stores/reports.js src/views/ReportsView.vue
git commit -m "feat(reports): add savings analysis view"
```

---

### Task 5: Verificação final end-to-end

**Files:**
- Nenhum arquivo novo — apenas verificação manual via Chrome automation.

**Interfaces:**
- Consumes: todas as tasks anteriores.
- Produces: nada (task de verificação).

- [ ] **Step 1: Rodar a suite de testes do backend inteira**

Run: `cd backend && source .venv/bin/activate && pytest -v`
Expected: todos os testes passam, incluindo os 13 novos deste plano (3 da Task 1 + 4 da Task 2 + 6 da Task 3). A falha pré-existente em `test_income.py::test_income_summary_average` é débito conhecido, não relacionado.

- [ ] **Step 2: Rebuild e subir o ambiente completo**

```bash
docker compose up -d --build
```

- [ ] **Step 3: Percorrer o fluxo completo no browser**

1. Login em uma conta com categorias já semeadas (ou semear via tela de Categorias).
2. Definir um limite baixo em "Compras" (ex: R$300) e lançar uma transação de R$450 nessa categoria.
3. Definir um limite em "Saúde" (ex: R$500) e lançar uma transação de R$600.
4. Ir em "Relatórios" — confirmar: "Compras" aparece com sugestão de corte de R$150,00 em destaque verde; "Saúde" aparece com badge "Essencial" e SEM sugestão de corte, só o aviso textual.
5. Testar uma categoria sem limite: lançar transações em 3 meses fechados anteriores para "Lazer" (ex: R$100 mês passado, R$200 dois meses atrás), depois lançar R$400 no mês corrente — confirmar que a referência mostrada é "média histórica" e o percentual reflete a comparação com a média (150), não um limite.
6. Confirmar que uma categoria dentro do esperado (gasto bem abaixo do limite/média) não aparece na lista.

- [ ] **Step 4: Checar console do browser por erros**

Usando `read_console_messages` (Chrome automation) com `onlyErrors: true` na tela de Relatórios — nenhum erro de JS deve aparecer.

- [ ] **Step 5: Rodar build de produção uma última vez**

```bash
cd frontend && npm run build
```

Expected: build succeeds sem warnings novos.

- [ ] **Step 6: Commit final (se houver ajustes desta verificação)**

Se a verificação não encontrar nada para corrigir, não é necessário commit nesta task. Se algum ajuste pontual for necessário, commitar separadamente com mensagem descritiva do que foi ajustado.

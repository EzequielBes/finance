# AnalisadorFinanceiro — Plano 2: Planos, Sub-planos, Simulação e Timeline

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar o sistema de planos financeiros com sub-planos, simulador de prazo interativo, histórico de aportes, endpoint de dashboard com resumo mensal e o construtor de dados da timeline visual.

**Architecture:** Novos models `Plan` e `PlanContribution` com auto-referência para hierarquia. Service `plan_simulator.py` encapsula toda a lógica de cálculo. Service `timeline_builder.py` agrega transações futuras + marcos de planos para o frontend. Dashboard router expõe resumo mensal.

**Tech Stack:** Mesmo stack do Plano 1 (FastAPI, SQLAlchemy async, SQLite, Pydantic v2, pytest, httpx)

## Global Constraints

- Herda todos os constraints do Plano 1
- Este plano depende do Plano 1 concluído (backend rodando com auth + transações + renda)
- `plan_simulator.py` e `timeline_builder.py` são serviços puros sem dependência de FastAPI — testáveis em isolamento
- Sub-planos: máximo de 1 nível de profundidade no MVP (plano → sub-plano, sem sub-sub-planos)

---

### Task 6: Models de Plano e Aportes

**Files:**
- Create: `backend/app/models/plan.py`
- Create: `backend/app/models/plan_contribution.py`
- Modify: `backend/app/models/__init__.py`

**Interfaces:**
- Produces: `Plan` model com campos: `id`, `user_id`, `parent_plan_id` (nullable FK para plans.id), `name`, `description`, `target_amount`, `current_savings`, `monthly_contribution`, `deadline` (nullable Date), `status` (Enum: active/paused/cancelled/completed), `priority` (int), `notes`, `created_at`, `updated_at`
- Produces: `PlanContribution` model com campos: `id`, `plan_id`, `amount`, `date`, `notes`
- Produces: Enum `PlanStatus` em `app/models/plan.py`

- [ ] **Step 1: Criar app/models/plan.py**

```python
import enum
from datetime import date, datetime, timezone
from sqlalchemy import Integer, String, Float, Boolean, Date, DateTime, ForeignKey, Text, Enum as SAEnum, event
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class PlanStatus(str, enum.Enum):
    active = "active"
    paused = "paused"
    cancelled = "cancelled"
    completed = "completed"


class Plan(Base):
    __tablename__ = "plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    parent_plan_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("plans.id"), nullable=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    target_amount: Mapped[float] = mapped_column(Float, nullable=False)
    current_savings: Mapped[float] = mapped_column(Float, default=0.0)
    monthly_contribution: Mapped[float] = mapped_column(Float, nullable=False)
    deadline: Mapped[date | None] = mapped_column(Date, nullable=True)
    status: Mapped[PlanStatus] = mapped_column(SAEnum(PlanStatus), default=PlanStatus.active)
    priority: Mapped[int] = mapped_column(Integer, default=1)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )
```

- [ ] **Step 2: Criar app/models/plan_contribution.py**

```python
from datetime import date, datetime, timezone
from sqlalchemy import Integer, Float, Date, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class PlanContribution(Base):
    __tablename__ = "plan_contributions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    plan_id: Mapped[int] = mapped_column(Integer, ForeignKey("plans.id"), nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
```

- [ ] **Step 3: Registrar em app/models/__init__.py**

```python
from app.models import plan  # noqa: F401
from app.models import plan_contribution  # noqa: F401
```

- [ ] **Step 4: Verificar que as tabelas são criadas**

```bash
cd backend && source .venv/bin/activate
python -c "
import asyncio
from app.database import create_all_tables
asyncio.run(create_all_tables())
print('Tabelas criadas OK')
"
```

Esperado: `Tabelas criadas OK` sem erros.

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: models Plan e PlanContribution com hierarquia e status"
```

---

### Task 7: Serviço de Simulação de Planos

**Files:**
- Create: `backend/app/services/__init__.py`
- Create: `backend/app/services/plan_simulator.py`
- Create: `backend/tests/test_plan_simulator.py`

**Interfaces:**
- Consumes: nenhuma dependência de FastAPI ou SQLAlchemy — funções puras
- Produces: `simulate_plan(target_amount, current_savings, monthly_contribution, reference_date) -> PlanSimulation`
- Produces: dataclass `PlanSimulation` com campos: `months_to_goal`, `estimated_date`, `progress_percent`, `remaining_amount`
- Produces: `simulate_with_deadline(target_amount, current_savings, deadline, reference_date) -> float` — retorna `monthly_contribution` necessária para atingir o prazo

- [ ] **Step 1: Escrever testes do simulador**

Criar `backend/tests/test_plan_simulator.py`:

```python
from datetime import date
from app.services.plan_simulator import simulate_plan, simulate_with_deadline, PlanSimulation


def test_simulate_plan_basic():
    result = simulate_plan(
        target_amount=10000.0,
        current_savings=1000.0,
        monthly_contribution=500.0,
        reference_date=date(2026, 7, 1),
    )
    assert isinstance(result, PlanSimulation)
    # Faltam 9000 / 500 = 18 meses
    assert result.months_to_goal == 18
    assert result.estimated_date == date(2028, 1, 1)
    assert result.remaining_amount == pytest.approx(9000.0)
    assert result.progress_percent == pytest.approx(10.0)


def test_simulate_plan_already_reached():
    result = simulate_plan(
        target_amount=5000.0,
        current_savings=5000.0,
        monthly_contribution=100.0,
        reference_date=date(2026, 7, 1),
    )
    assert result.months_to_goal == 0
    assert result.progress_percent == 100.0


def test_simulate_plan_zero_contribution():
    result = simulate_plan(
        target_amount=10000.0,
        current_savings=1000.0,
        monthly_contribution=0.0,
        reference_date=date(2026, 7, 1),
    )
    assert result.months_to_goal is None
    assert result.estimated_date is None


def test_simulate_with_deadline():
    # Atingir 12000 em 12 meses partindo de 0
    needed = simulate_with_deadline(
        target_amount=12000.0,
        current_savings=0.0,
        deadline=date(2027, 7, 1),
        reference_date=date(2026, 7, 1),
    )
    assert needed == pytest.approx(1000.0)


import pytest
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
pytest tests/test_plan_simulator.py -v
```

Esperado: `ERROR` (módulo não existe).

- [ ] **Step 3: Criar app/services/plan_simulator.py**

```python
from dataclasses import dataclass
from datetime import date
from typing import Optional
from math import ceil
from dateutil.relativedelta import relativedelta


@dataclass
class PlanSimulation:
    months_to_goal: Optional[int]
    estimated_date: Optional[date]
    progress_percent: float
    remaining_amount: float


def simulate_plan(
    target_amount: float,
    current_savings: float,
    monthly_contribution: float,
    reference_date: date,
) -> PlanSimulation:
    """Calcula prazo e progresso de um plano financeiro."""
    remaining = max(0.0, target_amount - current_savings)
    progress = min(100.0, (current_savings / target_amount * 100) if target_amount > 0 else 100.0)

    if remaining <= 0:
        return PlanSimulation(
            months_to_goal=0,
            estimated_date=reference_date,
            progress_percent=100.0,
            remaining_amount=0.0,
        )

    if monthly_contribution <= 0:
        return PlanSimulation(
            months_to_goal=None,
            estimated_date=None,
            progress_percent=round(progress, 2),
            remaining_amount=round(remaining, 2),
        )

    months = ceil(remaining / monthly_contribution)
    estimated = reference_date + relativedelta(months=months)
    return PlanSimulation(
        months_to_goal=months,
        estimated_date=estimated,
        progress_percent=round(progress, 2),
        remaining_amount=round(remaining, 2),
    )


def simulate_with_deadline(
    target_amount: float,
    current_savings: float,
    deadline: date,
    reference_date: date,
) -> float:
    """Calcula contribuição mensal necessária para atingir o prazo."""
    remaining = max(0.0, target_amount - current_savings)
    if remaining <= 0:
        return 0.0
    delta = relativedelta(deadline, reference_date)
    months = delta.years * 12 + delta.months
    if months <= 0:
        return remaining  # precisa de tudo agora
    return round(remaining / months, 2)
```

- [ ] **Step 4: Rodar testes**

```bash
pytest tests/test_plan_simulator.py -v
```

Esperado: todos os 4 testes `PASSED`.

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: serviço de simulação de planos financeiros"
```

---

### Task 8: Router de Planos (CRUD + Sub-planos + Simulador)

**Files:**
- Create: `backend/app/schemas/plan.py`
- Create: `backend/app/routers/plans.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/test_plans.py`

**Interfaces:**
- Consumes: `Plan`, `PlanContribution` models, `simulate_plan`, `simulate_with_deadline`, `get_current_user`, `get_async_session`
- Produces: endpoints:
  - `POST /plans` — criar plano
  - `GET /plans` — listar planos do usuário (apenas root plans por padrão, com sub-planos embutidos)
  - `GET /plans/{id}` — detalhe + simulação
  - `PUT /plans/{id}` — atualizar
  - `DELETE /plans/{id}` — deletar (cascata nos sub-planos)
  - `POST /plans/{id}/contributions` — registrar aporte
  - `GET /plans/{id}/contributions` — histórico de aportes
  - `GET /plans/{id}/simulate?monthly_contribution=X` — simulação interativa

- [ ] **Step 1: Escrever testes de planos**

Criar `backend/tests/test_plans.py`:

```python
import pytest
from tests.helpers import register_and_login


@pytest.mark.asyncio
async def test_create_plan(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.post("/plans", json={
        "name": "Viagem Japão",
        "target_amount": 15000.0,
        "current_savings": 1000.0,
        "monthly_contribution": 800.0,
        "priority": 1
    }, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Viagem Japão"
    assert data["status"] == "active"
    assert data["parent_plan_id"] is None


@pytest.mark.asyncio
async def test_create_subplan(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    parent = await client.post("/plans", json={
        "name": "Viagem Japão", "target_amount": 15000.0,
        "current_savings": 0.0, "monthly_contribution": 800.0, "priority": 1
    }, headers=headers)
    parent_id = parent.json()["id"]
    sub = await client.post("/plans", json={
        "name": "Passagem Aérea",
        "target_amount": 5000.0,
        "current_savings": 0.0,
        "monthly_contribution": 300.0,
        "priority": 1,
        "parent_plan_id": parent_id
    }, headers=headers)
    assert sub.status_code == 201
    assert sub.json()["parent_plan_id"] == parent_id


@pytest.mark.asyncio
async def test_plan_detail_includes_simulation(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "Carro", "target_amount": 20000.0,
        "current_savings": 2000.0, "monthly_contribution": 1000.0, "priority": 2
    }, headers=headers)
    plan_id = create.json()["id"]
    response = await client.get(f"/plans/{plan_id}", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "simulation" in data
    assert data["simulation"]["months_to_goal"] == 18
    assert data["simulation"]["progress_percent"] == pytest.approx(10.0)


@pytest.mark.asyncio
async def test_plan_simulate_endpoint(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "Reserva", "target_amount": 10000.0,
        "current_savings": 0.0, "monthly_contribution": 500.0, "priority": 1
    }, headers=headers)
    plan_id = create.json()["id"]
    response = await client.get(f"/plans/{plan_id}/simulate?monthly_contribution=1000", headers=headers)
    assert response.status_code == 200
    assert response.json()["months_to_goal"] == 10


@pytest.mark.asyncio
async def test_plan_contribution(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "Mochila", "target_amount": 500.0,
        "current_savings": 0.0, "monthly_contribution": 100.0, "priority": 1
    }, headers=headers)
    plan_id = create.json()["id"]
    contrib = await client.post(f"/plans/{plan_id}/contributions", json={
        "amount": 150.0, "date": "2026-07-31", "notes": "Economizei esse mês"
    }, headers=headers)
    assert contrib.status_code == 201
    # current_savings deve ter aumentado
    detail = await client.get(f"/plans/{plan_id}", headers=headers)
    assert detail.json()["current_savings"] == 150.0


@pytest.mark.asyncio
async def test_update_plan_status(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "X", "target_amount": 100.0,
        "current_savings": 0.0, "monthly_contribution": 10.0, "priority": 1
    }, headers=headers)
    plan_id = create.json()["id"]
    response = await client.put(f"/plans/{plan_id}", json={"status": "paused"}, headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "paused"


import pytest
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
pytest tests/test_plans.py -v
```

Esperado: `ERROR` ou `FAILED`.

- [ ] **Step 3: Criar app/schemas/plan.py**

```python
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel
from app.models.plan import PlanStatus
from app.services.plan_simulator import PlanSimulation


class PlanCreate(BaseModel):
    name: str
    description: Optional[str] = None
    target_amount: float
    current_savings: float = 0.0
    monthly_contribution: float
    deadline: Optional[date] = None
    priority: int = 1
    notes: Optional[str] = None
    parent_plan_id: Optional[int] = None


class PlanUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    target_amount: Optional[float] = None
    monthly_contribution: Optional[float] = None
    deadline: Optional[date] = None
    status: Optional[PlanStatus] = None
    priority: Optional[int] = None
    notes: Optional[str] = None


class PlanResponse(BaseModel):
    id: int
    user_id: int
    parent_plan_id: Optional[int]
    name: str
    description: Optional[str]
    target_amount: float
    current_savings: float
    monthly_contribution: float
    deadline: Optional[date]
    status: PlanStatus
    priority: int
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class PlanDetailResponse(PlanResponse):
    simulation: Optional[PlanSimulation] = None
    sub_plans: list[PlanResponse] = []


class PlanContributionCreate(BaseModel):
    amount: float
    date: date
    notes: Optional[str] = None


class PlanContributionResponse(BaseModel):
    id: int
    plan_id: int
    amount: float
    date: date
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}
```

- [ ] **Step 4: Criar app/routers/plans.py**

```python
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.plan import Plan, PlanStatus
from app.models.plan_contribution import PlanContribution
from app.schemas.plan import (
    PlanCreate, PlanUpdate, PlanResponse, PlanDetailResponse,
    PlanContributionCreate, PlanContributionResponse
)
from app.services.plan_simulator import simulate_plan

router = APIRouter(prefix="/plans", tags=["plans"])


def _build_simulation(plan: Plan):
    return simulate_plan(
        target_amount=plan.target_amount,
        current_savings=plan.current_savings,
        monthly_contribution=plan.monthly_contribution,
        reference_date=datetime.now(timezone.utc).date(),
    )


@router.post("", response_model=PlanResponse, status_code=201)
async def create_plan(
    payload: PlanCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    if payload.parent_plan_id:
        parent = await session.get(Plan, payload.parent_plan_id)
        if not parent or parent.user_id != current_user.id:
            raise HTTPException(status_code=404, detail="Plano pai não encontrado")
        if parent.parent_plan_id is not None:
            raise HTTPException(status_code=400, detail="Sub-planos não podem ter sub-planos (máx 1 nível)")
    plan = Plan(**payload.model_dump(), user_id=current_user.id)
    session.add(plan)
    await session.commit()
    await session.refresh(plan)
    return plan


@router.get("", response_model=list[PlanDetailResponse])
async def list_plans(
    include_sub: bool = False,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    q = select(Plan).where(Plan.user_id == current_user.id)
    if not include_sub:
        q = q.where(Plan.parent_plan_id == None)
    result = await session.execute(q.order_by(Plan.priority, Plan.created_at))
    plans = result.scalars().all()
    responses = []
    for plan in plans:
        sub_result = await session.execute(
            select(Plan).where(Plan.parent_plan_id == plan.id)
        )
        sub_plans = sub_result.scalars().all()
        responses.append(PlanDetailResponse(
            **PlanResponse.model_validate(plan).model_dump(),
            simulation=_build_simulation(plan),
            sub_plans=[PlanResponse.model_validate(s) for s in sub_plans],
        ))
    return responses


@router.get("/{plan_id}", response_model=PlanDetailResponse)
async def get_plan(
    plan_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    sub_result = await session.execute(select(Plan).where(Plan.parent_plan_id == plan.id))
    sub_plans = sub_result.scalars().all()
    return PlanDetailResponse(
        **PlanResponse.model_validate(plan).model_dump(),
        simulation=_build_simulation(plan),
        sub_plans=[PlanResponse.model_validate(s) for s in sub_plans],
    )


@router.get("/{plan_id}/simulate")
async def simulate_plan_endpoint(
    plan_id: int,
    monthly_contribution: float = Query(..., gt=0),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    return simulate_plan(
        target_amount=plan.target_amount,
        current_savings=plan.current_savings,
        monthly_contribution=monthly_contribution,
        reference_date=datetime.now(timezone.utc).date(),
    )


@router.put("/{plan_id}", response_model=PlanResponse)
async def update_plan(
    plan_id: int,
    payload: PlanUpdate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    for key, value in payload.model_dump(exclude_none=True).items():
        setattr(plan, key, value)
    plan.updated_at = datetime.now(timezone.utc)
    await session.commit()
    await session.refresh(plan)
    return plan


@router.delete("/{plan_id}", status_code=204)
async def delete_plan(
    plan_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    # Deletar sub-planos primeiro
    sub_result = await session.execute(select(Plan).where(Plan.parent_plan_id == plan.id))
    for sub in sub_result.scalars().all():
        await session.delete(sub)
    await session.delete(plan)
    await session.commit()


@router.post("/{plan_id}/contributions", response_model=PlanContributionResponse, status_code=201)
async def add_contribution(
    plan_id: int,
    payload: PlanContributionCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    contribution = PlanContribution(plan_id=plan_id, **payload.model_dump())
    session.add(contribution)
    plan.current_savings += payload.amount
    plan.updated_at = datetime.now(timezone.utc)
    if plan.current_savings >= plan.target_amount:
        plan.status = PlanStatus.completed
    await session.commit()
    await session.refresh(contribution)
    return contribution


@router.get("/{plan_id}/contributions", response_model=list[PlanContributionResponse])
async def list_contributions(
    plan_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    plan_result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    if not plan_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    result = await session.execute(
        select(PlanContribution).where(PlanContribution.plan_id == plan_id)
        .order_by(PlanContribution.date.desc())
    )
    return result.scalars().all()
```

- [ ] **Step 5: Registrar em main.py**

Em `app/main.py`:
```python
from app.routers import plans as plans_router
app.include_router(plans_router.router)
```

- [ ] **Step 6: Rodar testes**

```bash
pytest tests/test_plans.py -v
```

Esperado: todos os 6 testes `PASSED`.

- [ ] **Step 7: Commit**

```bash
git add .
git commit -m "feat: CRUD de planos com sub-planos, simulador e aportes"
```

---

### Task 9: Dashboard e Timeline Builder

**Files:**
- Create: `backend/app/services/timeline_builder.py`
- Create: `backend/app/routers/dashboard.py`
- Modify: `backend/app/main.py`
- Create: `backend/tests/test_dashboard.py`

**Interfaces:**
- Consumes: `Transaction`, `Plan`, `IncomeEntry` models, `simulate_plan`, `get_current_user`, `get_async_session`
- Produces: `GET /dashboard/summary` → `DashboardSummary` (receita, gasto, saldo, % economizado, gastos por categoria)
- Produces: `GET /dashboard/timeline?months_ahead=6` → `list[TimelineEvent]`
- Produces: `TimelineEvent` com campos: `date`, `type` (transaction/plan_milestone), `label`, `amount`, `color`, `icon`, `category`

- [ ] **Step 1: Escrever testes do dashboard**

Criar `backend/tests/test_dashboard.py`:

```python
import pytest
from tests.helpers import register_and_login


@pytest.mark.asyncio
async def test_dashboard_summary_empty(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/dashboard/summary", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total_income"] == 0.0
    assert data["total_expense"] == 0.0
    assert data["balance"] == 0.0
    assert data["savings_percent"] == 0.0
    assert data["by_category"] == []


@pytest.mark.asyncio
async def test_dashboard_summary_with_data(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    # Renda
    await client.post("/income", json={"amount": 5000.0, "date": "2026-07-01", "source": "Salário", "is_recurring": True, "recurrence_period": "monthly"}, headers=headers)
    # Categoria e gasto
    cat = await client.post("/categories", json={"name": "Energia", "type": "expense", "color": "#FF0000", "icon": "bolt"}, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={"category_id": cat_id, "description": "Luz", "amount": 250.0, "date": "2026-07-10", "type": "expense", "is_recurring": False}, headers=headers)
    # Busca summary para jul/2026
    response = await client.get("/dashboard/summary?month=7&year=2026", headers=headers)
    data = response.json()
    assert data["total_income"] == pytest.approx(5000.0)
    assert data["total_expense"] == pytest.approx(250.0)
    assert data["balance"] == pytest.approx(4750.0)
    assert len(data["by_category"]) == 1
    assert data["by_category"][0]["name"] == "Energia"


@pytest.mark.asyncio
async def test_dashboard_timeline_returns_events(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    # Transação futura
    cat = await client.post("/categories", json={"name": "Transporte", "type": "expense", "color": "#00FF00", "icon": "bus"}, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={"category_id": cat_id, "description": "Ônibus", "amount": 300.0, "date": "2026-08-05", "type": "expense", "is_recurring": True, "recurrence_period": "monthly"}, headers=headers)
    # Plano futuro
    await client.post("/plans", json={"name": "Japão", "target_amount": 15000.0, "current_savings": 3000.0, "monthly_contribution": 800.0, "priority": 1}, headers=headers)
    response = await client.get("/dashboard/timeline?months_ahead=6", headers=headers)
    assert response.status_code == 200
    events = response.json()
    assert len(events) >= 1
    types = [e["type"] for e in events]
    assert "plan_milestone" in types or "transaction" in types


import pytest
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
pytest tests/test_dashboard.py -v
```

Esperado: `ERROR` (router não existe).

- [ ] **Step 3: Criar app/services/timeline_builder.py**

```python
from dataclasses import dataclass
from datetime import date, datetime, timezone
from typing import Optional
from dateutil.relativedelta import relativedelta
from app.services.plan_simulator import simulate_plan


@dataclass
class TimelineEvent:
    date: date
    type: str  # "transaction" | "plan_milestone"
    label: str
    amount: Optional[float]
    color: str
    icon: str
    category: Optional[str]


def build_timeline(
    transactions: list,
    plans: list,
    reference_date: date,
    months_ahead: int = 6,
) -> list[TimelineEvent]:
    """Monta lista de eventos ordenados por data para a timeline visual."""
    events: list[TimelineEvent] = []
    cutoff = reference_date + relativedelta(months=months_ahead)

    # Transações dentro da janela (hoje → cutoff)
    for tx in transactions:
        tx_date = tx.date if isinstance(tx.date, date) else tx.date
        if reference_date <= tx_date <= cutoff:
            color = "#EF4444" if tx.is_recurring else "#F59E0B"
            events.append(TimelineEvent(
                date=tx_date,
                type="transaction",
                label=tx.description,
                amount=tx.amount,
                color=color,
                icon="receipt",
                category=None,
            ))

    # Marcos dos planos (data estimada de conclusão)
    for plan in plans:
        if plan.status not in ("active", "paused"):
            continue
        sim = simulate_plan(
            target_amount=plan.target_amount,
            current_savings=plan.current_savings,
            monthly_contribution=plan.monthly_contribution,
            reference_date=reference_date,
        )
        target_date = plan.deadline or sim.estimated_date
        if target_date and target_date >= reference_date:
            events.append(TimelineEvent(
                date=target_date,
                type="plan_milestone",
                label=plan.name,
                amount=plan.target_amount,
                color="#10B981",
                icon="flag",
                category=None,
            ))

    events.sort(key=lambda e: e.date)
    return events
```

- [ ] **Step 4: Criar app/routers/dashboard.py**

```python
from datetime import date, datetime, timezone
from calendar import monthrange
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from pydantic import BaseModel
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.transaction import Transaction
from app.models.income_entry import IncomeEntry
from app.models.category import Category
from app.models.plan import Plan
from app.services.timeline_builder import build_timeline, TimelineEvent

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


class CategorySummary(BaseModel):
    name: str
    color: str
    icon: str
    total: float
    percent: float


class DashboardSummary(BaseModel):
    total_income: float
    total_expense: float
    balance: float
    savings_percent: float
    by_category: list[CategorySummary]


class TimelineEventResponse(BaseModel):
    date: date
    type: str
    label: str
    amount: Optional[float]
    color: str
    icon: str
    category: Optional[str]


@router.get("/summary", response_model=DashboardSummary)
async def get_summary(
    month: Optional[int] = Query(None, ge=1, le=12),
    year: Optional[int] = Query(None),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    now = datetime.now(timezone.utc).date()
    ref_month = month or now.month
    ref_year = year or now.year
    last_day = monthrange(ref_year, ref_month)[1]
    start = date(ref_year, ref_month, 1)
    end = date(ref_year, ref_month, last_day)

    # Total de renda no período
    income_result = await session.execute(
        select(func.sum(IncomeEntry.amount)).where(
            and_(IncomeEntry.user_id == current_user.id, IncomeEntry.date >= start, IncomeEntry.date <= end)
        )
    )
    total_income = income_result.scalar_one() or 0.0

    # Total de gastos no período
    expense_result = await session.execute(
        select(func.sum(Transaction.amount)).where(
            and_(
                Transaction.user_id == current_user.id,
                Transaction.type == "expense",
                Transaction.date >= start,
                Transaction.date <= end,
            )
        )
    )
    total_expense = expense_result.scalar_one() or 0.0

    # Gastos por categoria
    cats_result = await session.execute(
        select(Category).where(Category.user_id == current_user.id, Category.type == "expense")
    )
    categories = cats_result.scalars().all()

    by_category = []
    for cat in categories:
        cat_total_result = await session.execute(
            select(func.sum(Transaction.amount)).where(
                and_(
                    Transaction.user_id == current_user.id,
                    Transaction.category_id == cat.id,
                    Transaction.type == "expense",
                    Transaction.date >= start,
                    Transaction.date <= end,
                )
            )
        )
        cat_total = cat_total_result.scalar_one() or 0.0
        if cat_total > 0:
            by_category.append(CategorySummary(
                name=cat.name,
                color=cat.color,
                icon=cat.icon,
                total=round(cat_total, 2),
                percent=round((cat_total / total_expense * 100) if total_expense > 0 else 0.0, 1),
            ))

    balance = total_income - total_expense
    savings_percent = round((balance / total_income * 100) if total_income > 0 else 0.0, 1)

    return DashboardSummary(
        total_income=round(total_income, 2),
        total_expense=round(total_expense, 2),
        balance=round(balance, 2),
        savings_percent=savings_percent,
        by_category=sorted(by_category, key=lambda x: x.total, reverse=True),
    )


@router.get("/timeline", response_model=list[TimelineEventResponse])
async def get_timeline(
    months_ahead: int = Query(6, ge=1, le=24),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    now = datetime.now(timezone.utc).date()
    cutoff = now
    from dateutil.relativedelta import relativedelta
    cutoff = now + relativedelta(months=months_ahead)

    tx_result = await session.execute(
        select(Transaction).where(
            and_(Transaction.user_id == current_user.id, Transaction.date >= now, Transaction.date <= cutoff)
        )
    )
    transactions = tx_result.scalars().all()

    plans_result = await session.execute(
        select(Plan).where(Plan.user_id == current_user.id, Plan.status.in_(["active", "paused"]))
    )
    plans = plans_result.scalars().all()

    events = build_timeline(transactions, plans, reference_date=now, months_ahead=months_ahead)
    return [TimelineEventResponse(
        date=e.date, type=e.type, label=e.label, amount=e.amount,
        color=e.color, icon=e.icon, category=e.category
    ) for e in events]
```

- [ ] **Step 5: Registrar em main.py**

Em `app/main.py`:
```python
from app.routers import dashboard as dashboard_router
app.include_router(dashboard_router.router)
```

- [ ] **Step 6: Rodar testes**

```bash
pytest tests/test_dashboard.py -v
```

Esperado: todos os 3 testes `PASSED`.

- [ ] **Step 7: Rodar suite completa**

```bash
pytest -v
```

Esperado: todos os testes dos planos 1 e 2 passando (25+ testes).

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "feat: dashboard summary e timeline builder com planos e transações"
```

---

## Self-Review do Plano 2

**Spec coverage:**
- ✅ Planos com sub-planos (1 nível) — Task 8
- ✅ Status: active/paused/cancelled/completed — Task 6 + 8
- ✅ Simulador interativo de prazo — Task 7 + 8
- ✅ Histórico de aportes — Task 8
- ✅ Renda variável usada no dashboard summary — Task 9
- ✅ Timeline visual com transações futuras + marcos de planos — Task 9
- ✅ Plano auto-completa ao atingir target via aporte — Task 8

**Type consistency:**
- `simulate_plan()` usa os mesmos parâmetros em `plan_simulator.py` e nos routers ✅
- `TimelineEvent` dataclass é convertida para `TimelineEventResponse` Pydantic no router ✅
- `PlanSimulation` é dataclass, embutida em `PlanDetailResponse` via `Optional[PlanSimulation]` ✅

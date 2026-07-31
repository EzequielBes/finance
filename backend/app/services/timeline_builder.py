from dataclasses import dataclass
from datetime import date, datetime, timezone
from typing import Optional, Union
from dateutil.relativedelta import relativedelta
from app.services.plan_simulator import simulate_plan


@dataclass
class TransactionEvent:
    type: str
    id: int
    title: str
    amount: float
    date: date
    category: Optional[str]
    transaction_type: str
    is_recurring: bool
    installments_total: Optional[int]

@dataclass
class PlanEvent:
    type: str
    id: int
    title: str
    target_amount: float
    date: date
    plan_name: str
    status: str

TimelineEvent = Union[TransactionEvent, PlanEvent]


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
            category_name = tx.category.name if getattr(tx, "category", None) else None
            events.append(TransactionEvent(
                date=tx_date,
                type="transaction",
                id=tx.id,
                title=tx.description,
                amount=tx.amount,
                category=category_name,
                transaction_type=tx.type,
                is_recurring=tx.is_recurring,
                installments_total=tx.installments_total,
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
        if target_date and reference_date <= target_date <= cutoff:
            events.append(PlanEvent(
                date=target_date,
                type="plan_milestone",
                id=plan.id,
                title=plan.name,
                target_amount=plan.target_amount,
                plan_name=plan.name,
                status=plan.status,
            ))

    events.sort(key=lambda e: e.date)
    return events

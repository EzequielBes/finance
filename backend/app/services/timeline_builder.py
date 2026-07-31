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

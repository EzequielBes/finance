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

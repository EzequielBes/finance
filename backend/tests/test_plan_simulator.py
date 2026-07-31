from datetime import date
import pytest
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

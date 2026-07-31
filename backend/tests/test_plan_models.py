import pytest
from datetime import date, datetime, timezone
from sqlalchemy import select
from app.models.plan import Plan, PlanStatus
from app.models.plan_contribution import PlanContribution
from app.models.user import User
from tests.conftest import TestSessionLocal


@pytest.mark.asyncio
async def test_plan_status_enum():
    assert PlanStatus.active.value == "active"
    assert PlanStatus.paused.value == "paused"
    assert PlanStatus.cancelled.value == "cancelled"
    assert PlanStatus.completed.value == "completed"


@pytest.mark.asyncio
async def test_create_plan_and_contribution_models():
    async with TestSessionLocal() as session:
        # Create user
        user = User(email="plan_user@example.com", password_hash="hashed_pass", name="Plan User")
        session.add(user)
        await session.commit()
        await session.refresh(user)

        # Create parent plan
        parent_plan = Plan(
            user_id=user.id,
            name="Viagem para Europa",
            description="Economizar para a viagem de férias",
            target_amount=15000.0,
            monthly_contribution=1000.0,
            deadline=date(2027, 12, 31),
            notes="Objetivo principal"
        )
        session.add(parent_plan)
        await session.commit()
        await session.refresh(parent_plan)

        assert parent_plan.id is not None
        assert parent_plan.user_id == user.id
        assert parent_plan.parent_plan_id is None
        assert parent_plan.name == "Viagem para Europa"
        assert parent_plan.description == "Economizar para a viagem de férias"
        assert parent_plan.target_amount == 15000.0
        assert parent_plan.current_savings == 0.0
        assert parent_plan.monthly_contribution == 1000.0
        assert parent_plan.deadline == date(2027, 12, 31)
        assert parent_plan.status == PlanStatus.active
        assert parent_plan.priority == 1
        assert parent_plan.notes == "Objetivo principal"
        assert parent_plan.created_at is not None
        assert parent_plan.updated_at is not None

        # Create child sub-plan
        child_plan = Plan(
            user_id=user.id,
            parent_plan_id=parent_plan.id,
            name="Passagens Aéreas",
            target_amount=5000.0,
            monthly_contribution=500.0,
            priority=2
        )
        session.add(child_plan)
        await session.commit()
        await session.refresh(child_plan)

        assert child_plan.parent_plan_id == parent_plan.id
        assert child_plan.priority == 2

        # Create plan contribution
        contribution = PlanContribution(
            plan_id=parent_plan.id,
            amount=500.0,
            date=date(2026, 8, 1),
            notes="Primeiro aporte"
        )
        session.add(contribution)
        await session.commit()
        await session.refresh(contribution)

        assert contribution.id is not None
        assert contribution.plan_id == parent_plan.id
        assert contribution.amount == 500.0
        assert contribution.date == date(2026, 8, 1)
        assert contribution.notes == "Primeiro aporte"
        assert contribution.created_at is not None

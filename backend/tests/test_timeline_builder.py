from datetime import date
from dateutil.relativedelta import relativedelta
from app.services.timeline_builder import build_timeline
from dataclasses import dataclass
from typing import Optional


@dataclass
class DummyCategory:
    name: str

@dataclass
class DummyTransaction:
    id: int
    date: date
    description: str
    amount: float
    is_recurring: bool
    type: str
    category: Optional[DummyCategory] = None
    installments_total: Optional[int] = None


@dataclass
class DummyPlan:
    id: int
    name: str
    target_amount: float
    current_savings: float
    monthly_contribution: float
    status: str
    deadline: Optional[date]


def test_build_timeline():
    today = date(2026, 7, 31)
    
    tx1 = DummyTransaction(
        id=1,
        date=today + relativedelta(days=5),
        description="Test TX",
        amount=100.0,
        is_recurring=False,
        type="expense",
        category=DummyCategory(name="Food")
    )
    plan1 = DummyPlan(
        id=2,
        name="Test Plan",
        target_amount=1000.0,
        current_savings=0.0,
        monthly_contribution=500.0,
        status="active",
        deadline=today + relativedelta(months=2)
    )
    
    events = build_timeline([tx1], [plan1], reference_date=today, months_ahead=6)
    
    assert len(events) == 2
    
    assert events[0].type == "transaction"
    assert events[0].title == "Test TX"
    assert events[0].date == today + relativedelta(days=5)
    assert events[0].category == "Food"
    
    assert events[1].type == "plan_milestone"
    assert events[1].title == "Test Plan"
    assert events[1].date == today + relativedelta(months=2)

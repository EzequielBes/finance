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

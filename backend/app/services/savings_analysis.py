from datetime import date
from dateutil.relativedelta import relativedelta
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.category import Category
from app.models.transaction import Transaction

ESSENTIAL_CATEGORY_NAMES = {"moradia", "saúde", "contas fixas"}


def is_essential_category(name: str) -> bool:
    return name.strip().lower() in ESSENTIAL_CATEGORY_NAMES


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

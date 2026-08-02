from datetime import date
from dateutil.relativedelta import relativedelta
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.category import Category
from app.models.transaction import Transaction
from app.schemas.report import SavingsAnalysisItem

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
                Transaction.type == "expense",
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
                Transaction.type == "expense",
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

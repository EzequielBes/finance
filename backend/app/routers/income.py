from datetime import date, datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.income_entry import IncomeEntry
from app.schemas.income_entry import IncomeEntryCreate, IncomeEntryUpdate, IncomeEntryResponse, IncomeSummaryResponse
from dateutil.relativedelta import relativedelta
from calendar import monthrange

router = APIRouter(prefix="/income", tags=["income"])


@router.post("", response_model=IncomeEntryResponse, status_code=201)
async def create_income(
    payload: IncomeEntryCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    entry = IncomeEntry(**payload.model_dump(), user_id=current_user.id)
    session.add(entry)
    await session.commit()
    await session.refresh(entry)
    return entry


@router.get("/summary", response_model=IncomeSummaryResponse)
async def get_income_summary(
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    now = datetime.now(timezone.utc).date()
    # Média dos últimos 3 meses
    three_months_ago = now - relativedelta(months=3)
    avg_result = await session.execute(
        select(func.avg(IncomeEntry.amount)).where(
            and_(IncomeEntry.user_id == current_user.id, IncomeEntry.date >= three_months_ago)
        )
    )
    avg = avg_result.scalar_one() or 0.0

    # Total do mês atual
    last_day = monthrange(now.year, now.month)[1]
    total_result = await session.execute(
        select(func.sum(IncomeEntry.amount)).where(
            and_(
                IncomeEntry.user_id == current_user.id,
                IncomeEntry.date >= date(now.year, now.month, 1),
                IncomeEntry.date <= date(now.year, now.month, last_day),
            )
        )
    )
    total = total_result.scalar_one() or 0.0
    return IncomeSummaryResponse(average_last_3_months=round(avg, 2), total_this_month=round(total, 2))


@router.get("", response_model=list[IncomeEntryResponse])
async def list_income(
    month: Optional[int] = Query(None, ge=1, le=12),
    year: Optional[int] = Query(None),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    filters = [IncomeEntry.user_id == current_user.id]
    if month and year:
        last_day = monthrange(year, month)[1]
        filters.append(IncomeEntry.date >= date(year, month, 1))
        filters.append(IncomeEntry.date <= date(year, month, last_day))
    result = await session.execute(
        select(IncomeEntry).where(and_(*filters)).order_by(IncomeEntry.date.desc())
    )
    return result.scalars().all()


@router.put("/{entry_id}", response_model=IncomeEntryResponse)
async def update_income(
    entry_id: int,
    payload: IncomeEntryUpdate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(IncomeEntry).where(IncomeEntry.id == entry_id, IncomeEntry.user_id == current_user.id)
    )
    entry = result.scalar_one_or_none()
    if not entry:
        raise HTTPException(status_code=404, detail="Entrada de renda não encontrada")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(entry, key, value)
    await session.commit()
    await session.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=204)
async def delete_income(
    entry_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(IncomeEntry).where(IncomeEntry.id == entry_id, IncomeEntry.user_id == current_user.id)
    )
    entry = result.scalar_one_or_none()
    if not entry:
        raise HTTPException(status_code=404, detail="Entrada de renda não encontrada")
    await session.delete(entry)
    await session.commit()

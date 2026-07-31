import calendar
import uuid
from datetime import date
from dateutil.relativedelta import relativedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.category import Category
from app.models.transaction import Transaction
from app.schemas.transaction import TransactionCreate, TransactionUpdate, TransactionResponse, TransactionListResponse

router = APIRouter(prefix="/transactions", tags=["transactions"])


def _build_installments(payload: TransactionCreate, user_id: int) -> list[Transaction]:
    group_id = str(uuid.uuid4())
    transactions = []
    base_date = payload.date
    for i in range(1, payload.installments_total + 1):
        tx_date = base_date + relativedelta(months=i - 1)
        transactions.append(Transaction(
            user_id=user_id,
            category_id=payload.category_id,
            description=f"{payload.description} ({i}/{payload.installments_total})",
            amount=payload.amount,
            date=tx_date,
            type=payload.type,
            is_recurring=False,
            installments_total=payload.installments_total,
            installments_current=i,
            installment_group_id=group_id,
        ))
    return transactions


@router.post("", response_model=TransactionResponse, status_code=201)
async def create_transaction(
    payload: TransactionCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    if payload.category_id is not None:
        cat_result = await session.execute(
            select(Category).where(Category.id == payload.category_id, Category.user_id == current_user.id)
        )
        if not cat_result.scalar_one_or_none():
            raise HTTPException(status_code=404, detail="Categoria não encontrada")

    if payload.installments_total and payload.installments_total > 1:
        transactions = _build_installments(payload, current_user.id)
        for tx in transactions:
            session.add(tx)
        await session.commit()
        await session.refresh(transactions[0])
        return transactions[0]
    
    tx = Transaction(
        user_id=current_user.id,
        category_id=payload.category_id,
        description=payload.description,
        amount=payload.amount,
        date=payload.date,
        type=payload.type,
        is_recurring=payload.is_recurring,
        recurrence_period=payload.recurrence_period,
    )
    session.add(tx)
    await session.commit()
    await session.refresh(tx)
    return tx


@router.get("", response_model=TransactionListResponse)
async def list_transactions(
    month: Optional[int] = Query(None, ge=1, le=12),
    year: Optional[int] = Query(None),
    category_id: Optional[int] = None,
    type: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    filters = [Transaction.user_id == current_user.id]
    if year and month:
        last_day = calendar.monthrange(year, month)[1]
        filters.append(Transaction.date >= date(year, month, 1))
        filters.append(Transaction.date <= date(year, month, last_day))
    elif year:
        filters.append(Transaction.date >= date(year, 1, 1))
        filters.append(Transaction.date <= date(year, 12, 31))

    if category_id:
        filters.append(Transaction.category_id == category_id)
    if type:
        filters.append(Transaction.type == type)

    count_result = await session.execute(select(func.count(Transaction.id)).where(and_(*filters)))
    total = count_result.scalar_one()

    result = await session.execute(
        select(Transaction).where(and_(*filters))
        .order_by(Transaction.date.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    return TransactionListResponse(items=result.scalars().all(), total=total)


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(
    transaction_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
    )
    tx = result.scalar_one_or_none()
    if not tx:
        raise HTTPException(status_code=404, detail="Transação não encontrada")
    return tx


@router.put("/{transaction_id}", response_model=TransactionResponse)
async def update_transaction(
    transaction_id: int,
    payload: TransactionUpdate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
    )
    tx = result.scalar_one_or_none()
    if not tx:
        raise HTTPException(status_code=404, detail="Transação não encontrada")

    update_data = payload.model_dump(exclude_unset=True)

    if "category_id" in update_data and update_data["category_id"] is not None:
        cat_result = await session.execute(
            select(Category).where(Category.id == update_data["category_id"], Category.user_id == current_user.id)
        )
        if not cat_result.scalar_one_or_none():
            raise HTTPException(status_code=404, detail="Categoria não encontrada")

    for key, value in update_data.items():
        setattr(tx, key, value)
    await session.commit()
    await session.refresh(tx)
    return tx


@router.delete("/{transaction_id}", status_code=204)
async def delete_transaction(
    transaction_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
    )
    tx = result.scalar_one_or_none()
    if not tx:
        raise HTTPException(status_code=404, detail="Transação não encontrada")
    await session.delete(tx)
    await session.commit()

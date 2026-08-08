from datetime import date, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.transaction import Transaction, TransactionType
from app.schemas.bulk_transaction import BulkTransactionCreate, BulkImportResponse

router = APIRouter(prefix="/transactions/bulk", tags=["import"])


async def _is_duplicate(
    session: AsyncSession,
    user_id: int,
    description: str,
    amount: float,
    tx_date: date,
    tx_type: TransactionType,
) -> bool:
    """Verifica duplicata por (description, amount, date ± 1 dia, type)."""
    result = await session.execute(
        select(func.count(Transaction.id)).where(
            and_(
                Transaction.user_id == user_id,
                Transaction.description == description,
                Transaction.amount == amount,
                Transaction.type == tx_type,
                Transaction.date >= tx_date - timedelta(days=1),
                Transaction.date <= tx_date + timedelta(days=1),
            )
        )
    )
    return result.scalar_one() > 0


@router.post("", response_model=BulkImportResponse, status_code=201)
async def bulk_import_transactions(
    payload: BulkTransactionCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    inserted = 0
    skipped = 0
    for item in payload.transactions:
        if await _is_duplicate(session, current_user.id, item.description, item.amount, item.date, item.type):
            skipped += 1
            continue
        tx = Transaction(
            user_id=current_user.id,
            category_id=item.category_id,
            description=item.description,
            amount=item.amount,
            date=item.date,
            type=item.type,
            import_source=item.import_source,
        )
        session.add(tx)
        inserted += 1
    await session.commit()
    return BulkImportResponse(
        inserted=inserted,
        skipped_duplicates=skipped,
        total_received=len(payload.transactions),
    )

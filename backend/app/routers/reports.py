from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.schemas.report import SavingsAnalysisItem
from app.services.savings_analysis import build_savings_analysis

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/savings-analysis", response_model=list[SavingsAnalysisItem])
async def get_savings_analysis(
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    return await build_savings_analysis(session, current_user.id)

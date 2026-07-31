from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.plan import Plan, PlanStatus
from app.models.plan_contribution import PlanContribution
from app.schemas.plan import (
    PlanCreate, PlanUpdate, PlanResponse, PlanDetailResponse,
    PlanContributionCreate, PlanContributionResponse
)
from app.services.plan_simulator import simulate_plan

router = APIRouter(prefix="/plans", tags=["plans"])


def _build_simulation(plan: Plan):
    return simulate_plan(
        target_amount=plan.target_amount,
        current_savings=plan.current_savings,
        monthly_contribution=plan.monthly_contribution,
        reference_date=datetime.now(timezone.utc).date(),
    )


@router.post("", response_model=PlanResponse, status_code=201)
async def create_plan(
    payload: PlanCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    if payload.parent_plan_id:
        parent = await session.get(Plan, payload.parent_plan_id)
        if not parent or parent.user_id != current_user.id:
            raise HTTPException(status_code=404, detail="Plano pai não encontrado")
        if parent.parent_plan_id is not None:
            raise HTTPException(status_code=400, detail="Sub-planos não podem ter sub-planos (máx 1 nível)")
    plan = Plan(**payload.model_dump(), user_id=current_user.id)
    session.add(plan)
    await session.commit()
    await session.refresh(plan)
    return plan


@router.get("", response_model=list[PlanDetailResponse])
async def list_plans(
    include_sub: bool = False,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    q = select(Plan).where(Plan.user_id == current_user.id)
    if not include_sub:
        q = q.where(Plan.parent_plan_id == None)
    result = await session.execute(q.order_by(Plan.priority, Plan.created_at))
    plans = result.scalars().all()
    responses = []
    for plan in plans:
        sub_result = await session.execute(
            select(Plan).where(Plan.parent_plan_id == plan.id)
        )
        sub_plans = sub_result.scalars().all()
        responses.append(PlanDetailResponse(
            **PlanResponse.model_validate(plan).model_dump(),
            simulation=_build_simulation(plan),
            sub_plans=[PlanResponse.model_validate(s) for s in sub_plans],
        ))
    return responses


@router.get("/{plan_id}", response_model=PlanDetailResponse)
async def get_plan(
    plan_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    sub_result = await session.execute(select(Plan).where(Plan.parent_plan_id == plan.id))
    sub_plans = sub_result.scalars().all()
    return PlanDetailResponse(
        **PlanResponse.model_validate(plan).model_dump(),
        simulation=_build_simulation(plan),
        sub_plans=[PlanResponse.model_validate(s) for s in sub_plans],
    )


@router.get("/{plan_id}/simulate")
async def simulate_plan_endpoint(
    plan_id: int,
    monthly_contribution: float = Query(..., gt=0),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    return simulate_plan(
        target_amount=plan.target_amount,
        current_savings=plan.current_savings,
        monthly_contribution=monthly_contribution,
        reference_date=datetime.now(timezone.utc).date(),
    )


@router.put("/{plan_id}", response_model=PlanResponse)
async def update_plan(
    plan_id: int,
    payload: PlanUpdate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    for key, value in payload.model_dump(exclude_none=True).items():
        setattr(plan, key, value)
    plan.updated_at = datetime.now(timezone.utc)
    await session.commit()
    await session.refresh(plan)
    return plan


@router.delete("/{plan_id}", status_code=204)
async def delete_plan(
    plan_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    # Deletar sub-planos primeiro
    sub_result = await session.execute(select(Plan).where(Plan.parent_plan_id == plan.id))
    for sub in sub_result.scalars().all():
        await session.delete(sub)
    await session.delete(plan)
    await session.commit()


@router.post("/{plan_id}/contributions", response_model=PlanContributionResponse, status_code=201)
async def add_contribution(
    plan_id: int,
    payload: PlanContributionCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    contribution = PlanContribution(plan_id=plan_id, **payload.model_dump())
    session.add(contribution)
    plan.current_savings += payload.amount
    plan.updated_at = datetime.now(timezone.utc)
    if plan.current_savings >= plan.target_amount:
        plan.status = PlanStatus.completed
    await session.commit()
    await session.refresh(contribution)
    return contribution


@router.get("/{plan_id}/contributions", response_model=list[PlanContributionResponse])
async def list_contributions(
    plan_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    plan_result = await session.execute(
        select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id)
    )
    if not plan_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    result = await session.execute(
        select(PlanContribution).where(PlanContribution.plan_id == plan_id)
        .order_by(PlanContribution.date.desc())
    )
    return result.scalars().all()

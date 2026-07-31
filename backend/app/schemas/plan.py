from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel
from app.models.plan import PlanStatus
from app.services.plan_simulator import PlanSimulation


class PlanCreate(BaseModel):
    name: str
    description: Optional[str] = None
    target_amount: float
    current_savings: float = 0.0
    monthly_contribution: float
    deadline: Optional[date] = None
    priority: int = 1
    notes: Optional[str] = None
    parent_plan_id: Optional[int] = None


class PlanUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    target_amount: Optional[float] = None
    monthly_contribution: Optional[float] = None
    deadline: Optional[date] = None
    status: Optional[PlanStatus] = None
    priority: Optional[int] = None
    notes: Optional[str] = None


class PlanResponse(BaseModel):
    id: int
    user_id: int
    parent_plan_id: Optional[int]
    name: str
    description: Optional[str]
    target_amount: float
    current_savings: float
    monthly_contribution: float
    deadline: Optional[date]
    status: PlanStatus
    priority: int
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class PlanDetailResponse(PlanResponse):
    simulation: Optional[PlanSimulation] = None
    sub_plans: list[PlanResponse] = []


class PlanContributionCreate(BaseModel):
    amount: float
    date: date
    notes: Optional[str] = None


class PlanContributionResponse(BaseModel):
    id: int
    plan_id: int
    amount: float
    date: date
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}

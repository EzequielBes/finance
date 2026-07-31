from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel
from app.models.income_entry import IncomeRecurrencePeriod


class IncomeEntryCreate(BaseModel):
    amount: float
    date: date
    source: str
    is_recurring: bool = False
    recurrence_period: Optional[IncomeRecurrencePeriod] = None
    notes: Optional[str] = None


class IncomeEntryUpdate(BaseModel):
    amount: Optional[float] = None
    date: Optional[date] = None
    source: Optional[str] = None
    is_recurring: Optional[bool] = None
    recurrence_period: Optional[IncomeRecurrencePeriod] = None
    notes: Optional[str] = None


class IncomeEntryResponse(BaseModel):
    id: int
    user_id: int
    amount: float
    date: date
    source: str
    is_recurring: bool
    recurrence_period: Optional[IncomeRecurrencePeriod]
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class IncomeSummaryResponse(BaseModel):
    average_last_3_months: float
    total_this_month: float

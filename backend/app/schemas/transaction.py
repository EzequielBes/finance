from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel
from app.models.transaction import TransactionType, RecurrencePeriod


class TransactionCreate(BaseModel):
    category_id: Optional[int] = None
    description: str
    amount: float
    date: date
    type: TransactionType
    is_recurring: bool = False
    recurrence_period: Optional[RecurrencePeriod] = None
    installments_total: Optional[int] = None


class TransactionUpdate(BaseModel):
    description: Optional[str] = None
    amount: Optional[float] = None
    date: Optional[date] = None
    category_id: Optional[int] = None


class TransactionResponse(BaseModel):
    id: int
    user_id: int
    category_id: Optional[int]
    description: str
    amount: float
    date: date
    type: TransactionType
    is_recurring: bool
    recurrence_period: Optional[RecurrencePeriod]
    installments_total: Optional[int]
    installments_current: Optional[int]
    installment_group_id: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    items: list[TransactionResponse]
    total: int

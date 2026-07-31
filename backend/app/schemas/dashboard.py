from datetime import date
from typing import Literal, Union, Annotated, Optional
from pydantic import BaseModel, Field

class TransactionTimelineItem(BaseModel):
    type: Literal["transaction"]
    id: int
    title: str
    amount: float
    date: date
    category: Optional[str] = None
    transaction_type: str

class PlanMilestoneTimelineItem(BaseModel):
    type: Literal["plan_milestone"]
    id: int
    title: str
    target_amount: float
    date: date
    plan_name: str

TimelineEventResponse = Annotated[
    Union[TransactionTimelineItem, PlanMilestoneTimelineItem],
    Field(discriminator="type")
]

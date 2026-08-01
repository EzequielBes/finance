from pydantic import BaseModel
from app.models.category import CategoryType


class CategoryCreate(BaseModel):
    name: str
    type: CategoryType
    color: str = "#6C63FF"
    icon: str = "tag"
    monthly_limit: float | None = None


class CategoryUpdate(BaseModel):
    name: str
    type: CategoryType
    color: str
    icon: str
    monthly_limit: float | None = None


class CategoryResponse(BaseModel):
    id: int
    user_id: int
    name: str
    type: CategoryType
    color: str
    icon: str
    monthly_limit: float | None
    current_month_usage: float = 0.0

    model_config = {"from_attributes": True}

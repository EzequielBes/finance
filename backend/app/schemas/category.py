from pydantic import BaseModel
from app.models.category import CategoryType


class CategoryCreate(BaseModel):
    name: str
    type: CategoryType
    color: str = "#6C63FF"
    icon: str = "tag"


class CategoryUpdate(BaseModel):
    name: str
    type: CategoryType
    color: str
    icon: str


class CategoryResponse(BaseModel):
    id: int
    user_id: int
    name: str
    type: CategoryType
    color: str
    icon: str

    model_config = {"from_attributes": True}

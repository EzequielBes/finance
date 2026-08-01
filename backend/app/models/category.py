import enum
from sqlalchemy import Integer, String, Float, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class CategoryType(str, enum.Enum):
    income = "income"
    expense = "expense"


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    type: Mapped[CategoryType] = mapped_column(SAEnum(CategoryType), nullable=False)
    color: Mapped[str] = mapped_column(String(7), nullable=False, default="#6C63FF")
    icon: Mapped[str] = mapped_column(String(50), nullable=False, default="tag")
    monthly_limit: Mapped[float | None] = mapped_column(Float, nullable=True)

import enum
from datetime import date, datetime, timezone
from sqlalchemy import Integer, String, Float, Boolean, Date, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class TransactionType(str, enum.Enum):
    income = "income"
    expense = "expense"


class RecurrencePeriod(str, enum.Enum):
    monthly = "monthly"
    weekly = "weekly"
    yearly = "yearly"


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    category_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("categories.id"), nullable=True)
    description: Mapped[str] = mapped_column(String(255), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    type: Mapped[TransactionType] = mapped_column(SAEnum(TransactionType), nullable=False)
    is_recurring: Mapped[bool] = mapped_column(Boolean, default=False)
    recurrence_period: Mapped[RecurrencePeriod | None] = mapped_column(SAEnum(RecurrencePeriod), nullable=True)
    installments_total: Mapped[int | None] = mapped_column(Integer, nullable=True)
    installments_current: Mapped[int | None] = mapped_column(Integer, nullable=True)
    installment_group_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

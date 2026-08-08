from datetime import date
from pydantic import BaseModel, Field
from app.models.transaction import TransactionType


class BulkTransactionItem(BaseModel):
    description: str = Field(..., min_length=1, max_length=255)
    amount: float = Field(..., gt=0)
    date: date
    type: TransactionType
    category_id: int | None = None
    import_source: str = Field(..., min_length=1, max_length=64)


class BulkTransactionCreate(BaseModel):
    transactions: list[BulkTransactionItem] = Field(..., min_length=1, max_length=500)


class BulkImportResponse(BaseModel):
    inserted: int
    skipped_duplicates: int
    total_received: int

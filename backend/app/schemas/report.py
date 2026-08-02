from pydantic import BaseModel


class SavingsAnalysisItem(BaseModel):
    category_id: int
    category_name: str
    category_color: str
    is_essential: bool
    current_amount: float
    reference_amount: float
    reference_source: str
    percent: float
    suggested_cut: float | None

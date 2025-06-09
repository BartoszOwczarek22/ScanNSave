from pydantic import BaseModel
from typing import List, Optional

class ReceiptItem(BaseModel):
    name: str
    quantity: float
    price: float

class Receipt(BaseModel):
    storeName: str
    date: Optional[str] = None
    items: List[ReceiptItem]
    total: float
    userId: str

class ReceiptResponse(BaseModel):
    message: str
    data: Optional[dict] = None
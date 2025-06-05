from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date

class ParagonItem(BaseModel):
    name: str
    quantity: int
    price: float
    product_id: Optional[int] = None  

class ReceiptIndeksItem(BaseModel):
    indeks: str  # Nazwa produktu
    price: float
    product_id: Optional[int] = None
    shop_id: Optional[int] = None

class ParagonInput(BaseModel):
    token: str  #
    date: str
    shop_name: str  
    location: Optional[str] = None 
    sum_price: float
    pic_path: Optional[str] = None
    receipt_indekses: List[ReceiptIndeksItem]

class ParagonResponse(BaseModel):
    id: int
    creator_id: str
    create_date: datetime
    date: date
    pic_path: Optional[str]
    shop_parcel_id: int
    sum_price: float
    shop_name: Optional[str] = None
    location: Optional[str] = None
    receipt_indekses: List[dict]

class ParagonListResponse(BaseModel):
    paragons: List[ParagonResponse]
    total_count: int
    page: int
    page_size: int
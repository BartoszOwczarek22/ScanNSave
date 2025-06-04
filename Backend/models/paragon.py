from pydantic import BaseModel
from typing import List, Optional
from datetime import date, datetime
from uuid import UUID
import json


class ParagonItem(BaseModel):
    name: str
    quantity: int
    price: float
    product_id: Optional[int] = None  


class ParagonInput(BaseModel):
    storeName: str
    date: Optional[str] = None
    items: List[ParagonItem]
    total: float
    user_id: UUID
    pic_path: Optional[str] = None  # Ścieżka do zdjęcia paragonu
    shop_parcel_id: Optional[UUID] = None 

    class Config:
        allow_population_by_field_name = True


class ParagonResponse(BaseModel):
    id: int
    creator_id: UUID
    create_date: datetime
    date: Optional[str]
    pic_path: Optional[str]
    shop_parcel_id: Optional[UUID] = None
    sum_price: float
    shop_name: Optional[str]
    location: Optional[str]
    items: List[ParagonItem]

    class Config:
        json_encoders = {
            UUID: lambda v: str(v)
        }

    @classmethod
    def from_db_row(cls, row: dict, items: List[ParagonItem] = None, shop_info: dict = None):
        return cls(
            id=row['id'],
            creator_id=row['creator_id'],
            create_date=row['create_date'],
            date=row.get('date'),
            pic_path=row.get('pic_path'),
            shop_parcel_id=row.get('shop_parcel_id'),
            sum_price=row['sum_price'],
            shop_name=shop_info.get('shop_name') if shop_info else None,
            location=shop_info.get('location') if shop_info else None,
            items=items or []
        )


class ParagonListResponse(BaseModel):
    paragons: List[ParagonResponse]
    total_count: int
    page: int
    page_size: int


class ReceiptShareInput(BaseModel):
    receipt_id: int
    user_id: UUID


class ProductCreate(BaseModel):
    name: str
    category_id: Optional[int] = None
    unit: Optional[str] = None


class CategoryCreate(BaseModel):
    name: str


class ShopCreate(BaseModel):
    name: str


class ShopParcelCreate(BaseModel):
    location: str
    shops_id: int
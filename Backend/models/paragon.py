from pydantic import BaseModel
from typing import List, Optional
from datetime import date, datetime
import json


class ParagonItem(BaseModel):
    name: str
    quantity: int
    price: float

class ParagonInput(BaseModel):
    storeName: str
    date: Optional[str] = None
    items: List[ParagonItem]
    total: float

    class Config:
        allow_population_by_field_name = True

class ParagonResponse(BaseModel):
    id: int
    created_at: datetime
    date: Optional[str]
    storeName: Optional[str]
    items: List[ParagonItem]
    total: Optional[float]

    @classmethod
    def from_db_row(cls, row: dict):
        items_data = []
        if row.get('items'):
            try:
                if isinstance(row['items'], str):
                    items_json = json.loads(row['items'])
                else:
                    items_json = row['items']

                items_data = [ParagonItem(**item) for item in items_json]
            except (json.JSONDecodeError, TypeError, KeyError):
                items_data = []
        
        return cls(
            id=row['id'],
            created_at=row['created_at'],
            date=row.get('date'),
            storeName=row.get('storeName'),
            items=items_data,
            total=row.get('total')
        )

class ParagonListResponse(BaseModel):
    paragons: List[ParagonResponse]
    total_count: int
    page: int
    page_size: int
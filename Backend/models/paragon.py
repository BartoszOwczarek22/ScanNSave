from pydantic import BaseModel
from typing import List
from datetime import date
from typing import Optional


class ParagonItem(BaseModel):
    name: str
    quantity: int
    price: float

class ParagonInput(BaseModel):
    storeName: str
    date: Optional[date] = None
    items: List[ParagonItem]
    total: float

    class Config:
        allow_population_by_field_name = True
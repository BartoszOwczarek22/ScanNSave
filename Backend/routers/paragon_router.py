from fastapi import APIRouter, Query, HTTPException
from models.paragon import ParagonInput, ParagonResponse, ParagonListResponse
from services import paragon_service
from typing import Optional, List

router = APIRouter(prefix="/paragon", tags=["paragon"])

@router.post("/save")
async def save_paragon_test(input_data: ParagonInput):
    return await paragon_service.save_paragon_test(input_data)

@router.post("/save-to-db")
def save_paragon_to_db(input_data: ParagonInput):
    return paragon_service.save_paragon(input_data)

@router.get("/list", response_model=ParagonListResponse)
def get_paragons(
    page: int = Query(1, ge=1, description="Numer strony (zaczyna od 1)"),
    page_size: int = Query(10, ge=1, le=100, description="Liczba elementów na stronę (max 100)"),
    store_name: Optional[str] = Query(None, description="Filtr po nazwie sklepu")
):

    return paragon_service.get_paragons(page=page, page_size=page_size, store_name=store_name)

@router.get("/{paragon_id}", response_model=ParagonResponse)
def get_paragon_by_id(paragon_id: int):
    paragon = paragon_service.get_paragon_by_id(paragon_id)
    if not paragon:
        raise HTTPException(status_code=404, detail="Paragon nie został znaleziony")
    return paragon

@router.get("/date-range/", response_model=List[ParagonResponse])
def get_paragons_by_date_range(
    start_date: str = Query(..., description="Data początkowa (YYYY-MM-DD)"),
    end_date: str = Query(..., description="Data końcowa (YYYY-MM-DD)")
):
    return paragon_service.get_paragons_by_date_range(start_date, end_date)
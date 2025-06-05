from fastapi import APIRouter, HTTPException, Query
from models.paragon import (
    ParagonInput, ParagonListResponse, 
)
from services.paragon_service import (
    get_paragons_for_user, 
    get_paragon_by_id,
    get_paragons_in_date_range
)
from typing import Optional

router = APIRouter(prefix="/paragon", tags=["paragon"])


@router.get("/list")
def get_user_paragons(
    user_id: str = Query(..., description="Firebase UID użytkownika"),
    page: int = Query(1, ge=1, description="Numer strony"),
    page_size: int = Query(10, ge=1, le=100, description="Liczba elementów na stronie"),
    store_name: Optional[str] = Query(None, description="Filtr po nazwie sklepu")
):
    """
    Pobiera listę paragonów dla konkretnego użytkownika z informacjami o sklepie i indeksach
    """
    result = get_paragons_for_user(user_id, page, page_size, store_name)
    
    if result["success"]:
        return {
            "paragons": result["paragons"],
            "total_count": result["total_count"],
            "page": result["page"],
            "page_size": result["page_size"],
            "total_pages": result["total_pages"]
        }
    else:
        raise HTTPException(status_code=400, detail=result["error"])

@router.get("/{paragon_id}")
def get_paragon_details(
    paragon_id: int,
    user_id: str = Query(..., description="Firebase UID użytkownika")
):
    """
    Pobiera szczegóły konkretnego paragonu z indeksami
    """
    result = get_paragon_by_id(paragon_id, user_id)
    
    if result["success"]:
        return result["paragon"]
    else:
        if "nie został znaleziony" in result["error"]:
            raise HTTPException(status_code=404, detail=result["error"])
        else:
            raise HTTPException(status_code=400, detail=result["error"])

@router.get("/date-range/")
def get_paragons_by_date_range(
    user_id: str = Query(..., description="Firebase UID użytkownika"),
    start_date: str = Query(..., description="Data początkowa (YYYY-MM-DD)"),
    end_date: str = Query(..., description="Data końcowa (YYYY-MM-DD)")
):
    """
    Pobiera paragony użytkownika w określonym zakresie dat
    """
    result = get_paragons_in_date_range(user_id, start_date, end_date)
    
    if result["success"]:
        return result["paragons"]
    else:
        raise HTTPException(status_code=400, detail=result["error"])
from fastapi import APIRouter, Query, HTTPException, Depends
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from models.paragon import (
    ParagonInput, ParagonResponse, ParagonListResponse, 
    ReceiptShareInput, ProductCreate, CategoryCreate, 
    ShopCreate, ShopParcelCreate
)
from services import paragon_service
from typing import Optional, List

router = APIRouter(prefix="/paragon", tags=["paragon"])

def get_current_user_id() -> int:
    return 1

@router.post("/save")
def save_paragon_to_db(input_data: ParagonInput):
    result = paragon_service.save_paragon(input_data)
    return JSONResponse(content=jsonable_encoder(result))

@router.get("/list", response_model=ParagonListResponse)
def get_paragons(
    page: int = Query(1, ge=1, description="Numer strony (zaczyna od 1)"),
    page_size: int = Query(10, ge=1, le=100, description="Liczba elementów na stronę (max 100)"),
    store_name: Optional[str] = Query(None, description="Filtr po nazwie sklepu"),
    user_id: Optional[int] = Query(None, description="ID użytkownika (jeśli nie podano, pobiera dla wszystkich)")
):
    """Pobiera listę paragonów z tabeli receipts z możliwością filtrowania"""
    return paragon_service.get_paragons(
        page=page, 
        page_size=page_size, 
        store_name=store_name,
        user_id=user_id
    )

@router.get("/my-receipts", response_model=ParagonListResponse)
def get_my_receipts(
    page: int = Query(1, ge=1, description="Numer strony (zaczyna od 1)"),
    page_size: int = Query(10, ge=1, le=100, description="Liczba elementów na stronę (max 100)"),
    store_name: Optional[str] = Query(None, description="Filtr po nazwie sklepu"),
    current_user_id: int = Depends(get_current_user_id)
):
    """Pobiera paragony aktualnie zalogowanego użytkownika z tabeli receipts"""
    return paragon_service.get_paragons(
        page=page, 
        page_size=page_size, 
        store_name=store_name,
        user_id=current_user_id
    )

@router.get("/shared", response_model=List[ParagonResponse])
def get_shared_receipts(current_user_id: int = Depends(get_current_user_id)):
    """Pobiera paragony udostępnione użytkownikowi"""
    return paragon_service.get_shared_receipts(current_user_id)

@router.get("/{paragon_id}", response_model=ParagonResponse)
def get_paragon_by_id(paragon_id: int):
    """Pobiera szczegóły pojedynczego paragonu z tabeli receipts"""
    paragon = paragon_service.get_paragon_by_id(paragon_id)
    if not paragon:
        raise HTTPException(status_code=404, detail="Paragon nie został znaleziony")
    return paragon

@router.delete("/{paragon_id}")
def delete_paragon(
    paragon_id: int,
    current_user_id: int = Depends(get_current_user_id)
):
    """Usuwa paragon i wszystkie powiązane pozycje"""
    result = paragon_service.delete_paragon(paragon_id, current_user_id)
    if "error" in result:
        if "nie został znaleziony" in result["error"]:
            raise HTTPException(status_code=404, detail=result["error"])
        elif "Brak uprawnień" in result["error"]:
            raise HTTPException(status_code=403, detail=result["error"])
        else:
            raise HTTPException(status_code=500, detail=result["error"])
    return result

@router.get("/date-range/", response_model=List[ParagonResponse])
def get_paragons_by_date_range(
    start_date: str = Query(..., description="Data początkowa (YYYY-MM-DD)"),
    end_date: str = Query(..., description="Data końcowa (YYYY-MM-DD)"),
    user_id: Optional[int] = Query(None, description="ID użytkownika (opcjonalne)")
):
    """Pobiera paragony z określonego zakresu dat z tabeli receipts"""
    return paragon_service.get_paragons_by_date_range(start_date, end_date, user_id)

@router.post("/share")
def share_receipt(
    share_data: ReceiptShareInput,
    current_user_id: int = Depends(get_current_user_id)
):
    """Udostępnia paragon innemu użytkownikowi"""
    return paragon_service.share_receipt(
        share_data.receipt_id, 
        share_data.user_id, 
        current_user_id
    )

# Dodatkowe endpointy dla zarządzania produktami i sklepami

@router.post("/products", response_model=dict)
def create_product(product_data: ProductCreate):
    """Tworzy nowy produkt"""
    try:
        from services.db import supabase_client
        
        data = product_data.model_dump()
        response = supabase_client.table("product").insert(data).execute()
        
        if response.data:
            return {"message": "Produkt utworzony pomyślnie", "product": response.data[0]}
        else:
            raise HTTPException(status_code=400, detail="Nie udało się utworzyć produktu")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd podczas tworzenia produktu: {str(e)}")

@router.post("/categories", response_model=dict)
def create_category(category_data: CategoryCreate):
    """Tworzy nową kategorię"""
    try:
        from services.db import supabase_client
        
        data = category_data.model_dump()
        response = supabase_client.table("categories").insert(data).execute()
        
        if response.data:
            return {"message": "Kategoria utworzona pomyślnie", "category": response.data[0]}
        else:
            raise HTTPException(status_code=400, detail="Nie udało się utworzyć kategorii")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd podczas tworzenia kategorii: {str(e)}")

@router.post("/shops", response_model=dict)
def create_shop(shop_data: ShopCreate):
    """Tworzy nowy sklep"""
    try:
        from services.db import supabase_client
        
        data = shop_data.model_dump()
        response = supabase_client.table("shops").insert(data).execute()
        
        if response.data:
            return {"message": "Sklep utworzony pomyślnie", "shop": response.data[0]}
        else:
            raise HTTPException(status_code=400, detail="Nie udało się utworzyć sklepu")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd podczas tworzenia sklepu: {str(e)}")

@router.post("/shop-parcels", response_model=dict)
def create_shop_parcel(parcel_data: ShopParcelCreate):
    """Tworzy nową lokalizację sklepu"""
    try:
        from services.db import supabase_client
        
        data = parcel_data.model_dump()
        response = supabase_client.table("shops_parcels").insert(data).execute()
        
        if response.data:
            return {"message": "Lokalizacja sklepu utworzona pomyślnie", "parcel": response.data[0]}
        else:
            raise HTTPException(status_code=400, detail="Nie udało się utworzyć lokalizacji sklepu")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd podczas tworzenia lokalizacji sklepu: {str(e)}")

@router.get("/products/search")
def search_products(
    query: str = Query(..., description="Fraza do wyszukania"),
    limit: int = Query(10, ge=1, le=50, description="Maksymalna liczba wyników")
):
    """Wyszukuje produkty po nazwie"""
    try:
        from services.db import supabase_client
        
        response = supabase_client.table("product").select("*").ilike("name", f"%{query}%").limit(limit).execute()
        
        return {"products": response.data or []}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd podczas wyszukiwania produktów: {str(e)}")

@router.get("/shops/search")
def search_shops(
    query: str = Query(..., description="Fraza do wyszukania"),
    limit: int = Query(10, ge=1, le=50, description="Maksymalna liczba wyników")
):
    """Wyszukuje sklepy po nazwie"""
    try:
        from services.db import supabase_client
        
        response = supabase_client.table("shops").select("*").ilike("name", f"%{query}%").limit(limit).execute()
        
        return {"shops": response.data or []}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd podczas wyszukiwania sklepów: {str(e)}")

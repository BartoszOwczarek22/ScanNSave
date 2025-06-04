from services.db import supabase_client
from models.paragon import ParagonInput, ParagonResponse, ReceiptIndeksItem
from typing import List, Dict, Any
import json


def get_shop_name(item: Dict[str, Any]) -> str:
    try:
        return item["shops_parcels"]["shops"]["name"]
    except (TypeError, KeyError):
        return None
    
def get_user_id_by_token(firebase_uid: str) -> Dict[str, Any]:
    """
    Pobiera ID użytkownika na podstawie Firebase UID (token)
    """
    try:
        result = supabase_client.table("users")\
            .select("id")\
            .eq("token", firebase_uid)\
            .execute()
        
        if result.data and len(result.data) > 0:
            return {"success": True, "user_id": result.data[0]["id"]}
        else:
            return {"success": False, "error": "Użytkownik nie został znaleziony"}
    except Exception as e:
        return {"success": False, "error": str(e)}

def save_paragon_to_db(paragon_data: ParagonInput) -> Dict[str, Any]:
    """
    Zapisuje paragon do bazy danych wraz z indeksami
    """
    try:
        # Najpierw pobieramy ID użytkownika na podstawie Firebase UID
        user_result = get_user_id_by_token(paragon_data.creator_id)
        if not user_result["success"]:
            return {"success": False, "error": f"Błąd użytkownika: {user_result['error']}"}
        
        user_id = user_result["user_id"]
        
        # Zapisujemy główny paragon do tabeli receipts
        receipt_data = {
            "creator_id": user_id,  # Teraz używamy ID z tabeli users
            "date": paragon_data.date,
            "shop_parcel_id": paragon_data.shop_parcel_id,
            "sum_price": paragon_data.sum_price,
            "pic_path": paragon_data.pic_path
        }
        
        # Zapisujemy paragon
        receipt_result = supabase_client.table("receipts").insert(receipt_data).execute()
        
        if not receipt_result.data:
            return {"success": False, "error": "Nie udało się zapisać paragonu"}
        
        receipt_id = receipt_result.data[0]["id"]
        
        # Zapisujemy indeksy do tabeli receipt_indekses
        for indeks_item in paragon_data.receipt_indekses:
            indeks_data = {
                "indeks": indeks_item.indeks,
                "price": indeks_item.price,
                "product_id": None, # na sztywno koniecznie zmienić !!!!!!!!!!!!!!!!!!!
                "shop_id": None # na sztywno koniecznie zmienić !!!!!!!!!!!!!!!!!!!
            }
            
            # Zapisujemy indeks
            indeks_result = supabase_client.table("receipt_indekses").insert(indeks_data).execute()
            
            if indeks_result.data:
                indeks_id = indeks_result.data[0]["id"]
                
                # Łączymy paragon z indeksem w tabeli receipt_connect_indekses
                connect_data = {
                    "receipt_id": receipt_id,
                    "receipt_indeks_id": indeks_id,
                    "quantity": indeks_item.quantity 
                }
                
                supabase_client.table("receipt_connect_indekses").insert(connect_data).execute()
        
        return {"success": True, "data": receipt_result.data[0]}
            
    except Exception as e:
        return {"success": False, "error": str(e)}

def get_paragons_for_user(
    firebase_uid: str, 
    page: int = 1, 
    page_size: int = 10,
    store_name: str = None
) -> Dict[str, Any]:
    """
    Pobiera paragony dla konkretnego użytkownika z JOIN do shops_parcels i shops
    """
    try:
        # Najpierw pobieramy ID użytkownika na podstawie Firebase UID
        user_result = get_user_id_by_token(firebase_uid)
        if not user_result["success"]:
            return {"success": False, "error": f"Błąd użytkownika: {user_result['error']}"}
        
        user_id = user_result["user_id"]
        
        # Bazowe zapytanie z JOIN do shops_parcels i shops
        query = supabase_client.table("receipts")\
            .select("""
                *,
                shops_parcels!left(
                    id,
                    location,
                    shops_id,
                    shops!inner(
                        id,
                        name
                    )
                )
            """)\
            .eq("creator_id", user_id)  # Używamy user_id zamiast firebase_uid
        
        # Dodajemy filtr po nazwie sklepu jeśli podany
        if store_name:
            query = query.ilike("shops_parcels.shops.name", f"%{store_name}%")
        
        # Sortujemy po dacie (najnowsze pierwsze)
        query = query.order("date", desc=True)
        
        # Pobieramy całkowitą liczbę rekordów dla paginacji
        count_query = supabase_client.table("receipts")\
            .select("id", count="exact")\
            .eq("creator_id", user_id)
            
        if store_name:
            count_query = count_query.select("""
                id,
                shops_parcels!inner(
                    shops!inner(name)
                )
            """, count="exact").ilike("shops_parcels.shops.name", f"%{store_name}%")
            
        count_response = count_query.execute()
        total_count = count_response.count
        
        # Dodajemy paginację
        offset = (page - 1) * page_size
        query = query.range(offset, offset + page_size - 1)
        
        # Wykonujemy zapytanie
        result = query.execute()
        
        if result.data:
            paragons = []
            for item in result.data:
                # Pobieramy indeksy dla tego paragonu
                indekses_query = supabase_client.table("receipt_connect_indekses")\
                    .select("""
                        quantity,
                        receipt_indekses!inner(
                            id,
                            indeks,
                            price,
                            product_id,
                            shop_id
                        )
                    """)\
                    .eq("receipt_id", item["id"])
                
                indekses_result = indekses_query.execute()
                receipt_indekses = []
                
                if indekses_result.data:
                    for idx in indekses_result.data:
                        receipt_indekses.append({
                            "indeks": idx["receipt_indekses"]["indeks"],
                            "price": idx["receipt_indekses"]["price"],
                            "quantity": idx["quantity"],
                            "product_id": idx["receipt_indekses"]["product_id"],
                            "shop_id": idx["receipt_indekses"]["shop_id"]
                        })
                
                paragon = {
                    "create_date": item["create_date"],
                    "date": item["date"],
                    "sum_price": item["sum_price"],
                    "shop_name": get_shop_name(item),
                    "receipt_indekses": receipt_indekses
                }
                paragons.append(paragon)
            
            return {
                "success": True,
                "paragons": paragons,
                "total_count": total_count,
                "page": page,
                "page_size": page_size,
                "total_pages": (total_count + page_size - 1) // page_size
            }
        else:
            return {
                "success": True,
                "paragons": [],
                "total_count": 0,
                "page": page,
                "page_size": page_size,
                "total_pages": 0
            }
            
    except Exception as e:
        return {"success": False, "error": str(e)}

def get_paragon_by_id(paragon_id: int, firebase_uid: str) -> Dict[str, Any]:
    """
    Pobiera konkretny paragon po ID (tylko dla właściciela)
    """
    try:
        # Najpierw pobieramy ID użytkownika na podstawie Firebase UID
        user_result = get_user_id_by_token(firebase_uid)
        if not user_result["success"]:
            return {"success": False, "error": f"Błąd użytkownika: {user_result['error']}"}
        
        user_id = user_result["user_id"]
        
        # Pobieramy paragon z JOIN do shops
        result = supabase_client.table("receipts")\
            .select("""
                *,
                shops_parcels!inner(
                    id,
                    location,
                    shops_id,
                    shops!inner(
                        id,
                        name
                    )
                )
            """)\
            .eq("id", paragon_id)\
            .eq("creator_id", user_id)\
            .execute()
        
        if result.data:
            item = result.data[0]
            
            # Pobieramy indeksy dla tego paragonu
            indekses_query = supabase_client.table("receipt_connect_indekses")\
                .select("""
                    quantity,
                    receipt_indekses!inner(
                        id,
                        indeks,
                        price,
                        product_id,
                        shop_id
                    )
                """)\
                .eq("receipt_id", item["id"])
            
            indekses_result = indekses_query.execute()
            receipt_indekses = []
            
            if indekses_result.data:
                for idx in indekses_result.data:
                    receipt_indekses.append({
                        "indeks": idx["receipt_indekses"]["indeks"],
                        "price": idx["receipt_indekses"]["price"],
                        "quantity": idx["quantity"],
                        "product_id": idx["receipt_indekses"]["product_id"],
                        "shop_id": idx["receipt_indekses"]["shop_id"]
                    })
            
            paragon = {
                "create_date": item["create_date"],
                "date": item["date"],
                "sum_price": item["sum_price"],
                "shop_name": get_shop_name(item),
                "receipt_indekses": receipt_indekses
            }
            
            return {"success": True, "paragon": paragon}
        else:
            return {"success": False, "error": "Paragon nie został znaleziony"}
            
    except Exception as e:
        return {"success": False, "error": str(e)}

def get_paragons_in_date_range(firebase_uid: str, start_date: str, end_date: str) -> Dict[str, Any]:
    """
    Pobiera paragony użytkownika w określonym zakresie dat
    """
    try:
        # Najpierw pobieramy ID użytkownika na podstawie Firebase UID
        user_result = get_user_id_by_token(firebase_uid)
        if not user_result["success"]:
            return {"success": False, "error": f"Błąd użytkownika: {user_result['error']}"}
        
        user_id = user_result["user_id"]
        
        result = supabase_client.table("receipts")\
            .select("*")\
            .eq("creator_id", user_id)\
            .gte("date", start_date)\
            .lte("date", end_date)\
            .order("date", desc=True)\
            .execute()
        
        if result.data:
            return {"success": True, "paragons": result.data}
        else:
            return {"success": True, "paragons": []}
        
    except Exception as e:
        return {"success": False, "error": str(e)}

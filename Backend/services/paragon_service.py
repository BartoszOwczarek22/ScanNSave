from services.db import supabase_client
from models.paragon import ParagonInput
from typing import Dict, Any, Optional

from Levenshtein import distance

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

def get_existing_shop_parcel(shop_name: str, location: str = None) -> Dict[str, Any]:
    """
    Pobiera istniejący shop_parcel na podstawie nazwy sklepu
    """
    try:
        # Sprawdzamy czy sklep istnieje w tabeli shops (case-insensitive)
        shop_result = supabase_client.table("shops")\
            .select("id, name")\
            .ilike("name", shop_name)\
            .execute()
        
        if not shop_result.data:
            return {
                "success": False, 
                "error": f"Sklep o nazwie '{shop_name}' nie istnieje w bazie danych"
            }
        
        shop_id = shop_result.data[0]["id"]
        
        # Sprawdzamy czy istnieje shop_parcel dla tego sklepu
        parcel_query = supabase_client.table("shops_parcels")\
            .select("id")\
            .eq("shops_id", shop_id)
        
        if location:
            parcel_query = parcel_query.eq("location", location)
        
        parcel_result = parcel_query.execute()
        
        if not parcel_result.data:
            return {
                "success": False, 
                "error": f"Nie znaleziono lokalizacji dla sklepu '{shop_name}'"
            }
        
        parcel_id = parcel_result.data[0]["id"]
        
        return {"success": True, "shop_parcel_id": parcel_id, "shop_id": shop_id}
        
    except Exception as e:
        return {"success": False, "error": str(e)}


def get_or_create_product(product_name: str, re_indeks_table = None, shop_id = None,  category_name: str = None) -> Dict[str, Any]:
    """
    Znajduje lub tworzy produkt na podstawie nazwy
    """
    try:
        # Sprawdzamy czy produkt istnieje
        # product_result = supabase_client.table("product")\
        #     .select("id")\
        #     .eq("name", product_name)\
        #     .execute()
        found = False
        found_reciept_indeks = None # jesli znaleziono w tabeli receipt_indekses że taki skrót już istnieje to tutaj jest on przechowywany
        if re_indeks_table is not None and shop_id is not None:
            for item in re_indeks_table:
                if item["shop_id"] == shop_id:
                    if item['product_id'] is not None:
                        if distance(item["indeks"], product_name) <= 2:
                            found = True
                            found_reciept_indeks = item
                            break
        
        if not found:
            # Jeśli podano kategorię, próbujemy ją znaleźć lub utworzyć
            category_id = None
            if category_name:
                category_result = supabase_client.table("categories")\
                    .select("id")\
                    .eq("name", category_name)\
                    .execute()
                
                if not category_result.data:
                    # Tworzymy nową kategorię
                    new_category = supabase_client.table("categories")\
                        .insert({"name": category_name})\
                        .execute()
                    
                    if new_category.data:
                        category_id = new_category.data[0]["id"]
                else:
                    category_id = category_result.data[0]["id"]
            
            # Tworzymy nowy produkt
            product_data = {
                "name": product_name,
                "categorie_id": category_id
            }
            new_product = supabase_client.table("product")\
                .insert(product_data)\
                .execute()
            
            if not new_product.data:
                return {"success": False, "error": f"Nie udało się utworzyć produktu: {product_name}", "found_indeks": False}
            
            product_id = new_product.data[0]["id"]
        else:
            product_id = found_reciept_indeks["product_id"]
        
        return {"success": True, "product_id": product_id, "found_indeks": found}
        
    except Exception as e:
        return {"success": False, "error": str(e), "found_indeks": False}

def build_paragon(item: dict) -> dict:
    """
    Buduje obiekt paragonu z dodatkowymi informacjami o indeksach i sklepie.
    """
    indekses_result = supabase_client.table("receipt_connect_indekses")\
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
        .eq("receipt_id", item["id"])\
        .execute()
    
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

    return {
        "id": item["id"],
        "create_date": item["create_date"],
        "date": item["date"],
        "sum_price": item["sum_price"],
        "shop_name": get_shop_name(item),
        "location": item["shops_parcels"]["location"] if item["shops_parcels"] else None,
        "receipt_indekses": receipt_indekses
    }


def get_paragons_for_user(
    firebase_uid: str,
    page: int = 1,
    page_size: int = 10,
    store_name: Optional[str] = None
) -> Dict[str, Any]:
    """
    Pobiera paragony dla konkretnego użytkownika z paginacją i opcjonalnym filtrowaniem po nazwie sklepu.
    """
    try:
        user_result = get_user_id_by_token(firebase_uid)
        if not user_result["success"]:
            return {"success": False, "error": f"Błąd użytkownika: {user_result['error']}"}
        
        user_id = user_result["user_id"]
        offset = (page - 1) * page_size

        # Główne zapytanie
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
            .eq("creator_id", user_id)\
            .order("date", desc=True)\
            .range(offset, offset + page_size - 1)

        if store_name:
            query = query.ilike("shops_parcels.shops.name", f"%{store_name}%")

        result = query.execute()

        # Zapytanie do licznika
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

        paragons = [build_paragon(item) for item in result.data] if result.data else []

        return {
            "success": True,
            "paragons": paragons,
            "total_count": total_count,
            "page": page,
            "page_size": page_size,
            "total_pages": (total_count + page_size - 1) // page_size
        }

    except Exception as e:
        return {"success": False, "error": str(e)}


def get_paragons_in_date_range(firebase_uid: str, start_date: str, end_date: str) -> Dict[str, Any]:
    """
    Pobiera paragony użytkownika w określonym zakresie dat z nazwą sklepu i indeksem.
    """
    try:
        user_result = get_user_id_by_token(firebase_uid)
        if not user_result["success"]:
            return {"success": False, "error": f"Błąd użytkownika: {user_result['error']}"}
        
        user_id = user_result["user_id"]

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
            .eq("creator_id", user_id)\
            .gte("date", start_date)\
            .lte("date", end_date)\
            .order("date", desc=True)

        result = query.execute()
        paragons = [build_paragon(item) for item in result.data] if result.data else []

        return {"success": True, "paragons": paragons}

    except Exception as e:
        return {"success": False, "error": str(e)}

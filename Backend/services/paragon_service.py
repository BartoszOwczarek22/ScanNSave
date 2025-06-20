from services.db import supabase_client
from models.paragon import ParagonInput
from typing import Dict, Any, Optional

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


def get_or_create_product(product_name: str, category_name: str = None) -> Dict[str, Any]:
    """
    Znajduje lub tworzy produkt na podstawie nazwy
    """
    try:
        # Sprawdzamy czy produkt istnieje
        product_result = supabase_client.table("product")\
            .select("id")\
            .eq("name", product_name)\
            .execute()
        
        if not product_result.data:
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
                return {"success": False, "error": f"Nie udało się utworzyć produktu: {product_name}"}
            
            product_id = new_product.data[0]["id"]
        else:
            product_id = product_result.data[0]["id"]
        
        return {"success": True, "product_id": product_id}
        
    except Exception as e:
        return {"success": False, "error": str(e)}

def save_paragon_to_db(paragon_data: ParagonInput) -> Dict[str, Any]:
    """
    Zapisuje paragon do bazy danych wraz z indeksami
    """
    try:
        # Pobieramy ID użytkownika na podstawie Firebase token
        user_result = get_user_id_by_token(paragon_data.token)
        if not user_result["success"]:
            return {"success": False, "error": f"Błąd użytkownika: {user_result['error']}"}
        
        user_id = user_result["user_id"]
        
        # ZMIANA: Używamy get_existing_shop_parcel zamiast get_or_create_shop_parcel
        shop_result = get_existing_shop_parcel(paragon_data.shop_name, paragon_data.location)
        if not shop_result["success"]:
            return {"success": False, "error": f"Błąd sklepu: {shop_result['error']}"}
        
        shop_parcel_id = shop_result["shop_parcel_id"]
        shop_id = shop_result["shop_id"]  # Prawdziwe ID sklepu z tabeli shops
        
        # Zapisujemy główny paragon do tabeli receipts
        receipt_data = {
            "creator_id": user_id,
            "date": paragon_data.date,
            "shop_id": shop_id,
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
            # Pobieramy lub tworzymy produkt na podstawie nazwy (indeks)
            product_result = get_or_create_product(indeks_item.indeks)
            if not product_result["success"]:
                print(f"Ostrzeżenie: {product_result['error']}")
                product_id = None
            else:
                product_id = product_result["product_id"]
            
            indeks_data = {
                "indeks": indeks_item.indeks,
                "price": indeks_item.price,
                "product_id": product_id,
                "shop_id": shop_id  
            }
            
            # Zapisujemy indeks
            indeks_result = supabase_client.table("receipt_indekses").insert(indeks_data).execute()
            
            if indeks_result.data:
                indeks_id = indeks_result.data[0]["id"]
                
                # Łączymy paragon z indeksem w tabeli receipt_connect_indekses
                connect_data = {
                    "receipt_id": receipt_id,
                    "receipt_indeks_id": indeks_id,
                    "quantity": 1  
                }
                
                supabase_client.table("receipt_connect_indekses").insert(connect_data).execute()
        
        return {"success": True, "data": receipt_result.data[0]}
            
    except Exception as e:
        return {"success": False, "error": str(e)}

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

from services.db import supabase_client
from models.receipt_model import Receipt, ReceiptItem
from services.paragon_service import (
    get_user_id_by_token, 
    get_existing_shop_parcel, 
    get_or_create_product
)
from typing import Dict, Any

def save_receipt_to_db(receipt: Receipt) -> Dict[str, Any]:
    """
    Konwertuje Receipt na format bazy danych i zapisuje jako paragon
    """
    try:
        # Pobierz ID użytkownika na podstawie userId (Firebase UID)
        user_result = get_user_id_by_token(receipt.userId)
        if not user_result["success"]:
            return {"success": False, "error": f"Błąd użytkownika: {user_result['error']}"}
        
        user_id = user_result["user_id"]
        
        shop_result = get_existing_shop_parcel(receipt.storeName, location=None)
        if not shop_result["success"]:
            return {"success": False, "error": f"Błąd sklepu: {shop_result['error']}"}
        
        shop_parcel_id = shop_result["shop_parcel_id"]
        shop_id = shop_result["shop_id"]  
        
        # Zapisz główny paragon do tabeli receipts
        receipt_data = {
            "creator_id": user_id,
            "date": receipt.date,
            "shop_id": shop_parcel_id,
            "sum_price": receipt.total,
            "pic_path": None  # Możesz rozszerzyć później
        }
        
        # Zapisz paragon
        receipt_result = supabase_client.table("receipts").insert(receipt_data).execute()
        
        if not receipt_result.data:
            return {"success": False, "error": "Nie udało się zapisać paragonu"}
        
        receipt_id = receipt_result.data[0]["id"]
        
        # Zapisz items jako receipt_indekses
        for item in receipt.items:
            if item.quantity == 0:
                continue 

            # Pobierz lub utwórz produkt na podstawie nazwy
            product_result = get_or_create_product(item.name)
            if not product_result["success"]:
                print(f"Ostrzeżenie: {product_result['error']}")
                product_id = None
            else:
                product_id = product_result["product_id"]
            
            # Zapisz indeks - używamy całkowitej ceny za item (price * quantity)
            total_item_price = item.price * item.quantity
            
            indeks_data = {
                "indeks": item.name,
                "price": total_item_price,
                "product_id": product_id,
                "shop_id": shop_id  
            }
            
            # Zapisz indeks
            indeks_result = supabase_client.table("receipt_indekses").insert(indeks_data).execute()
            
            if indeks_result.data:
                indeks_id = indeks_result.data[0]["id"]
                
                # Połącz paragon z indeksem
                connect_data = {
                    "receipt_id": receipt_id,
                    "receipt_indeks_id": indeks_id,
                    "quantity": item.quantity
                }
                
                supabase_client.table("receipt_connect_indekses").insert(connect_data).execute()
        
        return {"success": True, "data": receipt_result.data[0]}
            
    except Exception as e:
        return {"success": False, "error": str(e)}

def delete_receipt_from_db(receipt_id: int) -> dict:
    """
    Usuwa paragon z tabeli receipts oraz powiązany wiersz z receipt_shared.
    """
    try:
        # Usuń powiązany wiersz z receipt_shared
        supabase_client.table("receipt_shared").delete().eq("receipt_id", receipt_id).execute()
        # Usuń powiązane indeksy z receipt_connect_indekses
        supabase_client.table("receipt_connect_indekses").delete().eq("receipt_id", receipt_id).execute()
        
        # Usuń paragon z receipts
        delete_result = supabase_client.table("receipts").delete().eq("id", receipt_id).execute()
        
        if delete_result.data:
            return {"success": True, "data": delete_result.data[0]}
        else:
            return {"success": False, "error": "Nie znaleziono paragonu do usunięcia"}
    except Exception as e:
        return {"success": False, "error": str(e)}
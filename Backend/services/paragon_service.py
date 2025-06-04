from services.db import supabase_client
from models.paragon import (
    ParagonInput, ParagonResponse, ParagonListResponse, 
    ReceiptShareInput, ProductCreate, CategoryCreate, 
    ShopCreate, ShopParcelCreate, ParagonItem
)
from datetime import datetime
import json
import aiofiles
from typing import Optional, List
from uuid import UUID  # Add this import


async def save_paragon_test(paragon_data: ParagonInput):
    """Funkcja testowa - zapisuje do pliku"""
    paragon_dict = paragon_data.model_dump()
    paragon_json = json.dumps(paragon_dict, indent=2, ensure_ascii=False)

    async with aiofiles.open("paragon.txt", "w", encoding="utf-8") as file:
        await file.write(paragon_json)

    return {"message": "Paragon zapisany do pliku"}


def find_shop(shop_name: str) -> int:
    """Znajdź lub utwórz sklep"""
    try:
        # Sprawdź czy sklep już istnieje
        response = supabase_client.table("shops").select("id").eq("name", shop_name).execute()
        
        if response.data:
            return response.data[0]['id']
        
    except Exception as e:
        print(f"Błąd podczas wyszukiwania sklepu: {str(e)}")
        return None


def find_or_create_product(product_name: str, category_id: Optional[int] = None) -> int:
    """Znajdź lub utwórz produkt"""
    try:
        # Sprawdź czy produkt już istnieje
        response = supabase_client.table("product").select("id").eq("name", product_name).execute()
        
        if response.data:
            return response.data[0]['id']
        
        # Utwórz nowy produkt
        product_data = {"name": product_name}
        if category_id:
            product_data["categorie_id"] = category_id
            
        response = supabase_client.table("product").insert(product_data).execute()
        return response.data[0]['id']
    
    except Exception as e:
        print(f"Błąd podczas tworzenia/wyszukiwania produktu: {str(e)}")
        return None


def save_paragon(paragon: ParagonInput):
    """Zapisuje paragon do bazy danych używając pełnej struktury"""
    try:
        # Handle user_id - ensure it's a proper UUID string
        if isinstance(paragon.user_id, str):
            try:
                UUID(paragon.user_id)
                creator_id_str = paragon.user_id
            except ValueError:
                return {"error": "Nieprawidłowy format user_id - musi być UUID"}
        else:
            creator_id_str = str(paragon.user_id)
        
        # Handle shop_parcel_id if provided
        shop_parcel_id_str = None
        if paragon.shop_parcel_id:
            if isinstance(paragon.shop_parcel_id, str):
                try:
                    UUID(paragon.shop_parcel_id)
                    shop_parcel_id_str = paragon.shop_parcel_id
                except ValueError:
                    return {"error": "Nieprawidłowy format shop_parcel_id - musi być UUID"}
            else:
                shop_parcel_id_str = str(paragon.shop_parcel_id)
        
        # 1. Znajdź lub utwórz sklep
        shop_id = find_shop(paragon.storeName)
        if not shop_id:
            return {"error": "Nie udało się znaleźć/utworzyć sklepu"}
        
        # 2. Zapisz główny rekord paragonu
        receipt_data = {
            "creator_id": creator_id_str,
            "create_date": datetime.utcnow().isoformat(),
            "date": paragon.date,
            "pic_path": paragon.pic_path,
            "sum_price": paragon.total
        }
        if shop_parcel_id_str:
            receipt_data["shop_parcel_id"] = shop_parcel_id_str
        
        receipt_response = supabase_client.table("receipts").insert(receipt_data).execute()
        if not receipt_response.data:
            return {"error": "Nie udało się zapisać paragonu"}
        
        receipt_id = receipt_response.data[0]['id']
        
        # 3. Przygotuj dane do dwóch tabel
        receipt_indekses_data = []
        receipt_connect_indekses_data = []
        
        for item in paragon.items:
            product_id = find_or_create_product(item.name)
            
            receipt_indekses_data.append({
                "id": receipt_id,
                "indeks": item.name,
                "price": item.price,
                "product_id": product_id,
                "shop_id": shop_id,
            })
            
            receipt_connect_indekses_data.append({
                "receipt_id": receipt_id,
                "quantity": item.quantity
            })
        
        # 4. Wstaw do receipt_indekses
        if receipt_indekses_data:
            items_response = supabase_client.table("receipt_indekses").insert(receipt_indekses_data).execute()
            if not items_response.data:
                supabase_client.table("receipts").delete().eq("id", receipt_id).execute()
                return {"error": "Nie udało się zapisać pozycji paragonu (receipt_indekses)"}
        
        # 5. Wstaw do receipt_connect_indekses
        if receipt_connect_indekses_data:
            connect_response = supabase_client.table("receipt_connect_indekses").insert(receipt_connect_indekses_data).execute()
            if not connect_response.data:
                # Rollback - usuń też wpisy z receipt_indekses i receipts
                supabase_client.table("receipt_indekses").delete().eq("receipt_id", receipt_id).execute()
                supabase_client.table("receipts").delete().eq("id", receipt_id).execute()
                return {"error": "Nie udało się zapisać ilości produktów (receipt_connect_indekses)"}
        
        return {"message": "Paragon zapisany pomyślnie", "receipt_id": receipt_id}
        
    except Exception as e:
        return {"error": "Wyjątek podczas zapisu paragonu", "details": str(e)}

def get_paragons(page: int = 1, page_size: int = 10, store_name: Optional[str] = None, user_id: Optional[int] = None) -> ParagonListResponse:
    """Pobiera paragony z pełną strukturą bazy danych"""
    try:
        offset = (page - 1) * page_size
        
        # Główne zapytanie z JOIN-ami
        query = """
        SELECT 
            r.*,
            sp.location,
            s.name as shop_name
        FROM receipts r
        LEFT JOIN shops_parcels sp ON r.shop_parcel_id = sp.id
        LEFT JOIN shops s ON sp.shops_id = s.id
        """
        
        conditions = []
        params = []
        
        if user_id:
            conditions.append("r.creator_id = %s")
            params.append(user_id)
        
        if store_name:
            conditions.append("s.name ILIKE %s")
            params.append(f"%{store_name}%")
        
        if conditions:
            query += " WHERE " + " AND ".join(conditions)
        
        query += f" ORDER BY r.create_date DESC LIMIT {page_size} OFFSET {offset}"
        
        # Wykonaj zapytanie (to wymaga użycia raw SQL lub odpowiedniego ORM)
        # Dla uproszczenia używam podstawowego zapytania Supabase
        base_query = supabase_client.table("receipts").select(
            "*, shops_parcels(location, shops(name))"
        )
        
        if user_id:
            base_query = base_query.eq("creator_id", user_id)
        
        response = base_query.order("create_date", desc=True).range(offset, offset + page_size - 1).execute()
        
        if not response.data:
            return ParagonListResponse(
                paragons=[],
                total_count=0,
                page=page,
                page_size=page_size
            )
        
        paragons = []
        for receipt_row in response.data:
            # Pobierz pozycje dla każdego paragonu
            items_response = supabase_client.table("receipt_indekses").select(
                "*, product(name)"
            ).eq("receipt_id", receipt_row['id']).execute()
            
            items = []
            if items_response.data:
                for item_row in items_response.data:
                    items.append(ParagonItem(
                        name=item_row['indeks'],
                        quantity=item_row['quantity'],
                        price=item_row['price'],
                        product_id=item_row['product_id']
                    ))
            
            # Przygotuj informacje o sklepie
            shop_info = {}
            if receipt_row.get('shops_parcels'):
                shop_info['location'] = receipt_row['shops_parcels'].get('location')
                if receipt_row['shops_parcels'].get('shops'):
                    shop_info['shop_name'] = receipt_row['shops_parcels']['shops'].get('name')
            
            paragon = ParagonResponse.from_db_row(receipt_row, items, shop_info)
            paragons.append(paragon)
        
        # Policz całkowitą liczbę rekordów
        count_query = supabase_client.table("receipts").select("id", count="exact")
        if user_id:
            count_query = count_query.eq("creator_id", user_id)
        
        count_response = count_query.execute()
        total_count = count_response.count if count_response.count else len(paragons)
        
        return ParagonListResponse(
            paragons=paragons,
            total_count=total_count,
            page=page,
            page_size=page_size
        )
        
    except Exception as e:
        print(f"Błąd podczas pobierania paragonów: {str(e)}")
        return ParagonListResponse(
            paragons=[],
            total_count=0,
            page=page,
            page_size=page_size
        )


def get_paragon_by_id(paragon_id: int) -> Optional[ParagonResponse]:
    """Pobiera pojedynczy paragon z pełnymi danymi"""
    try:
        # Pobierz główny rekord paragonu
        response = supabase_client.table("receipts").select(
            "*, shops_parcels(location, shops(name))"
        ).eq("id", paragon_id).single().execute()
        
        if not response.data:
            return None
        
        receipt_row = response.data
        
        # Pobierz pozycje paragonu
        items_response = supabase_client.table("receipt_indekses").select(
            "*, product(name)"
        ).eq("receipt_id", paragon_id).execute()
        
        items = []
        if items_response.data:
            for item_row in items_response.data:
                items.append(ParagonItem(
                    name=item_row['indeks'],
                    quantity=item_row['quantity'],
                    price=item_row['price'],
                    product_id=item_row['product_id']
                ))
        
        # Przygotuj informacje o sklepie
        shop_info = {}
        if receipt_row.get('shops_parcels'):
            shop_info['location'] = receipt_row['shops_parcels'].get('location')
            if receipt_row['shops_parcels'].get('shops'):
                shop_info['shop_name'] = receipt_row['shops_parcels']['shops'].get('name')
        
        return ParagonResponse.from_db_row(receipt_row, items, shop_info)
        
    except Exception as e:
        print(f"Błąd podczas pobierania paragonu {paragon_id}: {str(e)}")
        return None


def delete_paragon(paragon_id: int, user_id: int):
    """Usuwa paragon i wszystkie powiązane pozycje"""
    try:
        # Sprawdź czy paragon istnieje i należy do użytkownika
        response = supabase_client.table("receipts").select("creator_id").eq("id", paragon_id).single().execute()
        
        if not response.data:
            return {"error": "Paragon nie został znaleziony"}
        
        # Compare as strings to avoid UUID conversion issues
        creator_id_str = str(response.data['creator_id'])
        user_id_str = str(user_id)
        
        if creator_id_str != user_id_str:
            return {"error": "Brak uprawnień do usunięcia tego paragonu"}
        
        # Usuń pozycje paragonu
        supabase_client.table("receipt_indekses").delete().eq("receipt_id", paragon_id).execute()
        
        # Usuń udostępnienia paragonu
        supabase_client.table("receipt_shared").delete().eq("receipt_id", paragon_id).execute()
        
        # Usuń główny rekord paragonu
        delete_response = supabase_client.table("receipts").delete().eq("id", paragon_id).execute()
        
        if delete_response.data:
            return {"message": "Paragon został usunięty pomyślnie"}
        else:
            return {"error": "Nie udało się usunąć paragonu"}
            
    except Exception as e:
        return {"error": "Błąd podczas usuwania paragonu", "details": str(e)}


def get_paragons_by_date_range(start_date: str, end_date: str, user_id: Optional[int] = None) -> List[ParagonResponse]:
    """Pobiera paragony z zakresu dat"""
    try:
        query = supabase_client.table("receipts").select(
            "*, shops_parcels(location, shops(name))"
        ).gte("date", start_date).lte("date", end_date)
        
        if user_id:
            query = query.eq("creator_id", user_id)
        
        response = query.order("date", desc=True).execute()
        
        paragons = []
        if response.data:
            for receipt_row in response.data:
                # Pobierz pozycje dla każdego paragonu
                items_response = supabase_client.table("receipt_indekses").select(
                    "*, product(name)"
                ).eq("receipt_id", receipt_row['id']).execute()
                
                items = []
                if items_response.data:
                    for item_row in items_response.data:
                        items.append(ParagonItem(
                            name=item_row['indeks'],
                            quantity=item_row['quantity'],
                            price=item_row['price'],
                            product_id=item_row['product_id']
                        ))
                
                # Przygotuj informacje o sklepie
                shop_info = {}
                if receipt_row.get('shops_parcels'):
                    shop_info['location'] = receipt_row['shops_parcels'].get('location')
                    if receipt_row['shops_parcels'].get('shops'):
                        shop_info['shop_name'] = receipt_row['shops_parcels']['shops'].get('name')
                
                paragon = ParagonResponse.from_db_row(receipt_row, items, shop_info)
                paragons.append(paragon)
        
        return paragons
        
    except Exception as e:
        print(f"Błąd podczas pobierania paragonów z zakresu dat: {str(e)}")
        return []



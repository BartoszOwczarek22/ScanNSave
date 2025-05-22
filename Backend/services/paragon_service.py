from services.db import supabase_client
from models.paragon import ParagonInput, ParagonResponse, ParagonListResponse
from datetime import datetime
import json
import aiofiles
from typing import Optional, List


async def save_paragon_test(paragon_data: ParagonInput):
    """Funkcja testowa - zapisuje do pliku"""
    paragon_dict = paragon_data.model_dump()
    paragon_json = json.dumps(paragon_dict, indent=2, ensure_ascii=False)

    async with aiofiles.open("paragon.txt", "w", encoding="utf-8") as file:
        await file.write(paragon_json)

    return {"message": "Paragon zapisany do pliku"}


def save_paragon(paragon: ParagonInput):
    """Zapisuje paragon do bazy danych"""
    # Konwertujemy items na JSON string
    items_json = json.dumps([item.model_dump() for item in paragon.items], ensure_ascii=False)
    
    data = {
        "date": paragon.date if paragon.date else None,
        "storeName": paragon.storeName,
        "items": items_json,
        "total": paragon.total,
        "created_at": datetime.utcnow().isoformat()
    }
    
    try:
        response = supabase_client.table("paragony_test").insert(data).execute()
    except Exception as e:
        return {"error": "Wyjątek podczas zapisu paragonu", "details": str(e)}

    if not response.data or len(response.data) == 0:
        return {"error": "Nie udało się zapisać paragonu", "details": response.data}

    return {"message": "Paragon zapisany pomyślnie", "data": response.data}


def get_paragons(page: int = 1, page_size: int = 10, store_name: Optional[str] = None) -> ParagonListResponse:

    try:
        offset = (page - 1) * page_size
        
        query = supabase_client.table("paragony_test").select("*")
        
        if store_name:
            query = query.ilike("storeName", f"%{store_name}%")
        
        query = query.order("created_at", desc=True).range(offset, offset + page_size - 1)

        response = query.execute()
        
        if not response.data:
            return ParagonListResponse(
                paragons=[],
                total_count=0,
                page=page,
                page_size=page_size
            )
        
        paragons = []
        for row in response.data:
            try:
                paragon = ParagonResponse.from_db_row(row)
                paragons.append(paragon)
            except Exception as e:
                print(f"Błąd podczas konwersji wiersza {row.get('id', 'unknown')}: {str(e)}")
                continue
        
        count_query = supabase_client.table("paragony_test").select("id", count="exact")
        if store_name:
            count_query = count_query.ilike("storeName", f"%{store_name}%")
        
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

    try:
        response = supabase_client.table("paragony_test").select("*").eq("id", paragon_id).single().execute()
        
        if response.data:
            return ParagonResponse.from_db_row(response.data)
        else:
            return None
            
    except Exception as e:
        print(f"Błąd podczas pobierania paragonu {paragon_id}: {str(e)}")
        return None


def get_paragons_by_date_range(start_date: str, end_date: str) -> List[ParagonResponse]:

    try:
        response = (supabase_client.table("paragony_test")
                   .select("*")
                   .gte("date", start_date)
                   .lte("date", end_date)
                   .order("date", desc=True)
                   .execute())
        
        paragons = []
        if response.data:
            for row in response.data:
                try:
                    paragon = ParagonResponse.from_db_row(row)
                    paragons.append(paragon)
                except Exception as e:
                    print(f"Błąd podczas konwersji wiersza {row.get('id', 'unknown')}: {str(e)}")
                    continue
        
        return paragons
        
    except Exception as e:
        print(f"Błąd podczas pobierania paragonów z zakresu dat: {str(e)}")
        return []
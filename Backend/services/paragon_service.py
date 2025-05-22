from services.db import supabase_client
from models.paragon import ParagonInput
from datetime import datetime
import json
import aiofiles
from models.paragon import ParagonInput

async def save_paragon_test(paragon_data: ParagonInput):
    
    paragon_dict = paragon_data.model_dump()
    paragon_json = json.dumps(paragon_dict, indent=2, ensure_ascii=False)

    async with aiofiles.open("paragon.txt", "w", encoding="utf-8") as file:
        await file.write(paragon_json)

    return {"message": "Paragon zapisany do pliku"}

def save_paragon(paragon: ParagonInput):
    data = {
        "tekst": paragon.tekst,
        "created_at": datetime.utcnow().isoformat()
    }
    
    try:
        response = supabase_client.table("paragony_test").insert(data).execute()
    except Exception as e:
        return {"error": "Wyjątek podczas zapisu paragonu", "details": str(e)}

    if not response.data or len(response.data) == 0:
        return {"error": "Nie udało się zapisać paragonu", "details": response.data}

    return {"message": "Paragon zapisany pomyślnie", "data": response.data}

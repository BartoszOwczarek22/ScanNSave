from services.db import supabase_client
from models.paragon import ParagonInput
from datetime import datetime

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

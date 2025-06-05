from fastapi import APIRouter
from services.db import supabase_client

router = APIRouter(prefix="/shops", tags=["shops"])

@router.get("/list")
def get_shops():
    response = supabase_client.from_("shops").select("name").execute()
    if response.error:
        return []
    return response.data
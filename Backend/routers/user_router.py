import datetime
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from services.db import supabase_client

class UserInput(BaseModel):
    token: str
    name: str

router = APIRouter(prefix="/user", tags=["user"])

@router.post("/add")
def add_user(user: UserInput):
    if not user.token.strip():  # usuwa spacje i sprawdza pusty ciąg
        raise HTTPException(status_code=400, detail="Token nie może być pusty")
    """
    Dodaje nowego użytkownika do bazy danych.
    """
    existing = supabase_client.table("users").select("id").eq("token", user.token).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail="User with this UID already exists")
    
    # Dodaj użytkownika
    response = supabase_client.table("users").insert({
        "token": user.token,
        "name": user.name,
    }).execute()

    return {"message": "User created", "user": response.data[0]}
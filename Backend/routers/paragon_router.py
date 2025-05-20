from fastapi import APIRouter
from models.paragon import ParagonInput
from services import paragon_service

router = APIRouter(prefix="/paragon", tags=["paragon"])

@router.post("/")
def save_paragon(input_data: ParagonInput):
    return paragon_service.save_paragon(input_data)

@router.get("/test-save")
def test_save_paragon():
    przykładowy_paragon = ParagonInput(tekst="pomidory chleb piwo")
    return paragon_service.save_paragon(przykładowy_paragon)
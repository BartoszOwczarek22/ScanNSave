from fastapi import APIRouter
from models.paragon import ParagonInput
from services import paragon_service

router = APIRouter(prefix="/paragon", tags=["paragon"])

@router.post("/save")
async def save_paragon(input_data: ParagonInput):
    return await paragon_service.save_paragon_test(input_data)


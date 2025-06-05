from fastapi import APIRouter, HTTPException
from models.receipt_model import Receipt, ReceiptResponse
from services.receipt_service import save_receipt_to_db

router = APIRouter(prefix="/receipt", tags=["receipt"])

@router.post("/save", response_model=ReceiptResponse)
def save_receipt(receipt: Receipt):
    try:
        result = save_receipt_to_db(receipt)
        
        if result["success"]:
            return ReceiptResponse(
                message="Paragon został zapisany pomyślnie", 
                data=result["data"]
            )
        else:
            raise HTTPException(status_code=400, detail=result["error"])
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd serwera: {str(e)}")
from fastapi import APIRouter, HTTPException
from models.receipt_model import Receipt, ReceiptResponse
from services.receipt_service import save_receipt_to_db, delete_receipt_from_db
from uuid import UUID

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

    except HTTPException:
        raise  
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd serwera: {str(e)}")


@router.delete("/delete/{receipt_id}", response_model=ReceiptResponse)
def delete_receipt(receipt_id: UUID):
    try:
        result = delete_receipt_from_db(receipt_id)

        if result["success"]:
            return ReceiptResponse(
                message="Paragon został usunięty pomyślnie",
                data=result.get("data")
            )
        else:
            raise HTTPException(status_code=404, detail=result["error"])

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Błąd serwera: {str(e)}")
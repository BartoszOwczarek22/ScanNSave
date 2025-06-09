from fastapi import APIRouter
from services.stats_service import *

router = APIRouter(prefix="/api/stats", tags=["Stats"])

@router.get("/categories")
def stats_by_category(user_id: str, start_date: str, end_date: str):
    return get_expenses_by_category(user_id, start_date, end_date)

@router.get("/shops")
def stats_by_shop(user_id: str, start_date: str, end_date: str):
    return get_expenses_by_shop(user_id, start_date, end_date)

@router.get("/months")
def stats_by_month(user_id: str, start_date: str, end_date: str):
    return get_expenses_by_month(user_id, start_date, end_date)

@router.get("/summary")
def total_expense_summary(user_id: str, start_date: str, end_date: str):
    return get_total_expense_summary(user_id, start_date, end_date)
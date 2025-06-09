from services.db import supabase_client

def get_expenses_by_category(user_id: str, start_date: str, end_date: str): 
    response = supabase_client.rpc("expenses_by_category", {
        "user_id": user_id,
        "start_date": start_date,
        "end_date": end_date
    }).execute()
    return response.data

def get_expenses_by_shop(user_id: str, start_date: str, end_date: str):
    response = supabase_client.rpc("expenses_by_shop", {
        "user_id": user_id,
        "start_date": start_date,
        "end_date": end_date
    }).execute()
    return response.data

def get_expenses_by_month(user_id: str, start_date: str, end_date: str):
    response = supabase_client.rpc("expenses_by_month", {
        "user_id": user_id,
        "start_date": start_date,
        "end_date": end_date
    }).execute()
    return response.data

def get_total_expense_summary(user_id: str, start_date: str, end_date: str):
    response = supabase_client.rpc("total_expense_summary", {
        "user_id": user_id,
        "start_date": start_date,
        "end_date": end_date
    }).execute()
    return response.data
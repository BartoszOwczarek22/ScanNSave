import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from unittest.mock import patch, Mock
import sys
import json

# Dodaj ścieżkę do głównego katalogu projektu
sys.path.append('..')

from routers.paragon_router import router as paragon_router
from routers.receipt_router import router as receipt_router
from routers.user_router import router as user_router

# Utwórz aplikację testową
app = FastAPI()
app.include_router(paragon_router)
app.include_router(receipt_router)
app.include_router(user_router)

client = TestClient(app)


class TestParagonRouter:
    """Testy dla paragon_router.py"""
    
    @patch('routers.paragon_router.get_paragons_for_user')
    def test_get_user_paragons_success(self, mock_get_paragons):
        # Arrange
        mock_get_paragons.return_value = {
            "success": True,
            "paragons": [
                {
                    "id": 1,
                    "create_date": "2024-01-01",
                    "date": "2024-01-01",
                    "sum_price": 25.50,
                    "shop_name": "Biedronka",
                    "location": "ul. Główna 1",
                    "receipt_indekses": []
                }
            ],
            "total_count": 1,
            "page": 1,
            "page_size": 10,
            "total_pages": 1
        }
        
        # Act
        response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=10")
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["paragons"]) == 1
        assert data["total_count"] == 1
        assert data["paragons"][0]["shop_name"] == "Biedronka"

    @patch('routers.paragon_router.get_paragons_for_user')
    def test_get_user_paragons_with_store_filter(self, mock_get_paragons):
        # Arrange
        mock_get_paragons.return_value = {
            "success": True,
            "paragons": [],
            "total_count": 0,
            "page": 1,
            "page_size": 10,
            "total_pages": 0
        }
        
        # Act
        response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=10&store_name=Biedronka")
        
        # Assert
        assert response.status_code == 200
        mock_get_paragons.assert_called_with("test_uid", 1, 10, "Biedronka")

    @patch('routers.paragon_router.get_paragons_for_user')
    def test_get_user_paragons_error(self, mock_get_paragons):
        # Arrange
        mock_get_paragons.return_value = {
            "success": False,
            "error": "Użytkownik nie znaleziony"
        }
        
        # Act
        response = client.get("/paragon/list?user_id=invalid_uid&page=1&page_size=10")
        
        # Assert
        assert response.status_code == 400
        assert "Użytkownik nie znaleziony" in response.json()["detail"]

    def test_get_user_paragons_missing_user_id(self):
        # Act
        response = client.get("/paragon/list?page=1&page_size=10")
        
        # Assert
        assert response.status_code == 422  # Validation error

    @patch('routers.paragon_router.get_paragons_in_date_range')
    def test_get_paragons_by_date_range_success(self, mock_get_paragons_date):
        # Arrange
        mock_get_paragons_date.return_value = {
            "success": True,
            "paragons": [
                {
                    "id": 1,
                    "date": "2024-01-15",
                    "sum_price": 15.00,
                    "shop_name": "Żabka"
                }
            ]
        }
        
        # Act
        response = client.get("/paragon/date-range/?user_id=test_uid&start_date=2024-01-01&end_date=2024-01-31")
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["shop_name"] == "Żabka"

    @patch('routers.paragon_router.get_paragons_in_date_range')
    def test_get_paragons_by_date_range_error(self, mock_get_paragons_date):
        # Arrange
        mock_get_paragons_date.return_value = {
            "success": False,
            "error": "Błąd bazy danych"
        }
        
        # Act
        response = client.get("/paragon/date-range/?user_id=test_uid&start_date=2024-01-01&end_date=2024-01-31")
        
        # Assert
        assert response.status_code == 400


class TestReceiptRouter:
    """Testy dla receipt_router.py"""
    
    @patch('routers.receipt_router.save_receipt_to_db')
    def test_save_receipt_success(self, mock_save_receipt):
        # Arrange
        mock_save_receipt.return_value = {
            "success": True,
            "data": {"id": 1001, "sum_price": 25.50}
        }
        
        receipt_data = {
            "storeName": "Biedronka",
            "date": "2024-01-01",
            "items": [
                {"name": "Mleko", "quantity": 2, "price": 3.50},
                {"name": "Chleb", "quantity": 1, "price": 2.00}
            ],
            "total": 9.00,
            "userId": "firebase_uid_123"
        }
        
        # Act
        response = client.post("/receipt/save", json=receipt_data)
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Paragon został zapisany pomyślnie"
        assert data["data"]["id"] == 1001

    @patch('routers.receipt_router.save_receipt_to_db')
    def test_save_receipt_error(self, mock_save_receipt):
        # Arrange
        mock_save_receipt.return_value = {
            "success": False,
            "error": "Sklep nie istnieje"
        }
        
        receipt_data = {
            "storeName": "NonExistentStore",
            "date": "2024-01-01",
            "items": [{"name": "Mleko", "quantity": 1, "price": 3.50}],
            "total": 3.50,
            "userId": "firebase_uid_123"
        }
        
        # Act
        response = client.post("/receipt/save", json=receipt_data)
        
        # Assert
        assert response.status_code == 400
        assert "Sklep nie istnieje" in response.json()["detail"]

    def test_save_receipt_invalid_data(self):
        # Arrange
        invalid_receipt_data = {
            "storeName": "Biedronka",
            # brak wymaganych pól
            "items": [],
            "userId": "firebase_uid_123"
        }
        
        # Act
        response = client.post("/receipt/save", json=invalid_receipt_data)
        
        # Assert
        assert response.status_code == 422  # Validation error

    @patch('routers.receipt_router.delete_receipt_from_db')
    def test_delete_receipt_success(self, mock_delete_receipt):
        # Arrange
        receipt_id = "550e8400-e29b-41d4-a716-446655440000"  # UUID format
        mock_delete_receipt.return_value = {
            "success": True,
            "data": {"id": receipt_id}
        }
        
        # Act
        response = client.delete(f"/receipt/delete/{receipt_id}")
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Paragon został usunięty pomyślnie"

    @patch('routers.receipt_router.delete_receipt_from_db')
    def test_delete_receipt_not_found(self, mock_delete_receipt):
        # Arrange
        receipt_id = "550e8400-e29b-41d4-a716-446655440000"
        mock_delete_receipt.return_value = {
            "success": False,
            "error": "Nie znaleziono paragonu"
        }
        
        # Act
        response = client.delete(f"/receipt/delete/{receipt_id}")
        
        # Assert
        assert response.status_code == 404

    def test_delete_receipt_invalid_uuid(self):
        # Act
        response = client.delete("/receipt/delete/invalid-uuid")
        
        # Assert
        assert response.status_code == 422  # Validation error


class TestUserRouter:
    """Testy dla user_router.py"""
    
    @patch('routers.user_router.supabase_client')
    def test_add_user_success(self, mock_supabase):
        # Arrange
        # Mock dla sprawdzenia czy użytkownik istnieje (nie istnieje)
        mock_existing_check = Mock()
        mock_existing_check.data = []
        
        # Mock dla dodania użytkownika
        mock_insert_result = Mock()
        mock_insert_result.data = [{"id": 123, "token": "firebase_uid_123", "name": "Jan Kowalski"}]
        
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_existing_check
        mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_insert_result
        
        user_data = {
            "token": "firebase_uid_123",
            "name": "Jan Kowalski"
        }
        
        # Act
        response = client.post("/user/add", json=user_data)
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "User created"
        assert data["user"]["name"] == "Jan Kowalski"

    @patch('routers.user_router.supabase_client')
    def test_add_user_already_exists(self, mock_supabase):
        # Arrange
        mock_existing_check = Mock()
        mock_existing_check.data = [{"id": 123}]  # Użytkownik już istnieje
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_existing_check
        
        user_data = {
            "token": "existing_firebase_uid",
            "name": "Jan Kowalski"
        }
        
        # Act
        response = client.post("/user/add", json=user_data)
        
        # Assert
        assert response.status_code == 400
        assert "already exists" in response.json()["detail"]

    def test_add_user_invalid_data(self):
        # Arrange
        invalid_user_data = {
            "token": "firebase_uid_123"
            # brak wymaganego pola 'name'
        }
        
        # Act
        response = client.post("/user/add", json=invalid_user_data)
        
        # Assert
        assert response.status_code == 422  # Validation error


class TestEndpointValidation:
    """Testy walidacji parametrów endpoints"""
    
    def test_paragon_list_page_validation(self):
        # Act - strona mniejsza niż 1
        response = client.get("/paragon/list?user_id=test_uid&page=0&page_size=10")
        
        # Assert
        assert response.status_code == 422

    def test_paragon_list_page_size_validation(self):
        # Act - rozmiar strony większy niż 100
        response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=200")
        
        # Assert
        assert response.status_code == 422

    def test_paragon_date_range_missing_params(self):
        # Act - brak wymaganych parametrów dat
        response = client.get("/paragon/date-range/?user_id=test_uid")
        
        # Assert
        assert response.status_code == 422


if __name__ == "__main__":
    # Uruchom testy routerów
    pytest.main([__file__, "-v"])
import pytest
from fastapi.testclient import TestClient
from fastapi import FastAPI
from unittest.mock import patch, Mock
import sys
import json
from uuid import uuid4

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

    @patch('routers.paragon_router.get_paragons_in_date_range')
    def test_get_paragons_by_date_range_invalid_date_format(self, mock_get_paragons_date):
        # Act
        response = client.get("/paragon/date-range/?user_id=test_uid&start_date=invalid-date&end_date=2024-01-31")
        
        # Assert - service powinien obsłużyć walidację dat
        mock_get_paragons_date.assert_called_with("test_uid", "invalid-date", "2024-01-31")

    @patch('routers.paragon_router.get_paragons_for_user')
    def test_get_user_paragons_pagination_limits(self, mock_get_paragons):
        # Arrange
        mock_get_paragons.return_value = {
            "success": True,
            "paragons": [],
            "total_count": 0,
            "page": 1,
            "page_size": 100,
            "total_pages": 0
        }
        
        # Act
        response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=100")
        
        # Assert
        assert response.status_code == 200
        mock_get_paragons.assert_called_with("test_uid", 1, 100, None)

    @patch('routers.paragon_router.get_paragons_for_user')
    def test_get_user_paragons_empty_store_filter(self, mock_get_paragons):
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
        response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=10&store_name=")
        
        # Assert
        assert response.status_code == 200
        # Pusty string powinien być przekazany jako None lub ""
        mock_get_paragons.assert_called_with("test_uid", 1, 10, "")


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

    @patch('routers.receipt_router.save_receipt_to_db')
    def test_save_receipt_service_exception(self, mock_save_receipt):
        # Arrange
        mock_save_receipt.side_effect = Exception("Database connection failed")
        
        receipt_data = {
            "storeName": "Biedronka",
            "date": "2024-01-01",
            "items": [{"name": "Mleko", "quantity": 1, "price": 3.50}],
            "total": 3.50,
            "userId": "firebase_uid_123"
        }
        
        # Act
        response = client.post("/receipt/save", json=receipt_data)
        
        # Assert
        assert response.status_code == 500
        assert "Błąd serwera" in response.json()["detail"]

    @patch('routers.receipt_router.save_receipt_to_db')
    def test_save_receipt_with_complex_items(self, mock_save_receipt):
        # Arrange
        mock_save_receipt.return_value = {
            "success": True,
            "data": {"id": 1002, "sum_price": 156.99}
        }
        
        receipt_data = {
            "storeName": "Auchan",
            "date": "2024-02-15",
            "items": [
                {"name": "Laptop", "quantity": 1, "price": 2999.99},
                {"name": "Myszka", "quantity": 2, "price": 45.50},
                {"name": "Klawiatura", "quantity": 1, "price": 129.99}
            ],
            "total": 3220.98,
            "userId": "firebase_uid_456"
        }
        
        # Act
        response = client.post("/receipt/save", json=receipt_data)
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Paragon został zapisany pomyślnie"

    @patch('routers.receipt_router.delete_receipt_from_db')
    def test_delete_receipt_success(self, mock_delete_receipt):
        # Arrange
        receipt_id = str(uuid4())
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
        receipt_id = str(uuid4())
        mock_delete_receipt.return_value = {
            "success": False,
            "error": "Nie znaleziono paragonu"
        }
        
        # Act
        response = client.delete(f"/receipt/delete/{receipt_id}")
        
        # Assert
        assert response.status_code == 404
        assert "Nie znaleziono paragonu" in response.json()["detail"]

    def test_delete_receipt_invalid_uuid(self):
        # Act
        response = client.delete("/receipt/delete/invalid-uuid")
        
        # Assert
        assert response.status_code == 422  # Validation error

    @patch('routers.receipt_router.delete_receipt_from_db')
    def test_delete_receipt_service_exception(self, mock_delete_receipt):
        # Arrange
        receipt_id = str(uuid4())
        mock_delete_receipt.side_effect = Exception("Database error")
        
        # Act
        response = client.delete(f"/receipt/delete/{receipt_id}")
        
        # Assert
        assert response.status_code == 500
        assert "Błąd serwera" in response.json()["detail"]

    @patch('routers.receipt_router.delete_receipt_from_db')
    def test_delete_receipt_database_error(self, mock_delete_receipt):
        # Arrange
        receipt_id = str(uuid4())
        mock_delete_receipt.return_value = {
            "success": False,
            "error": "Błąd bazy danych podczas usuwania"
        }
        
        # Act
        response = client.delete(f"/receipt/delete/{receipt_id}")
        
        # Assert
        assert response.status_code == 404


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
        mock_existing_check.data = [{"id": 123}]  
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_existing_check
        
        user_data = {
            "token": "jakistoken",
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
        assert response.status_code == 422  

    @patch('routers.user_router.supabase_client')
    def test_add_user_database_error(self, mock_supabase):
        # Arrange
        mock_existing_check = Mock()
        mock_existing_check.data = []
        
        # Mock error podczas dodawania użytkownika
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_existing_check
        mock_supabase.table.return_value.insert.return_value.execute.side_effect = Exception("Database connection failed")
        
        user_data = {
            "token": "firebase_uid_789",
            "name": "Anna Nowak"
        }
        
        # Act
        response = client.post("/user/add", json=user_data)
        
        # Assert
        assert response.status_code == 500

    def test_add_user_empty_name(self):
        # Arrange
        user_data = {
            "token": "firebase_uid_123",
            "name": ""  # puste imię
        }
        
        # Act
        response = client.post("/user/add", json=user_data)
        

    def test_add_user_empty_token(self):
        # Arrange
        user_data = {
            "token": "",  # pusty token
            "name": "Jan Kowalski"
        }
        
        # Act
        response = client.post("/user/add", json=user_data)
        
        # Assert
        assert response.status_code == 400


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

    def test_paragon_list_negative_page_size(self):
        # Act - ujemny rozmiar strony
        response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=-5")
        
        # Assert
        assert response.status_code == 422

    def test_paragon_date_range_missing_params(self):
        # Act - brak wymaganych parametrów dat
        response = client.get("/paragon/date-range/?user_id=test_uid")
        
        # Assert
        assert response.status_code == 422

    def test_paragon_date_range_missing_user_id(self):
        # Act - brak user_id
        response = client.get("/paragon/date-range/?start_date=2024-01-01&end_date=2024-01-31")
        
        # Assert
        assert response.status_code == 422

    def test_paragon_date_range_missing_start_date(self):
        # Act - brak start_date
        response = client.get("/paragon/date-range/?user_id=test_uid&end_date=2024-01-31")
        
        # Assert
        assert response.status_code == 422

    def test_paragon_date_range_missing_end_date(self):
        # Act - brak end_date
        response = client.get("/paragon/date-range/?user_id=test_uid&start_date=2024-01-01")
        
        # Assert
        assert response.status_code == 422

    def test_paragon_list_extreme_pagination(self):
        # Act - bardzo duża strona
        response = client.get("/paragon/list?user_id=test_uid&page=999999&page_size=1")
        
        # Assert - powinno przejść walidację FastAPI ale service może zwrócić pusty wynik
        assert response.status_code == 422 or response.status_code == 200


class TestErrorHandling:
    """Testy obsługi błędów"""
    
    @patch('routers.paragon_router.get_paragons_for_user')
    def test_paragon_service_returns_none(self, mock_get_paragons):
        # Arrange
        mock_get_paragons.return_value = None
        
        response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=10")

        # Assert: endpoint powinien zwrócić odpowiedź z błędem
        assert response.status_code == 500  
        json_data = response.json()
        assert "error" in json_data or "detail" in json_data

    @patch('routers.paragon_router.get_paragons_for_user')
    def test_paragon_service_missing_success_key(self, mock_get_paragons):
        # Arrange
        mock_get_paragons.return_value = {"paragons": []}  # brak klucza "success"
        
        # Act & Assert
        with pytest.raises(KeyError):
            response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=10")

    def test_receipt_invalid_json(self):
        # Act - nieprawidłowy JSON
        response = client.post(
            "/receipt/save", 
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )
        
        # Assert
        assert response.status_code == 422

    def test_receipt_missing_content_type(self):
        # Act - brak nagłówka Content-Type
        response = client.post("/receipt/save", data='{"test": "data"}')
        
        # Assert
        assert response.status_code == 422


class TestIntegrationScenarios:
    """Testy scenariuszy integracyjnych"""
    
    @patch('routers.paragon_router.get_paragons_for_user')
    def test_large_pagination_response(self, mock_get_paragons):
        # Arrange - symulacja dużej ilości danych
        large_paragons_list = [
            {
                "id": i,
                "create_date": f"2024-01-{i:02d}",
                "date": f"2024-01-{i:02d}",
                "sum_price": 10.00 + i,
                "shop_name": f"Sklep_{i}",
                "location": f"ul. Testowa {i}",
                "receipt_indekses": []
            }
            for i in range(1, 101)  # 100 paragonów
        ]
        
        mock_get_paragons.return_value = {
            "success": True,
            "paragons": large_paragons_list,
            "total_count": 1000,
            "page": 1,
            "page_size": 100,
            "total_pages": 10
        }
        
        # Act
        response = client.get("/paragon/list?user_id=test_uid&page=1&page_size=100")
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["paragons"]) == 100
        assert data["total_count"] == 1000
        assert data["total_pages"] == 10

    @patch('routers.receipt_router.save_receipt_to_db')
    def test_receipt_with_zero_total(self, mock_save_receipt):
        # Arrange - paragon z totalem 0 (np. zwroty)
        mock_save_receipt.return_value = {
            "success": True,
            "data": {"id": 1003, "sum_price": 0.00}
        }
        
        receipt_data = {
            "storeName": "Biedronka",
            "date": "2024-03-01",
            "items": [
                {"name": "Krakersy", "quantity": 1, "price": 0.00}
            ],
            "total": 0.00,
            "userId": "firebase_uid_return"
        }
        
        # Act
        response = client.post("/receipt/save", json=receipt_data)
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["sum_price"] == 0.00


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
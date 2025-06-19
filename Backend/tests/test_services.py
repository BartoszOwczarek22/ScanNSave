import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime
import sys
import os

# Dodaj ścieżkę do głównego katalogu projektu
sys.path.append('..')

from models.receipt_model import Receipt, ReceiptItem
from services.paragon_service import (
    get_user_id_by_token,
    get_existing_shop_parcel,
    get_or_create_product,
    build_paragon,
    get_paragons_for_user
)
from services.receipt_service import save_receipt_to_db, delete_receipt_from_db


class TestParagonService:
    """Testy dla paragon_service.py"""
    
    @patch('services.paragon_service.supabase_client')
    def test_get_user_id_by_token_success(self, mock_supabase):
        # Arrange
        mock_result = Mock()
        mock_result.data = [{"id": 123}]
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result
        
        # Act
        result = get_user_id_by_token("test_firebase_uid")
        
        # Assert
        assert result["success"] is True
        assert result["user_id"] == 123
        mock_supabase.table.assert_called_with("users")

    @patch('services.paragon_service.supabase_client')
    def test_get_user_id_by_token_not_found(self, mock_supabase):
        # Arrange
        mock_result = Mock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result
        
        # Act
        result = get_user_id_by_token("non_existent_uid")
        
        # Assert
        assert result["success"] is False
        assert "nie został znaleziony" in result["error"]

    @patch('services.paragon_service.supabase_client')
    def test_get_existing_shop_parcel_success(self, mock_supabase):
        # Arrange
        # Mock dla zapytania o sklep
        mock_shop_result = Mock()
        mock_shop_result.data = [{"id": 456, "name": "Biedronka"}]
        
        # Mock dla zapytania o parcel
        mock_parcel_result = Mock()
        mock_parcel_result.data = [{"id": 789}]
        
        mock_supabase.table.return_value.select.return_value.ilike.return_value.execute.return_value = mock_shop_result
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_parcel_result
        
        # Act
        result = get_existing_shop_parcel("Biedronka")
        
        # Assert
        assert result["success"] is True
        assert result["shop_parcel_id"] == 789
        assert result["shop_id"] == 456

    @patch('services.paragon_service.supabase_client')
    def test_get_existing_shop_parcel_shop_not_found(self, mock_supabase):
        # Arrange
        mock_result = Mock()
        mock_result.data = []
        mock_supabase.table.return_value.select.return_value.ilike.return_value.execute.return_value = mock_result
        
        # Act
        result = get_existing_shop_parcel("NonExistentShop")
        
        # Assert
        assert result["success"] is False
        assert "nie istnieje w bazie danych" in result["error"]

    @patch('services.paragon_service.supabase_client')
    def test_get_or_create_product_existing(self, mock_supabase):
        # Arrange
        mock_result = Mock()
        mock_result.data = [{"id": 999}]
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_result
        
        # Act
        result = get_or_create_product("Mleko")
        
        # Assert
        assert result["success"] is True
        assert result["product_id"] == 999

    @patch('services.paragon_service.supabase_client')
    def test_get_or_create_product_new_product(self, mock_supabase):
        # Arrange
        # Mock dla sprawdzenia czy produkt istnieje (nie istnieje)
        mock_product_check = Mock()
        mock_product_check.data = []
        
        # Mock dla utworzenia nowego produktu
        mock_new_product = Mock()
        mock_new_product.data = [{"id": 1001}]
        
        mock_supabase.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            mock_product_check,  # sprawdzenie produktu
            mock_new_product     # utworzenie produktu
        ]
        mock_supabase.table.return_value.insert.return_value.execute.return_value = mock_new_product
        
        # Act
        result = get_or_create_product("Nowy Produkt")
        
        # Assert
        assert result["success"] is True
        assert result["product_id"] == 1001

    def test_build_paragon(self):
        # Arrange
        mock_item = {
            "id": 1,
            "create_date": "2024-01-01",
            "date": "2024-01-01",
            "sum_price": 25.50,
            "shops_parcels": {
                "location": "ul. Główna 1",
                "shops": {"name": "Biedronka"}
            }
        }
        
        with patch('services.paragon_service.supabase_client') as mock_supabase:
            mock_indekses_result = Mock()
            mock_indekses_result.data = [
                {
                    "quantity": 2,
                    "receipt_indekses": {
                        "id": 1,
                        "indeks": "Mleko",
                        "price": 5.00,
                        "product_id": 100,
                        "shop_id": 200
                    }
                }
            ]
            mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value = mock_indekses_result
        
            # Act
            result = build_paragon(mock_item)
        
            # Assert
            assert result["id"] == 1
            assert result["shop_name"] == "Biedronka"
            assert result["location"] == "ul. Główna 1"
            assert result["sum_price"] == 25.50
            assert len(result["receipt_indekses"]) == 1
            assert result["receipt_indekses"][0]["indeks"] == "Mleko"


class TestReceiptService:
    """Testy dla receipt_service.py"""
    
    @patch('services.receipt_service.get_user_id_by_token')
    @patch('services.receipt_service.get_existing_shop_parcel')
    @patch('services.receipt_service.get_or_create_product')
    @patch('services.receipt_service.supabase_client')
    def test_save_receipt_to_db_success(self, mock_supabase, mock_get_product, mock_get_shop, mock_get_user):
        # Arrange
        mock_get_user.return_value = {"success": True, "user_id": 123}
        mock_get_shop.return_value = {"success": True, "shop_parcel_id": 456, "shop_id": 789}
        mock_get_product.return_value = {"success": True, "product_id": 999}
        
        # Mock dla zapisania paragonu
        mock_receipt_result = Mock()
        mock_receipt_result.data = [{"id": 1001}]
        
        # Mock dla zapisania indeksu
        mock_indeks_result = Mock()
        mock_indeks_result.data = [{"id": 2001}]
        
        mock_supabase.table.return_value.insert.return_value.execute.side_effect = [
            mock_receipt_result,  # receipts
            mock_indeks_result,   # receipt_indekses
            Mock()                # receipt_connect_indekses
        ]
        
        receipt = Receipt(
            storeName="Biedronka",
            date="2024-01-01",
            items=[ReceiptItem(name="Mleko", quantity=2, price=3.50)],
            total=7.00,
            userId="firebase_uid_123"
        )
        
        # Act
        result = save_receipt_to_db(receipt)
        
        # Assert
        assert result["success"] is True
        assert result["data"]["id"] == 1001

    @patch('services.receipt_service.get_user_id_by_token')
    def test_save_receipt_to_db_user_not_found(self, mock_get_user):
        # Arrange
        mock_get_user.return_value = {"success": False, "error": "Użytkownik nie znaleziony"}
        
        receipt = Receipt(
            storeName="Biedronka",
            date="2024-01-01",
            items=[ReceiptItem(name="Mleko", quantity=2, price=3.50)],
            total=7.00,
            userId="invalid_uid"
        )
        
        # Act
        result = save_receipt_to_db(receipt)
        
        # Assert
        assert result["success"] is False
        assert "Błąd użytkownika" in result["error"]

    @patch('services.receipt_service.supabase_client')
    def test_delete_receipt_from_db_success(self, mock_supabase):
        # Arrange
        mock_delete_result = Mock()
        mock_delete_result.data = [{"id": 1001}]
        mock_supabase.table.return_value.delete.return_value.eq.return_value.execute.return_value = mock_delete_result
        
        # Act
        result = delete_receipt_from_db(1001)
        
        # Assert
        assert result["success"] is True
        assert result["data"]["id"] == 1001

    @patch('services.receipt_service.supabase_client')
    def test_delete_receipt_from_db_not_found(self, mock_supabase):
        # Arrange
        mock_delete_result = Mock()
        mock_delete_result.data = []
        mock_supabase.table.return_value.delete.return_value.eq.return_value.execute.return_value = mock_delete_result
        
        # Act
        result = delete_receipt_from_db(9999)
        
        # Assert
        assert result["success"] is False
        assert "Nie znaleziono paragonu" in result["error"]


class TestReceiptModel:
    """Testy dla modeli danych"""
    
    def test_receipt_item_creation(self):
        # Act
        item = ReceiptItem(name="Mleko", quantity=2, price=3.50)
        
        # Assert
        assert item.name == "Mleko"
        assert item.quantity == 2
        assert item.price == 3.50

    def test_receipt_creation(self):
        # Arrange
        items = [
            ReceiptItem(name="Mleko", quantity=2, price=3.50),
            ReceiptItem(name="Chleb", quantity=1, price=2.00)
        ]
        
        # Act
        receipt = Receipt(
            storeName="Biedronka",
            date="2024-01-01",
            items=items,
            total=9.00,
            userId="firebase_uid_123"
        )
        
        # Assert
        assert receipt.storeName == "Biedronka"
        assert receipt.date == "2024-01-01"
        assert len(receipt.items) == 2
        assert receipt.total == 9.00
        assert receipt.userId == "firebase_uid_123"

    def test_receipt_without_date(self):
        # Act
        receipt = Receipt(
            storeName="Biedronka",
            items=[ReceiptItem(name="Mleko", quantity=1, price=3.50)],
            total=3.50,
            userId="firebase_uid_123"
        )
        
        # Assert
        assert receipt.date is None


# Testy integracyjne (wymagają działającej bazy danych)
class TestIntegration:
    """Testy integracyjne - uruchamiaj tylko z działającą bazą danych"""
    
    @pytest.mark.integration
    def test_full_receipt_flow(self):
        """Test pełnego przepływu: zapisanie i pobranie paragonu"""
        # Ten test wymaga prawdziwej bazy danych i należy go uruchamiać osobno
        pytest.skip("Wymaga działającej bazy danych - uruchom z flagą --integration")


if __name__ == "__main__":
    # Uruchom testy
    pytest.main([__file__, "-v"])
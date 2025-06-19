# Makefile do testów backendu

.PHONY: help install test test-unit test-routers test-integration test-coverage clean

# Domyślna akcja
help:
	@echo "🧪 Dostępne komendy testowe:"
	@echo ""
	@echo "  make install         - Zainstaluj zależności testowe"
	@echo "  make test           - Uruchom wszystkie podstawowe testy"
	@echo "  make test-unit      - Uruchom tylko testy jednostkowe"
	@echo "  make test-routers   - Uruchom tylko testy routerów"
	@echo "  make test-integration - Uruchom testy integracyjne"
	@echo "  make test-coverage  - Uruchom testy z pokryciem kodu"
	@echo "  make clean          - Wyczyść pliki testowe"
	@echo ""

# Instalacja zależności
install:
	@echo "📦 Instalowanie zależności testowych..."
	pip install -r requirements-test.txt

# Podstawowe testy (bez integracyjnych)
test:
	@echo "🧪 Uruchamianie podstawowych testów..."
	pytest test_services.py test_routers.py -v

# Tylko testy jednostkowe
test-unit:
	@echo "🔧 Uruchamianie testów jednostkowych..."
	pytest test_services.py -v

# Tylko testy routerów
test-routers:
	@echo "🌐 Uruchamianie testów routerów..."
	pytest test_routers.py -v

# Testy integracyjne (wymagają działającej bazy)
test-integration:
	@echo "🔗 Uruchamianie testów integracyjnych..."
	pytest -m integration -v

# Testy z pokryciem kodu
test-coverage:
	@echo "📊 Uruchamianie testów z analizą pokrycia..."
	pytest --cov=services --cov=models --cov-report=html --cov-report=term -v
	@echo "📈 Raport HTML: htmlcov/index.html"

# Szybkie testy (bez verbose)
test-quick:
	@echo "⚡ Szybkie testy..."
	pytest test_services.py test_routers.py -q

# Testy z szczegółowym logowaniem
test-verbose:
	@echo "🔍 Szczegółowe testy..."
	pytest test_services.py test_routers.py -v -s

# Testy konkretnej funkcji/klasy
test-specific:
	@echo "🎯 Uruchom konkretny test:"
	@echo "Przykład: make test-file FILE=test_services.py::TestParagonService::test_get_user_id_by_token_success"
	
test-file:
	pytest $(FILE) -v

# Czyszczenie
clean:
	@echo "🧹 Czyszczenie plików testowych..."
	rm -rf htmlcov/
	rm -rf .pytest_cache/
	rm -rf __pycache__/
	rm -rf .coverage
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -delete

# Przygotowanie środowiska testowego
setup-test-env:
	@echo "⚙️ Przygotowywanie środowiska testowego..."
	python -m venv test_env
	source test_env/bin/activate && pip install -r requirements-test.txt
	@echo "✅ Środowisko testowe gotowe. Aktywuj przez: source test_env/bin/activate"

# Sprawdzenie jakości kodu
lint:
	@echo "🧹 Sprawdzanie jakości kodu..."
	@if command -v flake8 >/dev/null 2>&1; then \
		flake8 services/ models/ --max-line-length=100; \
	else \
		echo "⚠️ flake8 nie jest zainstalowany. Instaluję..."; \
		pip install flake8; \
		flake8 services/ models/ --max-line-length=100; \
	fi

# Formatowanie kodu
format:
	@echo "✨ Formatowanie kodu..."
	@if command -v black >/dev/null 2>&1; then \
		black services/ models/ --line-length=100; \
	else \
		echo "⚠️ black nie jest zainstalowany. Instaluję..."; \
		pip install black; \
		black services/ models/ --line-length=100; \
	fi

# Pełny workflow: format + lint + test
full-check: format lint test
	@echo "✅ Pełne sprawdzenie zakończone!"

# Pomoc dla konkretnych testów
test-help:
	@echo "🎯 Jak uruchomić konkretne testy:"
	@echo ""
	@echo "  pytest test_services.py::TestParagonService::test_get_user_id_by_token_success"
	@echo "  pytest test_routers.py::TestReceiptRouter -v"
	@echo "  pytest -k 'test_save_receipt' -v"
	@echo "  pytest --lf  # Tylko ostatnio nieudane"
	@echo "  pytest --tb=short  # Krótkie tracebacki"
	@echo ""
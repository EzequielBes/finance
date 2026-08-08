import pytest
import pytest_asyncio
from httpx import AsyncClient
from tests.helpers import register_and_login


@pytest_asyncio.fixture
async def auth_headers(client: AsyncClient):
    token = await register_and_login(client)
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_bulk_import_inserts_transactions(client: AsyncClient, auth_headers: dict):
    payload = {
        "transactions": [
            {
                "description": "Supermercado Extra",
                "amount": 150.00,
                "date": "2024-01-15",
                "type": "expense",
                "import_source": "nubank_csv"
            },
            {
                "description": "Salário",
                "amount": 5000.00,
                "date": "2024-01-01",
                "type": "income",
                "import_source": "nubank_csv"
            }
        ]
    }
    response = await client.post("/transactions/bulk", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["inserted"] == 2
    assert data["skipped_duplicates"] == 0
    assert data["total_received"] == 2


@pytest.mark.asyncio
async def test_bulk_import_skips_duplicates(client: AsyncClient, auth_headers: dict):
    payload = {
        "transactions": [
            {
                "description": "Supermercado Extra",
                "amount": 150.00,
                "date": "2024-01-15",
                "type": "expense",
                "import_source": "nubank_csv"
            }
        ]
    }
    # Primeira importação
    await client.post("/transactions/bulk", json=payload, headers=auth_headers)
    # Segunda importação com a mesma transação
    response = await client.post("/transactions/bulk", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["inserted"] == 0
    assert data["skipped_duplicates"] == 1
    assert data["total_received"] == 1


@pytest.mark.asyncio
async def test_bulk_import_skips_duplicates_within_one_day_tolerance(client: AsyncClient, auth_headers: dict):
    # Existing transaction on Jan 15
    await client.post("/transactions/bulk", json={
        "transactions": [{
            "description": "Restaurante",
            "amount": 80.00,
            "date": "2024-01-15",
            "type": "expense",
            "import_source": "nubank_csv"
        }]
    }, headers=auth_headers)

    # Import transaction on Jan 16 (1 day difference)
    response = await client.post("/transactions/bulk", json={
        "transactions": [{
            "description": "Restaurante",
            "amount": 80.00,
            "date": "2024-01-16",
            "type": "expense",
            "import_source": "nubank_csv"
        }]
    }, headers=auth_headers)

    assert response.status_code == 201
    data = response.json()
    assert data["inserted"] == 0
    assert data["skipped_duplicates"] == 1


@pytest.mark.asyncio
async def test_bulk_import_same_batch_duplicates(client: AsyncClient, auth_headers: dict):
    payload = {
        "transactions": [
            {
                "description": "Farmácia",
                "amount": 45.00,
                "date": "2024-01-20",
                "type": "expense",
                "import_source": "nubank_csv"
            },
            {
                "description": "Farmácia",
                "amount": 45.00,
                "date": "2024-01-20",
                "type": "expense",
                "import_source": "nubank_csv"
            }
        ]
    }
    response = await client.post("/transactions/bulk", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["inserted"] == 1
    assert data["skipped_duplicates"] == 1
    assert data["total_received"] == 2


@pytest.mark.asyncio
async def test_bulk_import_different_type_not_duplicate(client: AsyncClient, auth_headers: dict):
    payload = {
        "transactions": [
            {
                "description": "Reembolso",
                "amount": 100.00,
                "date": "2024-01-20",
                "type": "expense",
                "import_source": "nubank_csv"
            },
            {
                "description": "Reembolso",
                "amount": 100.00,
                "date": "2024-01-20",
                "type": "income",
                "import_source": "nubank_csv"
            }
        ]
    }
    response = await client.post("/transactions/bulk", json=payload, headers=auth_headers)
    assert response.status_code == 201
    data = response.json()
    assert data["inserted"] == 2
    assert data["skipped_duplicates"] == 0
    assert data["total_received"] == 2


@pytest.mark.asyncio
async def test_bulk_import_saves_import_source(client: AsyncClient, auth_headers: dict):
    payload = {
        "transactions": [
            {
                "description": "Cinema",
                "amount": 35.00,
                "date": "2024-01-25",
                "type": "expense",
                "import_source": "itau_csv"
            }
        ]
    }
    response = await client.post("/transactions/bulk", json=payload, headers=auth_headers)
    assert response.status_code == 201

    tx_response = await client.get("/transactions", headers=auth_headers)
    assert tx_response.status_code == 200
    items = tx_response.json()["items"]
    imported_tx = next(item for item in items if item["description"] == "Cinema")
    assert imported_tx["import_source"] == "itau_csv"


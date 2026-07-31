import pytest
from tests.helpers import register_and_login


async def get_category_id(client, headers):
    r = await client.post("/categories", json={
        "name": "Outros", "type": "expense", "color": "#999", "icon": "tag"
    }, headers=headers)
    return r.json()["id"]


@pytest.mark.asyncio
async def test_create_simple_transaction(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    response = await client.post("/transactions", json={
        "category_id": cat_id,
        "description": "Conta de luz",
        "amount": 250.0,
        "date": "2026-07-10",
        "type": "expense",
        "is_recurring": False
    }, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["amount"] == 250.0
    assert data["description"] == "Conta de luz"
    assert data["installments_total"] is None


@pytest.mark.asyncio
async def test_create_recurring_transaction(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    response = await client.post("/transactions", json={
        "category_id": cat_id,
        "description": "Aluguel",
        "amount": 1200.0,
        "date": "2026-07-01",
        "type": "expense",
        "is_recurring": True,
        "recurrence_period": "monthly"
    }, headers=headers)
    assert response.status_code == 201
    assert response.json()["is_recurring"] is True
    assert response.json()["recurrence_period"] == "monthly"


@pytest.mark.asyncio
async def test_create_installment_transaction_creates_multiple(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    response = await client.post("/transactions", json={
        "category_id": cat_id,
        "description": "Tênis Nike",
        "amount": 100.0,
        "date": "2026-07-01",
        "type": "expense",
        "is_recurring": False,
        "installments_total": 3
    }, headers=headers)
    assert response.status_code == 201
    # Buscar todas as transações para verificar que criou 3
    all_tx = await client.get("/transactions", headers=headers)
    items = all_tx.json()["items"]
    group_id = response.json()["installment_group_id"]
    installments = sorted(
        [t for t in items if t["installment_group_id"] == group_id],
        key=lambda x: x["installments_current"]
    )
    assert len(installments) == 3
    assert installments[0]["installments_current"] == 1
    assert installments[1]["installments_current"] == 2
    assert installments[2]["installments_current"] == 3


@pytest.mark.asyncio
async def test_list_transactions_with_filter(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "A", "amount": 10.0,
        "date": "2026-07-01", "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "B", "amount": 20.0,
        "date": "2026-08-01", "type": "expense", "is_recurring": False
    }, headers=headers)
    response = await client.get("/transactions?month=7&year=2026", headers=headers)
    items = response.json()["items"]
    assert len(items) == 1
    assert items[0]["description"] == "A"


@pytest.mark.asyncio
async def test_delete_transaction(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    create = await client.post("/transactions", json={
        "category_id": cat_id, "description": "X", "amount": 50.0,
        "date": "2026-07-15", "type": "expense", "is_recurring": False
    }, headers=headers)
    tx_id = create.json()["id"]
    delete = await client.delete(f"/transactions/{tx_id}", headers=headers)
    assert delete.status_code == 204

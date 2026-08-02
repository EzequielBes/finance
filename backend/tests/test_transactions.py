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


@pytest.mark.asyncio
async def test_update_transaction_remove_category(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    create = await client.post("/transactions", json={
        "category_id": cat_id, "description": "Supermercado", "amount": 150.0,
        "date": "2026-07-10", "type": "expense", "is_recurring": False
    }, headers=headers)
    tx_id = create.json()["id"]
    assert create.json()["category_id"] == cat_id

    # Remover a categoria explicitamente passando category_id: null
    update_res = await client.put(f"/transactions/{tx_id}", json={"category_id": None}, headers=headers)
    assert update_res.status_code == 200
    assert update_res.json()["category_id"] is None


@pytest.mark.asyncio
async def test_category_ownership_validation_post_and_put(client):
    await client.post("/auth/register", json={
        "name": "User 1", "email": "u1@example.com", "password": "password123"
    })
    login_u1 = await client.post("/auth/login", json={
        "email": "u1@example.com", "password": "password123"
    })
    headers_user1 = {"Authorization": f"Bearer {login_u1.json()['access_token']}"}
    cat_id_user1 = await get_category_id(client, headers_user1)

    await client.post("/auth/register", json={
        "name": "User 2", "email": "u2@example.com", "password": "password123"
    })
    login_u2 = await client.post("/auth/login", json={
        "email": "u2@example.com", "password": "password123"
    })
    headers_user2 = {"Authorization": f"Bearer {login_u2.json()['access_token']}"}

    # Tentar criar transação com categoria de outro usuário
    res_post_invalid = await client.post("/transactions", json={
        "category_id": cat_id_user1, "description": "Tentativa", "amount": 50.0,
        "date": "2026-07-10", "type": "expense", "is_recurring": False
    }, headers=headers_user2)
    assert res_post_invalid.status_code == 404
    assert res_post_invalid.json()["detail"] == "Categoria não encontrada"

    # User 2 cria transação sem categoria
    res_post_ok = await client.post("/transactions", json={
        "category_id": None, "description": "Válida", "amount": 50.0,
        "date": "2026-07-10", "type": "expense", "is_recurring": False
    }, headers=headers_user2)
    assert res_post_ok.status_code == 201
    tx_id_user2 = res_post_ok.json()["id"]

    # Tentar atualizar transação do User 2 com categoria do User 1
    res_put_invalid = await client.put(f"/transactions/{tx_id_user2}", json={
        "category_id": cat_id_user1
    }, headers=headers_user2)
    assert res_put_invalid.status_code == 404
    assert res_put_invalid.json()["detail"] == "Categoria não encontrada"


@pytest.mark.asyncio
async def test_list_transactions_year_only_filter(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Tx 2025", "amount": 100.0,
        "date": "2025-11-20", "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Tx 2026", "amount": 200.0,
        "date": "2026-05-10", "type": "expense", "is_recurring": False
    }, headers=headers)

    res_2026 = await client.get("/transactions?year=2026", headers=headers)
    assert res_2026.status_code == 200
    items_2026 = res_2026.json()["items"]
    assert len(items_2026) == 1
    assert items_2026[0]["description"] == "Tx 2026"

    res_2025 = await client.get("/transactions?year=2025", headers=headers)
    assert res_2025.status_code == 200
    items_2025 = res_2025.json()["items"]
    assert len(items_2025) == 1
    assert items_2025[0]["description"] == "Tx 2025"


@pytest.mark.asyncio
async def test_cannot_access_others_transaction(client):
    # User A cria uma transação
    token_a = await register_and_login(client)
    headers_a = {"Authorization": f"Bearer {token_a}"}
    create = await client.post("/transactions", json={
        "category_id": None, "description": "Privado de A", "amount": 99.0,
        "date": "2026-06-01", "type": "expense", "is_recurring": False
    }, headers=headers_a)
    assert create.status_code == 201
    tx_id = create.json()["id"]

    # User B se registra e faz login
    token_b = await register_and_login(
        client,
        email="userb@email.com",
        name="User B",
        password="senhaB123",
    )
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # GET deve retornar 404
    r_get = await client.get(f"/transactions/{tx_id}", headers=headers_b)
    assert r_get.status_code == 404

    # PUT deve retornar 404
    r_put = await client.put(f"/transactions/{tx_id}", json={"description": "Hackeado"}, headers=headers_b)
    assert r_put.status_code == 404

    # DELETE deve retornar 404
    r_del = await client.delete(f"/transactions/{tx_id}", headers=headers_b)
    assert r_del.status_code == 404


@pytest.mark.asyncio
async def test_suggestions_returns_most_recent_per_description(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Mercado", "amount": 980.0,
        "date": "2026-06-01", "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Mercado", "amount": 1200.0,
        "date": "2026-07-15", "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/transactions/suggestions?q=merc", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["description"] == "Mercado"
    assert data[0]["amount"] == 1200.0


@pytest.mark.asyncio
async def test_suggestions_case_insensitive(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Conta de Luz", "amount": 250.0,
        "date": "2026-07-01", "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/transactions/suggestions?q=CONTA", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["description"] == "Conta de Luz"


@pytest.mark.asyncio
async def test_suggestions_limits_to_five_distinct_descriptions(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_id = await get_category_id(client, headers)
    for i in range(7):
        await client.post("/transactions", json={
            "category_id": cat_id, "description": f"Assinatura {i}", "amount": 10.0 + i,
            "date": "2026-07-01", "type": "expense", "is_recurring": False
        }, headers=headers)

    response = await client.get("/transactions/suggestions?q=assinatura", headers=headers)
    assert response.status_code == 200
    assert len(response.json()) == 5


@pytest.mark.asyncio
async def test_suggestions_only_own_transactions(client):
    token_a = await register_and_login(client)
    headers_a = {"Authorization": f"Bearer {token_a}"}
    cat_id_a = await get_category_id(client, headers_a)
    await client.post("/transactions", json={
        "category_id": cat_id_a, "description": "Aluguel", "amount": 1200.0,
        "date": "2026-07-01", "type": "expense", "is_recurring": False
    }, headers=headers_a)

    token_b = await register_and_login(client, email="userb@email.com", name="User B", password="senhaB999")
    headers_b = {"Authorization": f"Bearer {token_b}"}

    response = await client.get("/transactions/suggestions?q=aluguel", headers=headers_b)
    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_suggestions_requires_min_two_chars(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/transactions/suggestions?q=a", headers=headers)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_suggestions_route_does_not_collide_with_transaction_id(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/transactions/suggestions?q=xx", headers=headers)
    assert response.status_code == 200
    assert response.json() == []


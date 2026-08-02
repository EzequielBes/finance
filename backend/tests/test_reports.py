import pytest
from datetime import date
from tests.helpers import register_and_login


@pytest.mark.asyncio
async def test_savings_analysis_excludes_categories_below_eighty_percent(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Educação", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 1000.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Curso", "amount": 500.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    names = [item["category_name"] for item in response.json()]
    assert "Educação" not in names


@pytest.mark.asyncio
async def test_savings_analysis_essential_category_has_no_suggested_cut(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Saúde", "type": "expense", "color": "#b8563a", "icon": "tag", "monthly_limit": 500.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Consulta", "amount": 800.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    item = next(i for i in response.json() if i["category_name"] == "Saúde")
    assert item["is_essential"] is True
    assert item["suggested_cut"] is None


@pytest.mark.asyncio
async def test_savings_analysis_cuttable_category_over_limit_has_suggested_cut(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet", "monthly_limit": 500.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Roupas", "amount": 800.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    item = next(i for i in response.json() if i["category_name"] == "Compras")
    assert item["is_essential"] is False
    assert item["suggested_cut"] == 300.0


@pytest.mark.asyncio
async def test_savings_analysis_cuttable_between_eighty_and_hundred_has_no_cut(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 1000.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Cinema", "amount": 850.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    item = next(i for i in response.json() if i["category_name"] == "Lazer")
    assert item["suggested_cut"] is None
    assert item["percent"] == pytest.approx(85.0, rel=0.01)


@pytest.mark.asyncio
async def test_savings_analysis_ordered_by_largest_overage_first(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat_a = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet", "monthly_limit": 500.0
    }, headers=headers)
    cat_b = await client.post("/categories", json={
        "name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 500.0
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_a.json()["id"], "description": "Roupas", "amount": 600.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_b.json()["id"], "description": "Show", "amount": 1000.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    data = response.json()
    assert data[0]["category_name"] == "Lazer"
    assert data[1]["category_name"] == "Compras"


@pytest.mark.asyncio
async def test_savings_analysis_excludes_income_transactions_from_usage(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    cat = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet", "monthly_limit": 500.0
    }, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Roupas", "amount": 450.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)
    # Refund posted as income against the same expense category — must not
    # count toward current-month usage.
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Estorno", "amount": 9999.0,
        "date": date.today().isoformat(), "type": "income", "is_recurring": False
    }, headers=headers)

    response = await client.get("/reports/savings-analysis", headers=headers)
    assert response.status_code == 200
    item = next((i for i in response.json() if i["category_name"] == "Compras"), None)
    assert item is not None
    assert item["current_amount"] == 450.0
    assert item["suggested_cut"] is None


@pytest.mark.asyncio
async def test_savings_analysis_only_own_categories(client):
    token_a = await register_and_login(client)
    headers_a = {"Authorization": f"Bearer {token_a}"}
    cat = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet", "monthly_limit": 100.0
    }, headers=headers_a)
    await client.post("/transactions", json={
        "category_id": cat.json()["id"], "description": "Item", "amount": 200.0,
        "date": date.today().isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers_a)

    token_b = await register_and_login(client, email="userb@email.com", name="User B", password="senhaB999")
    headers_b = {"Authorization": f"Bearer {token_b}"}

    response = await client.get("/reports/savings-analysis", headers=headers_b)
    assert response.status_code == 200
    assert response.json() == []

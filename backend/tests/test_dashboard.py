import pytest
from tests.helpers import register_and_login


@pytest.mark.asyncio
async def test_dashboard_summary_empty(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/dashboard/summary", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total_income"] == 0.0
    assert data["total_expense"] == 0.0
    assert data["balance"] == 0.0
    assert data["savings_percent"] == 0.0
    assert data["by_category"] == []


@pytest.mark.asyncio
async def test_dashboard_summary_with_data(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    # Renda
    await client.post("/income", json={"amount": 5000.0, "date": "2026-07-01", "source": "Salário", "is_recurring": True, "recurrence_period": "monthly"}, headers=headers)
    # Categoria e gasto
    cat = await client.post("/categories", json={"name": "Energia", "type": "expense", "color": "#FF0000", "icon": "bolt"}, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={"category_id": cat_id, "description": "Luz", "amount": 250.0, "date": "2026-07-10", "type": "expense", "is_recurring": False}, headers=headers)
    # Busca summary para jul/2026
    response = await client.get("/dashboard/summary?month=7&year=2026", headers=headers)
    data = response.json()
    assert data["total_income"] == pytest.approx(5000.0)
    assert data["total_expense"] == pytest.approx(250.0)
    assert data["balance"] == pytest.approx(4750.0)
    assert len(data["by_category"]) == 1
    assert data["by_category"][0]["name"] == "Energia"


@pytest.mark.asyncio
async def test_dashboard_timeline_returns_events(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    # Transação futura
    cat = await client.post("/categories", json={"name": "Transporte", "type": "expense", "color": "#00FF00", "icon": "bus"}, headers=headers)
    cat_id = cat.json()["id"]
    await client.post("/transactions", json={"category_id": cat_id, "description": "Ônibus", "amount": 300.0, "date": "2026-08-05", "type": "expense", "is_recurring": True, "recurrence_period": "monthly"}, headers=headers)
    # Plano futuro
    await client.post("/plans", json={"name": "Japão", "target_amount": 15000.0, "current_savings": 3000.0, "monthly_contribution": 800.0, "priority": 1}, headers=headers)
    response = await client.get("/dashboard/timeline?months_ahead=6", headers=headers)
    assert response.status_code == 200
    events = response.json()
    assert len(events) >= 1
    types = [e["type"] for e in events]
    assert "plan_milestone" in types or "transaction" in types

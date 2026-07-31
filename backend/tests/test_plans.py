import pytest
from tests.helpers import register_and_login


@pytest.mark.asyncio
async def test_create_plan(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.post("/plans", json={
        "name": "Viagem Japão",
        "target_amount": 15000.0,
        "current_savings": 1000.0,
        "monthly_contribution": 800.0,
        "priority": 1
    }, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Viagem Japão"
    assert data["status"] == "active"
    assert data["parent_plan_id"] is None


@pytest.mark.asyncio
async def test_create_subplan(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    parent = await client.post("/plans", json={
        "name": "Viagem Japão", "target_amount": 15000.0,
        "current_savings": 0.0, "monthly_contribution": 800.0, "priority": 1
    }, headers=headers)
    parent_id = parent.json()["id"]
    sub = await client.post("/plans", json={
        "name": "Passagem Aérea",
        "target_amount": 5000.0,
        "current_savings": 0.0,
        "monthly_contribution": 300.0,
        "priority": 1,
        "parent_plan_id": parent_id
    }, headers=headers)
    assert sub.status_code == 201
    assert sub.json()["parent_plan_id"] == parent_id


@pytest.mark.asyncio
async def test_plan_detail_includes_simulation(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "Carro", "target_amount": 20000.0,
        "current_savings": 2000.0, "monthly_contribution": 1000.0, "priority": 2
    }, headers=headers)
    plan_id = create.json()["id"]
    response = await client.get(f"/plans/{plan_id}", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "simulation" in data
    assert data["simulation"]["months_to_goal"] == 18
    assert data["simulation"]["progress_percent"] == pytest.approx(10.0)


@pytest.mark.asyncio
async def test_plan_simulate_endpoint(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "Reserva", "target_amount": 10000.0,
        "current_savings": 0.0, "monthly_contribution": 500.0, "priority": 1
    }, headers=headers)
    plan_id = create.json()["id"]
    response = await client.get(f"/plans/{plan_id}/simulate?monthly_contribution=1000", headers=headers)
    assert response.status_code == 200
    assert response.json()["months_to_goal"] == 10


@pytest.mark.asyncio
async def test_plan_contribution(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "Mochila", "target_amount": 500.0,
        "current_savings": 0.0, "monthly_contribution": 100.0, "priority": 1
    }, headers=headers)
    plan_id = create.json()["id"]
    contrib = await client.post(f"/plans/{plan_id}/contributions", json={
        "amount": 150.0, "date": "2026-07-31", "notes": "Economizei esse mês"
    }, headers=headers)
    assert contrib.status_code == 201
    # current_savings deve ter aumentado
    detail = await client.get(f"/plans/{plan_id}", headers=headers)
    assert detail.json()["current_savings"] == 150.0


@pytest.mark.asyncio
async def test_update_plan_status(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "X", "target_amount": 100.0,
        "current_savings": 0.0, "monthly_contribution": 10.0, "priority": 1
    }, headers=headers)
    plan_id = create.json()["id"]
    response = await client.put(f"/plans/{plan_id}", json={"status": "paused"}, headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "paused"

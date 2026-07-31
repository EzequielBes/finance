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


@pytest.mark.asyncio
async def test_delete_plan(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "Del", "target_amount": 100.0,
        "current_savings": 0.0, "monthly_contribution": 10.0, "priority": 1
    }, headers=headers)
    plan_id = create.json()["id"]
    response = await client.delete(f"/plans/{plan_id}", headers=headers)
    assert response.status_code == 204
    get_response = await client.get(f"/plans/{plan_id}", headers=headers)
    assert get_response.status_code == 404


@pytest.mark.asyncio
async def test_list_contributions(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/plans", json={
        "name": "Mochila 2", "target_amount": 500.0,
        "current_savings": 0.0, "monthly_contribution": 100.0, "priority": 1
    }, headers=headers)
    plan_id = create.json()["id"]
    await client.post(f"/plans/{plan_id}/contributions", json={
        "amount": 50.0, "date": "2026-07-01", "notes": "C1"
    }, headers=headers)
    await client.post(f"/plans/{plan_id}/contributions", json={
        "amount": 50.0, "date": "2026-07-15", "notes": "C2"
    }, headers=headers)
    response = await client.get(f"/plans/{plan_id}/contributions", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["amount"] == 50.0


@pytest.mark.asyncio
async def test_user_isolation(client):
    token_a = await register_and_login(client)
    headers_a = {"Authorization": f"Bearer {token_a}"}
    token_b = await register_and_login(client, email="userB@test.com", password="123", name="B")
    headers_b = {"Authorization": f"Bearer {token_b}"}

    create = await client.post("/plans", json={
        "name": "Plan A", "target_amount": 100.0,
        "current_savings": 0.0, "monthly_contribution": 10.0, "priority": 1
    }, headers=headers_a)
    plan_id = create.json()["id"]

    # B tenta GET
    resp_get = await client.get(f"/plans/{plan_id}", headers=headers_b)
    assert resp_get.status_code == 404

    # B tenta PUT
    resp_put = await client.put(f"/plans/{plan_id}", json={"name": "Hacked"}, headers=headers_b)
    assert resp_put.status_code == 404

    # B tenta DELETE
    resp_delete = await client.delete(f"/plans/{plan_id}", headers=headers_b)
    assert resp_delete.status_code == 404

    # B tenta POST contribution
    resp_contrib = await client.post(f"/plans/{plan_id}/contributions", json={
        "amount": 10.0, "date": "2026-07-01"
    }, headers=headers_b)
    assert resp_contrib.status_code == 404


@pytest.mark.asyncio
async def test_subplan_nesting_limit(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    parent = await client.post("/plans", json={
        "name": "Parent", "target_amount": 15000.0,
        "current_savings": 0.0, "monthly_contribution": 800.0, "priority": 1
    }, headers=headers)
    parent_id = parent.json()["id"]
    sub = await client.post("/plans", json={
        "name": "Sub", "target_amount": 5000.0,
        "current_savings": 0.0, "monthly_contribution": 300.0,
        "priority": 1, "parent_plan_id": parent_id
    }, headers=headers)
    sub_id = sub.json()["id"]
    
    # Tentativa de criar sub-sub-plano
    sub_sub = await client.post("/plans", json={
        "name": "Sub-Sub", "target_amount": 1000.0,
        "current_savings": 0.0, "monthly_contribution": 100.0,
        "priority": 1, "parent_plan_id": sub_id
    }, headers=headers)
    assert sub_sub.status_code == 400
    assert "Sub-planos não podem ter sub-planos" in sub_sub.json()["detail"]

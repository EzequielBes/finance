import pytest
from tests.helpers import register_and_login


@pytest.mark.asyncio
async def test_create_income_entry(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.post("/income", json={
        "amount": 5000.0,
        "date": "2026-07-01",
        "source": "Salário",
        "is_recurring": True,
        "recurrence_period": "monthly"
    }, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["amount"] == 5000.0
    assert data["source"] == "Salário"


@pytest.mark.asyncio
async def test_list_income_entries(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    await client.post("/income", json={"amount": 5000.0, "date": "2026-07-01", "source": "Salário", "is_recurring": True, "recurrence_period": "monthly"}, headers=headers)
    await client.post("/income", json={"amount": 800.0, "date": "2026-07-15", "source": "Freela", "is_recurring": False}, headers=headers)
    response = await client.get("/income", headers=headers)
    assert response.status_code == 200
    assert len(response.json()) == 2


@pytest.mark.asyncio
async def test_income_summary_average(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    # 3 meses de salário: 5000, 5500, 6000
    await client.post("/income", json={"amount": 5000.0, "date": "2026-05-01", "source": "Salário", "is_recurring": True, "recurrence_period": "monthly"}, headers=headers)
    await client.post("/income", json={"amount": 5500.0, "date": "2026-06-01", "source": "Salário", "is_recurring": True, "recurrence_period": "monthly"}, headers=headers)
    await client.post("/income", json={"amount": 6000.0, "date": "2026-07-01", "source": "Salário", "is_recurring": True, "recurrence_period": "monthly"}, headers=headers)
    response = await client.get("/income/summary", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert "average_last_3_months" in data
    assert data["average_last_3_months"] == pytest.approx(5500.0, rel=0.01)


@pytest.mark.asyncio
async def test_delete_income_entry(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/income", json={"amount": 200.0, "date": "2026-07-20", "source": "Venda", "is_recurring": False}, headers=headers)
    entry_id = create.json()["id"]
    delete = await client.delete(f"/income/{entry_id}", headers=headers)
    assert delete.status_code == 204


@pytest.mark.asyncio
async def test_update_income_entry(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/income", json={"amount": 1000.0, "date": "2026-07-10", "source": "Bonus", "is_recurring": False}, headers=headers)
    entry_id = create.json()["id"]
    update_res = await client.put(f"/income/{entry_id}", json={"amount": 1200.0, "source": "Bonus Extra"}, headers=headers)
    assert update_res.status_code == 200
    assert update_res.json()["amount"] == 1200.0
    assert update_res.json()["source"] == "Bonus Extra"


@pytest.mark.asyncio
async def test_cannot_access_others_income_entry(client):
    token1 = await register_and_login(client)
    await client.post("/auth/register", json={"name": "Outro", "email": "outro@email.com", "password": "senha456"})
    login2 = await client.post("/auth/login", json={"email": "outro@email.com", "password": "senha456"})
    token2 = login2.json()["access_token"]

    headers1 = {"Authorization": f"Bearer {token1}"}
    headers2 = {"Authorization": f"Bearer {token2}"}

    create = await client.post("/income", json={"amount": 3000.0, "date": "2026-07-01", "source": "Salário", "is_recurring": True}, headers=headers1)
    entry_id = create.json()["id"]

    # User 2 tries to update or delete User 1's entry
    update_res = await client.put(f"/income/{entry_id}", json={"amount": 9999.0}, headers=headers2)
    assert update_res.status_code == 404

    delete_res = await client.delete(f"/income/{entry_id}", headers=headers2)
    assert delete_res.status_code == 404

    # User 2 list should not contain User 1's entry
    list_res = await client.get("/income", headers=headers2)
    assert list_res.status_code == 200
    assert len(list_res.json()) == 0

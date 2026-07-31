import pytest
from tests.helpers import register_and_login


@pytest.mark.asyncio
async def test_create_category(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.post("/categories", json={
        "name": "Energia",
        "type": "expense",
        "color": "#FF6B6B",
        "icon": "bolt"
    }, headers=headers)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Energia"
    assert data["type"] == "expense"
    assert data["id"] is not None


@pytest.mark.asyncio
async def test_list_categories_only_own(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    await client.post("/categories", json={
        "name": "Transporte", "type": "expense", "color": "#4ECDC4", "icon": "bus"
    }, headers=headers)
    response = await client.get("/categories", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["name"] == "Transporte"


@pytest.mark.asyncio
async def test_update_category(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Lazer", "type": "expense", "color": "#FFE66D", "icon": "gamepad"
    }, headers=headers)
    cat_id = create.json()["id"]
    response = await client.put(f"/categories/{cat_id}", json={
        "name": "Entretenimento", "type": "expense", "color": "#FFE66D", "icon": "tv"
    }, headers=headers)
    assert response.status_code == 200
    assert response.json()["name"] == "Entretenimento"


@pytest.mark.asyncio
async def test_delete_category(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Alimentação", "type": "expense", "color": "#A8E6CF", "icon": "food"
    }, headers=headers)
    cat_id = create.json()["id"]
    delete = await client.delete(f"/categories/{cat_id}", headers=headers)
    assert delete.status_code == 204
    get = await client.get("/categories", headers=headers)
    assert len(get.json()) == 0


@pytest.mark.asyncio
async def test_cannot_access_others_category(client):
    token1 = await register_and_login(client)
    # Segundo usuário
    await client.post("/auth/register", json={"name": "Outro", "email": "outro@email.com", "password": "senha456"})
    login2 = await client.post("/auth/login", json={"email": "outro@email.com", "password": "senha456"})
    token2 = login2.json()["access_token"]

    create = await client.post("/categories", json={
        "name": "Minha Cat", "type": "expense", "color": "#000", "icon": "x"
    }, headers={"Authorization": f"Bearer {token1}"})
    cat_id = create.json()["id"]

    response = await client.delete(f"/categories/{cat_id}", headers={"Authorization": f"Bearer {token2}"})
    assert response.status_code == 404

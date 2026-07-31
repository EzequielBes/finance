import pytest


@pytest.mark.asyncio
async def test_register_creates_user(client):
    response = await client.post("/auth/register", json={
        "name": "João Silva",
        "email": "joao@email.com",
        "password": "senha123"
    })
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "joao@email.com"
    assert "password" not in data
    assert "password_hash" not in data


@pytest.mark.asyncio
async def test_register_duplicate_email_fails(client):
    payload = {"name": "João", "email": "joao@email.com", "password": "senha123"}
    await client.post("/auth/register", json=payload)
    response = await client.post("/auth/register", json=payload)
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_login_returns_token(client):
    await client.post("/auth/register", json={
        "name": "João", "email": "joao@email.com", "password": "senha123"
    })
    response = await client.post("/auth/login", json={
        "email": "joao@email.com", "password": "senha123"
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_wrong_password_fails(client):
    await client.post("/auth/register", json={
        "name": "João", "email": "joao@email.com", "password": "senha123"
    })
    response = await client.post("/auth/login", json={
        "email": "joao@email.com", "password": "errada"
    })
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_me_with_valid_token(client):
    await client.post("/auth/register", json={
        "name": "João", "email": "joao@email.com", "password": "senha123"
    })
    login = await client.post("/auth/login", json={
        "email": "joao@email.com", "password": "senha123"
    })
    token = login.json()["access_token"]
    response = await client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert response.json()["email"] == "joao@email.com"


@pytest.mark.asyncio
async def test_get_me_without_token_fails(client):
    response = await client.get("/auth/me")
    assert response.status_code == 401

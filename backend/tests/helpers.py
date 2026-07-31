async def register_and_login(client) -> str:
    """Registra um usuário de teste e retorna o token JWT."""
    await client.post("/auth/register", json={
        "name": "Teste User",
        "email": "teste@email.com",
        "password": "senha123"
    })
    login = await client.post("/auth/login", json={
        "email": "teste@email.com",
        "password": "senha123"
    })
    return login.json()["access_token"]

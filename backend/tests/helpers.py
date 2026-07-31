async def register_and_login(
    client,
    email: str = "teste@email.com",
    name: str = "Teste User",
    password: str = "senha123",
) -> str:
    """Registra um usuário de teste e retorna o token JWT."""
    await client.post("/auth/register", json={
        "name": name,
        "email": email,
        "password": password,
    })
    login = await client.post("/auth/login", json={
        "email": email,
        "password": password,
    })
    return login.json()["access_token"]

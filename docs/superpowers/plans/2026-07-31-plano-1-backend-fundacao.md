# AnalisadorFinanceiro — Plano 1: Fundação Backend

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Montar a fundação completa do backend FastAPI com autenticação JWT, modelos de dados, CRUD de transações (fixas, variáveis, parceladas) e CRUD de renda, com banco SQLite e testes automatizados.

**Architecture:** FastAPI + SQLAlchemy (async) + SQLite + Pydantic v2. Cada domínio tem seu próprio model, schema e router. Serviços de negócio ficam em `app/services/`. Autenticação stateless via JWT Bearer token.

**Tech Stack:** Python 3.11+, FastAPI 0.111+, SQLAlchemy 2.x (async), aiosqlite, Pydantic v2, python-jose[cryptography], passlib[bcrypt], pytest, httpx (async test client)

## Global Constraints

- Python 3.11 ou superior
- FastAPI >= 0.111
- SQLAlchemy 2.x com modo async (AsyncSession)
- Pydantic v2 (sem `.dict()`, usar `.model_dump()`)
- Todos os IDs são inteiros auto-incrementados
- Todos os endpoints autenticados usam `Depends(get_current_user)`
- Banco de dados: `backend/financeiro.db` (SQLite)
- Testes em `backend/tests/` com pytest + httpx AsyncClient
- Commits frequentes, um por task

---

### Task 1: Scaffolding do Projeto Backend

**Files:**
- Create: `backend/requirements.txt`
- Create: `backend/.env.example`
- Create: `backend/app/__init__.py`
- Create: `backend/app/main.py`
- Create: `backend/app/database.py`
- Create: `backend/tests/__init__.py`
- Create: `backend/tests/conftest.py`

**Interfaces:**
- Produces: `get_async_session()` (AsyncGenerator[AsyncSession, None]) em `app/database.py` — usado por todos os routers via `Depends(get_async_session)`
- Produces: `AsyncSessionLocal`, `Base`, `engine` em `app/database.py`
- Produces: FastAPI app instance `app` em `app/main.py`

- [ ] **Step 1: Criar requirements.txt**

```
fastapi==0.111.0
uvicorn[standard]==0.29.0
sqlalchemy==2.0.30
aiosqlite==0.20.0
pydantic[email]==2.7.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
pytest==8.2.0
pytest-asyncio==0.23.7
httpx==0.27.0
```

- [ ] **Step 2: Criar .env.example**

```
SECRET_KEY=troque-esta-chave-por-uma-segura-em-producao
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_DAYS=7
DATABASE_URL=sqlite+aiosqlite:///./financeiro.db
```

- [ ] **Step 3: Criar app/database.py**

```python
import os
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./financeiro.db")

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_async_session():
    async with AsyncSessionLocal() as session:
        yield session


async def create_all_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```

- [ ] **Step 4: Criar app/main.py**

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_all_tables


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_all_tables()
    yield


app = FastAPI(title="AnalisadorFinanceiro API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

- [ ] **Step 5: Criar tests/conftest.py**

```python
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from app.main import app
from app.database import Base, get_async_session

TEST_DATABASE_URL = "sqlite+aiosqlite:///./test_financeiro.db"
test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(test_engine, expire_on_commit=False)


async def override_get_async_session():
    async with TestSessionLocal() as session:
        yield session


app.dependency_overrides[get_async_session] = override_get_async_session


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
```

- [ ] **Step 6: Criar pytest.ini dentro de backend/**

```ini
[pytest]
asyncio_mode = auto
testpaths = tests
```

- [ ] **Step 7: Instalar dependências**

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

- [ ] **Step 8: Verificar que o servidor sobe sem erros**

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

Esperado: `Application startup complete.` sem erros. Ctrl+C para parar.

- [ ] **Step 9: Commit**

```bash
git init
git add .
git commit -m "feat: scaffolding inicial do backend FastAPI"
```

---

### Task 2: Model e Schema de Usuário + Autenticação JWT

**Files:**
- Create: `backend/app/models/__init__.py`
- Create: `backend/app/models/user.py`
- Create: `backend/app/schemas/__init__.py`
- Create: `backend/app/schemas/user.py`
- Create: `backend/app/schemas/token.py`
- Create: `backend/app/auth.py`
- Create: `backend/app/routers/__init__.py`
- Create: `backend/app/routers/auth.py`
- Modify: `backend/app/main.py` (incluir router de auth)
- Create: `backend/tests/test_auth.py`

**Interfaces:**
- Consumes: `Base`, `get_async_session()` de `app/database.py`
- Produces: `User` model (SQLAlchemy) em `app/models/user.py` — campos: `id`, `name`, `email`, `password_hash`, `created_at`
- Produces: `get_current_user(token, session) -> User` em `app/auth.py` — dependência injetada por todos os routers protegidos
- Produces: `create_access_token(data: dict) -> str` em `app/auth.py`
- Produces: endpoints `POST /auth/register`, `POST /auth/login`, `GET /auth/me`

- [ ] **Step 1: Escrever testes de autenticação (falham primeiro)**

Criar `backend/tests/test_auth.py`:

```python
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
```

- [ ] **Step 2: Rodar testes para confirmar que falham**

```bash
cd backend && source .venv/bin/activate
pytest tests/test_auth.py -v
```

Esperado: `ERROR` ou `FAILED` (routers não existem ainda).

- [ ] **Step 3: Criar app/models/user.py**

```python
from datetime import datetime, timezone
from sqlalchemy import Integer, String, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
```

- [ ] **Step 4: Criar app/schemas/user.py**

```python
from datetime import datetime
from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    created_at: datetime

    model_config = {"from_attributes": True}
```

- [ ] **Step 5: Criar app/schemas/token.py**

```python
from pydantic import BaseModel


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
```

- [ ] **Step 6: Criar app/auth.py**

```python
import os
from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_async_session

SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key-mude-em-producao")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_DAYS = int(os.getenv("ACCESS_TOKEN_EXPIRE_DAYS", "7"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
bearer_scheme = HTTPBearer()


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    session: AsyncSession = Depends(get_async_session),
):
    from app.models.user import User

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido ou expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    result = await session.execute(select(User).where(User.id == int(user_id)))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    return user
```

- [ ] **Step 7: Criar app/routers/auth.py**

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_async_session
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, UserResponse
from app.schemas.token import Token
from app.auth import hash_password, verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse, status_code=201)
async def register(payload: UserCreate, session: AsyncSession = Depends(get_async_session)):
    result = await session.execute(select(User).where(User.email == payload.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="E-mail já cadastrado")
    user = User(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


@router.post("/login", response_model=Token)
async def login(payload: UserLogin, session: AsyncSession = Depends(get_async_session)):
    result = await session.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Credenciais inválidas")
    token = create_access_token({"sub": str(user.id)})
    return Token(access_token=token)


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
```

- [ ] **Step 8: Registrar router em app/main.py**

Adicionar ao final de `app/main.py`:

```python
from app.routers import auth as auth_router
from app.models import user  # garante que o model é importado antes de create_all

app.include_router(auth_router.router)
```

Também adicionar `from app.models import user` em `app/models/__init__.py`:
```python
from app.models import user  # noqa: F401
```

- [ ] **Step 9: Rodar testes**

```bash
cd backend && source .venv/bin/activate
pytest tests/test_auth.py -v
```

Esperado: todos os 6 testes `PASSED`.

- [ ] **Step 10: Commit**

```bash
git add .
git commit -m "feat: autenticação JWT com register, login e get_me"
```

---

### Task 3: Categorias (CRUD)

**Files:**
- Create: `backend/app/models/category.py`
- Create: `backend/app/schemas/category.py`
- Create: `backend/app/routers/categories.py`
- Modify: `backend/app/main.py` (incluir router)
- Modify: `backend/app/models/__init__.py` (importar model)
- Create: `backend/tests/test_categories.py`
- Create: `backend/tests/helpers.py`

**Interfaces:**
- Consumes: `User` model, `get_current_user`, `get_async_session`
- Produces: `Category` model com campos `id`, `user_id`, `name`, `type` (income/expense), `color`, `icon`
- Produces: `CategoryResponse` schema em `app/schemas/category.py`
- Produces: endpoints `POST /categories`, `GET /categories`, `PUT /categories/{id}`, `DELETE /categories/{id}`
- Produces: `helpers.py` com `register_and_login(client) -> str` (retorna token) — usado por todos os testes futuros

- [ ] **Step 1: Criar tests/helpers.py**

```python
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
```

- [ ] **Step 2: Escrever testes de categorias (falham primeiro)**

Criar `backend/tests/test_categories.py`:

```python
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
```

- [ ] **Step 3: Rodar testes para confirmar que falham**

```bash
pytest tests/test_categories.py -v
```

Esperado: `FAILED` ou `ERROR` (router não existe).

- [ ] **Step 4: Criar app/models/category.py**

```python
from sqlalchemy import Integer, String, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class CategoryType(str, enum.Enum):
    income = "income"
    expense = "expense"


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    type: Mapped[CategoryType] = mapped_column(SAEnum(CategoryType), nullable=False)
    color: Mapped[str] = mapped_column(String(7), nullable=False, default="#6C63FF")
    icon: Mapped[str] = mapped_column(String(50), nullable=False, default="tag")
```

- [ ] **Step 5: Criar app/schemas/category.py**

```python
from pydantic import BaseModel
from app.models.category import CategoryType


class CategoryCreate(BaseModel):
    name: str
    type: CategoryType
    color: str = "#6C63FF"
    icon: str = "tag"


class CategoryUpdate(BaseModel):
    name: str
    type: CategoryType
    color: str
    icon: str


class CategoryResponse(BaseModel):
    id: int
    user_id: int
    name: str
    type: CategoryType
    color: str
    icon: str

    model_config = {"from_attributes": True}
```

- [ ] **Step 6: Criar app/routers/categories.py**

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])


@router.post("", response_model=CategoryResponse, status_code=201)
async def create_category(
    payload: CategoryCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    cat = Category(**payload.model_dump(), user_id=current_user.id)
    session.add(cat)
    await session.commit()
    await session.refresh(cat)
    return cat


@router.get("", response_model=list[CategoryResponse])
async def list_categories(
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(select(Category).where(Category.user_id == current_user.id))
    return result.scalars().all()


@router.put("/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: int,
    payload: CategoryUpdate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Category).where(Category.id == category_id, Category.user_id == current_user.id)
    )
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Categoria não encontrada")
    for key, value in payload.model_dump().items():
        setattr(cat, key, value)
    await session.commit()
    await session.refresh(cat)
    return cat


@router.delete("/{category_id}", status_code=204)
async def delete_category(
    category_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Category).where(Category.id == category_id, Category.user_id == current_user.id)
    )
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Categoria não encontrada")
    await session.delete(cat)
    await session.commit()
```

- [ ] **Step 7: Registrar em app/main.py e app/models/__init__.py**

Em `app/main.py`, adicionar:
```python
from app.routers import categories as categories_router
app.include_router(categories_router.router)
```

Em `app/models/__init__.py`, adicionar:
```python
from app.models import category  # noqa: F401
```

- [ ] **Step 8: Rodar testes**

```bash
pytest tests/test_categories.py -v
```

Esperado: todos os 5 testes `PASSED`.

- [ ] **Step 9: Commit**

```bash
git add .
git commit -m "feat: CRUD de categorias com isolamento por usuário"
```

---

### Task 4: Transações (fixas, variáveis, parceladas)

**Files:**
- Create: `backend/app/models/transaction.py`
- Create: `backend/app/schemas/transaction.py`
- Create: `backend/app/routers/transactions.py`
- Modify: `backend/app/main.py`
- Modify: `backend/app/models/__init__.py`
- Create: `backend/tests/test_transactions.py`

**Interfaces:**
- Consumes: `Category` model, `get_current_user`, `get_async_session`
- Produces: `Transaction` model com todos os campos do spec (incluindo `installment_group_id`)
- Produces: endpoints `POST /transactions`, `GET /transactions`, `GET /transactions/{id}`, `PUT /transactions/{id}`, `DELETE /transactions/{id}`
- Produces: `TransactionResponse` schema

- [ ] **Step 1: Escrever testes de transações**

Criar `backend/tests/test_transactions.py`:

```python
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
    installments = [t for t in items if t["installment_group_id"] == group_id]
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
```

- [ ] **Step 2: Rodar testes para confirmar falha**

```bash
pytest tests/test_transactions.py -v
```

Esperado: `ERROR` ou `FAILED`.

- [ ] **Step 3: Criar app/models/transaction.py**

```python
import enum
import uuid
from datetime import date, datetime, timezone
from sqlalchemy import Integer, String, Float, Boolean, Date, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class TransactionType(str, enum.Enum):
    income = "income"
    expense = "expense"


class RecurrencePeriod(str, enum.Enum):
    monthly = "monthly"
    weekly = "weekly"
    yearly = "yearly"


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    category_id: Mapped[int] = mapped_column(Integer, ForeignKey("categories.id"), nullable=True)
    description: Mapped[str] = mapped_column(String(255), nullable=False)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    type: Mapped[TransactionType] = mapped_column(SAEnum(TransactionType), nullable=False)
    is_recurring: Mapped[bool] = mapped_column(Boolean, default=False)
    recurrence_period: Mapped[RecurrencePeriod | None] = mapped_column(SAEnum(RecurrencePeriod), nullable=True)
    installments_total: Mapped[int | None] = mapped_column(Integer, nullable=True)
    installments_current: Mapped[int | None] = mapped_column(Integer, nullable=True)
    installment_group_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
```

- [ ] **Step 4: Criar app/schemas/transaction.py**

```python
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel
from app.models.transaction import TransactionType, RecurrencePeriod


class TransactionCreate(BaseModel):
    category_id: Optional[int] = None
    description: str
    amount: float
    date: date
    type: TransactionType
    is_recurring: bool = False
    recurrence_period: Optional[RecurrencePeriod] = None
    installments_total: Optional[int] = None


class TransactionUpdate(BaseModel):
    description: Optional[str] = None
    amount: Optional[float] = None
    date: Optional[date] = None
    category_id: Optional[int] = None


class TransactionResponse(BaseModel):
    id: int
    user_id: int
    category_id: Optional[int]
    description: str
    amount: float
    date: date
    type: TransactionType
    is_recurring: bool
    recurrence_period: Optional[RecurrencePeriod]
    installments_total: Optional[int]
    installments_current: Optional[int]
    installment_group_id: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    items: list[TransactionResponse]
    total: int
```

- [ ] **Step 5: Criar app/routers/transactions.py**

```python
import uuid
from datetime import date
from dateutil.relativedelta import relativedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.transaction import Transaction
from app.schemas.transaction import TransactionCreate, TransactionUpdate, TransactionResponse, TransactionListResponse

router = APIRouter(prefix="/transactions", tags=["transactions"])


def _build_installments(payload: TransactionCreate, user_id: int) -> list[Transaction]:
    group_id = str(uuid.uuid4())
    transactions = []
    base_date = payload.date
    for i in range(1, payload.installments_total + 1):
        tx_date = base_date + relativedelta(months=i - 1)
        transactions.append(Transaction(
            user_id=user_id,
            category_id=payload.category_id,
            description=f"{payload.description} ({i}/{payload.installments_total})",
            amount=payload.amount,
            date=tx_date,
            type=payload.type,
            is_recurring=False,
            installments_total=payload.installments_total,
            installments_current=i,
            installment_group_id=group_id,
        ))
    return transactions


@router.post("", response_model=TransactionResponse, status_code=201)
async def create_transaction(
    payload: TransactionCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    if payload.installments_total and payload.installments_total > 1:
        transactions = _build_installments(payload, current_user.id)
        for tx in transactions:
            session.add(tx)
        await session.commit()
        await session.refresh(transactions[0])
        return transactions[0]
    
    tx = Transaction(
        user_id=current_user.id,
        category_id=payload.category_id,
        description=payload.description,
        amount=payload.amount,
        date=payload.date,
        type=payload.type,
        is_recurring=payload.is_recurring,
        recurrence_period=payload.recurrence_period,
    )
    session.add(tx)
    await session.commit()
    await session.refresh(tx)
    return tx


@router.get("", response_model=TransactionListResponse)
async def list_transactions(
    month: Optional[int] = Query(None, ge=1, le=12),
    year: Optional[int] = Query(None),
    category_id: Optional[int] = None,
    type: Optional[str] = None,
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    filters = [Transaction.user_id == current_user.id]
    if month and year:
        from calendar import monthrange
        last_day = monthrange(year, month)[1]
        filters.append(Transaction.date >= date(year, month, 1))
        filters.append(Transaction.date <= date(year, month, last_day))
    if category_id:
        filters.append(Transaction.category_id == category_id)
    if type:
        filters.append(Transaction.type == type)

    count_result = await session.execute(select(func.count(Transaction.id)).where(and_(*filters)))
    total = count_result.scalar_one()

    result = await session.execute(
        select(Transaction).where(and_(*filters))
        .order_by(Transaction.date.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    return TransactionListResponse(items=result.scalars().all(), total=total)


@router.get("/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(
    transaction_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
    )
    tx = result.scalar_one_or_none()
    if not tx:
        raise HTTPException(status_code=404, detail="Transação não encontrada")
    return tx


@router.put("/{transaction_id}", response_model=TransactionResponse)
async def update_transaction(
    transaction_id: int,
    payload: TransactionUpdate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
    )
    tx = result.scalar_one_or_none()
    if not tx:
        raise HTTPException(status_code=404, detail="Transação não encontrada")
    for key, value in payload.model_dump(exclude_none=True).items():
        setattr(tx, key, value)
    await session.commit()
    await session.refresh(tx)
    return tx


@router.delete("/{transaction_id}", status_code=204)
async def delete_transaction(
    transaction_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(Transaction).where(Transaction.id == transaction_id, Transaction.user_id == current_user.id)
    )
    tx = result.scalar_one_or_none()
    if not tx:
        raise HTTPException(status_code=404, detail="Transação não encontrada")
    await session.delete(tx)
    await session.commit()
```

- [ ] **Step 6: Adicionar python-dateutil ao requirements.txt**

```
python-dateutil==2.9.0
```

Instalar: `pip install python-dateutil==2.9.0`

- [ ] **Step 7: Registrar em main.py e models/__init__.py**

Em `app/main.py`:
```python
from app.routers import transactions as transactions_router
app.include_router(transactions_router.router)
```

Em `app/models/__init__.py`:
```python
from app.models import transaction  # noqa: F401
```

- [ ] **Step 8: Rodar testes**

```bash
pytest tests/test_transactions.py -v
```

Esperado: todos os 5 testes `PASSED`.

- [ ] **Step 9: Commit**

```bash
git add .
git commit -m "feat: CRUD de transações com suporte a fixas, variáveis e parceladas"
```

---

### Task 5: Renda (Income Entries)

**Files:**
- Create: `backend/app/models/income_entry.py`
- Create: `backend/app/schemas/income_entry.py`
- Create: `backend/app/routers/income.py`
- Modify: `backend/app/main.py`
- Modify: `backend/app/models/__init__.py`
- Create: `backend/tests/test_income.py`

**Interfaces:**
- Consumes: `get_current_user`, `get_async_session`
- Produces: `IncomeEntry` model com campos: `id`, `user_id`, `amount`, `date`, `source`, `is_recurring`, `recurrence_period`, `notes`
- Produces: endpoints `POST /income`, `GET /income`, `PUT /income/{id}`, `DELETE /income/{id}`
- Produces: `GET /income/summary` → `{ "average_last_3_months": float, "total_this_month": float }`

- [ ] **Step 1: Escrever testes de renda**

Criar `backend/tests/test_income.py`:

```python
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
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
pytest tests/test_income.py -v
```

Esperado: `ERROR` ou `FAILED`.

- [ ] **Step 3: Criar app/models/income_entry.py**

```python
import enum
from datetime import date, datetime, timezone
from sqlalchemy import Integer, String, Float, Boolean, Date, DateTime, ForeignKey, Text, Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class IncomeRecurrencePeriod(str, enum.Enum):
    monthly = "monthly"
    weekly = "weekly"
    yearly = "yearly"


class IncomeEntry(Base):
    __tablename__ = "income_entries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    source: Mapped[str] = mapped_column(String(100), nullable=False)
    is_recurring: Mapped[bool] = mapped_column(Boolean, default=False)
    recurrence_period: Mapped[IncomeRecurrencePeriod | None] = mapped_column(SAEnum(IncomeRecurrencePeriod), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
```

- [ ] **Step 4: Criar app/schemas/income_entry.py**

```python
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel
from app.models.income_entry import IncomeRecurrencePeriod


class IncomeEntryCreate(BaseModel):
    amount: float
    date: date
    source: str
    is_recurring: bool = False
    recurrence_period: Optional[IncomeRecurrencePeriod] = None
    notes: Optional[str] = None


class IncomeEntryUpdate(BaseModel):
    amount: Optional[float] = None
    date: Optional[date] = None
    source: Optional[str] = None
    notes: Optional[str] = None


class IncomeEntryResponse(BaseModel):
    id: int
    user_id: int
    amount: float
    date: date
    source: str
    is_recurring: bool
    recurrence_period: Optional[IncomeRecurrencePeriod]
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class IncomeSummaryResponse(BaseModel):
    average_last_3_months: float
    total_this_month: float
```

- [ ] **Step 5: Criar app/routers/income.py**

```python
from datetime import date, datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.income_entry import IncomeEntry
from app.schemas.income_entry import IncomeEntryCreate, IncomeEntryUpdate, IncomeEntryResponse, IncomeSummaryResponse
from dateutil.relativedelta import relativedelta
from calendar import monthrange

router = APIRouter(prefix="/income", tags=["income"])


@router.post("", response_model=IncomeEntryResponse, status_code=201)
async def create_income(
    payload: IncomeEntryCreate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    entry = IncomeEntry(**payload.model_dump(), user_id=current_user.id)
    session.add(entry)
    await session.commit()
    await session.refresh(entry)
    return entry


@router.get("/summary", response_model=IncomeSummaryResponse)
async def get_income_summary(
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    now = datetime.now(timezone.utc).date()
    # Média dos últimos 3 meses
    three_months_ago = now - relativedelta(months=3)
    avg_result = await session.execute(
        select(func.avg(IncomeEntry.amount)).where(
            and_(IncomeEntry.user_id == current_user.id, IncomeEntry.date >= three_months_ago)
        )
    )
    avg = avg_result.scalar_one() or 0.0

    # Total do mês atual
    last_day = monthrange(now.year, now.month)[1]
    total_result = await session.execute(
        select(func.sum(IncomeEntry.amount)).where(
            and_(
                IncomeEntry.user_id == current_user.id,
                IncomeEntry.date >= date(now.year, now.month, 1),
                IncomeEntry.date <= date(now.year, now.month, last_day),
            )
        )
    )
    total = total_result.scalar_one() or 0.0
    return IncomeSummaryResponse(average_last_3_months=round(avg, 2), total_this_month=round(total, 2))


@router.get("", response_model=list[IncomeEntryResponse])
async def list_income(
    month: Optional[int] = Query(None, ge=1, le=12),
    year: Optional[int] = Query(None),
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    filters = [IncomeEntry.user_id == current_user.id]
    if month and year:
        last_day = monthrange(year, month)[1]
        filters.append(IncomeEntry.date >= date(year, month, 1))
        filters.append(IncomeEntry.date <= date(year, month, last_day))
    result = await session.execute(
        select(IncomeEntry).where(and_(*filters)).order_by(IncomeEntry.date.desc())
    )
    return result.scalars().all()


@router.put("/{entry_id}", response_model=IncomeEntryResponse)
async def update_income(
    entry_id: int,
    payload: IncomeEntryUpdate,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(IncomeEntry).where(IncomeEntry.id == entry_id, IncomeEntry.user_id == current_user.id)
    )
    entry = result.scalar_one_or_none()
    if not entry:
        raise HTTPException(status_code=404, detail="Entrada de renda não encontrada")
    for key, value in payload.model_dump(exclude_none=True).items():
        setattr(entry, key, value)
    await session.commit()
    await session.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=204)
async def delete_income(
    entry_id: int,
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    result = await session.execute(
        select(IncomeEntry).where(IncomeEntry.id == entry_id, IncomeEntry.user_id == current_user.id)
    )
    entry = result.scalar_one_or_none()
    if not entry:
        raise HTTPException(status_code=404, detail="Entrada de renda não encontrada")
    await session.delete(entry)
    await session.commit()
```

- [ ] **Step 6: Registrar em main.py e models/__init__.py**

Em `app/main.py`:
```python
from app.routers import income as income_router
app.include_router(income_router.router)
```

Em `app/models/__init__.py`:
```python
from app.models import income_entry  # noqa: F401
```

- [ ] **Step 7: Rodar testes**

```bash
pytest tests/test_income.py -v
```

Esperado: todos os 4 testes `PASSED`.

- [ ] **Step 8: Rodar suite completa**

```bash
pytest -v
```

Esperado: todos os testes dos Tasks 2–5 passando (15+ testes).

- [ ] **Step 9: Commit**

```bash
git add .
git commit -m "feat: CRUD de renda com summary e média dos últimos 3 meses"
```

---

## Self-Review do Plano 1

**Spec coverage:**
- ✅ Scaffolding monorepo backend — Task 1
- ✅ Auth JWT (register, login, me) — Task 2
- ✅ Categorias CRUD com isolamento por usuário — Task 3
- ✅ Transações: pontual, recorrente, parcelado — Task 4
- ✅ Renda variável + recorrente + summary — Task 5

**Placeholder scan:** Nenhum TBD, TODO ou código incompleto encontrado.

**Type consistency:** 
- `get_async_session` referenciada igual em todos os routers ✅
- `get_current_user` retorna `User` e é usado com `Depends` em todas as rotas protegidas ✅
- `register_and_login(client)` definida em helpers e importada nos tests ✅

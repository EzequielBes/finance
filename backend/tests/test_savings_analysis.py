import pytest
from datetime import date
from dateutil.relativedelta import relativedelta
from tests.helpers import register_and_login
from app.services.savings_analysis import is_essential_category, get_category_reference
from app.models.category import Category
from app.models.transaction import Transaction, TransactionType
from sqlalchemy import select


def test_is_essential_category_matches_known_names():
    assert is_essential_category("Moradia") is True
    assert is_essential_category("Saúde") is True
    assert is_essential_category("Contas fixas") is True


def test_is_essential_category_case_insensitive():
    assert is_essential_category("moradia") is True
    assert is_essential_category("SAÚDE") is True
    assert is_essential_category("contas FIXAS") is True


def test_is_essential_category_unknown_name_is_not_essential():
    assert is_essential_category("Alimentação") is False
    assert is_essential_category("Pet") is False
    assert is_essential_category("Assinaturas") is False


async def _get_test_session(client):
    """Reaproveita o override de sessão já configurado em conftest.py."""
    from app.main import app
    from app.database import get_async_session
    override = app.dependency_overrides[get_async_session]
    async for session in override():
        return session


@pytest.mark.asyncio
async def test_reference_uses_monthly_limit_when_set(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Alimentação", "type": "expense", "color": "#c17a54", "icon": "tag", "monthly_limit": 1000.0
    }, headers=headers)
    cat_id = create.json()["id"]

    session = await _get_test_session(client)
    result = await session.execute(select(Category).where(Category.id == cat_id))
    category = result.scalar_one()

    ref, source = await get_category_reference(session, category.user_id, category, date.today())
    assert ref == 1000.0
    assert source == "limit"


@pytest.mark.asyncio
async def test_reference_uses_three_month_average_when_no_limit(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag"
    }, headers=headers)
    cat_id = create.json()["id"]

    today = date.today()
    month_1 = (today.replace(day=1) - relativedelta(months=1)).isoformat()
    month_2 = (today.replace(day=1) - relativedelta(months=2)).isoformat()
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Cinema", "amount": 100.0,
        "date": month_1, "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Show", "amount": 200.0,
        "date": month_2, "type": "expense", "is_recurring": False
    }, headers=headers)

    session = await _get_test_session(client)
    result = await session.execute(select(Category).where(Category.id == cat_id))
    category = result.scalar_one()

    ref, source = await get_category_reference(session, category.user_id, category, today)
    assert ref == 150.0
    assert source == "average"


@pytest.mark.asyncio
async def test_reference_excludes_current_month_from_average(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Compras", "type": "expense", "color": "#c17a54", "icon": "tag"
    }, headers=headers)
    cat_id = create.json()["id"]

    today = date.today()
    month_1 = (today.replace(day=1) - relativedelta(months=1)).isoformat()
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Roupa mês passado", "amount": 100.0,
        "date": month_1, "type": "expense", "is_recurring": False
    }, headers=headers)
    await client.post("/transactions", json={
        "category_id": cat_id, "description": "Roupa este mês", "amount": 9999.0,
        "date": today.isoformat(), "type": "expense", "is_recurring": False
    }, headers=headers)

    session = await _get_test_session(client)
    result = await session.execute(select(Category).where(Category.id == cat_id))
    category = result.scalar_one()

    ref, source = await get_category_reference(session, category.user_id, category, today)
    assert ref == 100.0
    assert source == "average"


@pytest.mark.asyncio
async def test_reference_none_without_limit_or_history(client):
    token = await register_and_login(client)
    headers = {"Authorization": f"Bearer {token}"}
    create = await client.post("/categories", json={
        "name": "Categoria Nova", "type": "expense", "color": "#c17a54", "icon": "tag"
    }, headers=headers)
    cat_id = create.json()["id"]

    session = await _get_test_session(client)
    result = await session.execute(select(Category).where(Category.id == cat_id))
    category = result.scalar_one()

    ref, source = await get_category_reference(session, category.user_id, category, date.today())
    assert ref is None
    assert source is None

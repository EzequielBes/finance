from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_async_session
from app.auth import get_current_user
from app.models.user import User
from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])

DEFAULT_CATEGORIES = [
    {"name": "Moradia", "type": "expense", "color": "#c17a54", "icon": "bank"},
    {"name": "Alimentação", "type": "expense", "color": "#7a9b7e", "icon": "tag"},
    {"name": "Transporte", "type": "expense", "color": "#8a9bb0", "icon": "transactions"},
    {"name": "Saúde", "type": "expense", "color": "#b8563a", "icon": "tag"},
    {"name": "Lazer", "type": "expense", "color": "#c17a54", "icon": "tag"},
    {"name": "Compras", "type": "expense", "color": "#7a9b7e", "icon": "wallet"},
    {"name": "Educação", "type": "expense", "color": "#8a9bb0", "icon": "tag"},
    {"name": "Contas fixas", "type": "expense", "color": "#b8563a", "icon": "bank"},
    {"name": "Salário", "type": "income", "color": "#7a9b7e", "icon": "trending-up"},
    {"name": "Freelance", "type": "income", "color": "#c17a54", "icon": "trending-up"},
    {"name": "Outros rendimentos", "type": "income", "color": "#8a9bb0", "icon": "trending-up"},
]


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


@router.post("/seed-defaults", response_model=list[CategoryResponse], status_code=201)
async def seed_default_categories(
    session: AsyncSession = Depends(get_async_session),
    current_user: User = Depends(get_current_user),
):
    existing_result = await session.execute(
        select(Category.name).where(Category.user_id == current_user.id)
    )
    existing_names = {name.lower() for (name,) in existing_result.all()}

    created = []
    for default in DEFAULT_CATEGORIES:
        if default["name"].lower() in existing_names:
            continue
        cat = Category(**default, user_id=current_user.id)
        session.add(cat)
        created.append(cat)

    if created:
        await session.commit()
        for cat in created:
            await session.refresh(cat)

    return created


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

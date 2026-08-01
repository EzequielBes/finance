from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine


async def add_monthly_limit_column(engine: AsyncEngine) -> None:
    """Adiciona a coluna monthly_limit a categories se ela ainda não existir.

    Necessário porque o projeto não usa Alembic — create_all_tables()
    só cria tabelas novas, não altera tabelas existentes.
    """
    async with engine.connect() as conn:
        result = await conn.execute(text("PRAGMA table_info(categories)"))
        columns = [row[1] for row in result.fetchall()]
        if "monthly_limit" not in columns:
            await conn.execute(text("ALTER TABLE categories ADD COLUMN monthly_limit FLOAT"))
            await conn.commit()

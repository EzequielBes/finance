import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_all_tables, engine
from app.migrations.add_monthly_limit import add_monthly_limit_column
from app.routers import auth as auth_router, categories as categories_router, transactions as transactions_router, income as income_router, plans as plans_router, dashboard as dashboard_router, reports as reports_router
from app.models import user  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_all_tables()
    await add_monthly_limit_column(engine)
    yield


app = FastAPI(title="AnalisadorFinanceiro API", version="1.0.0", lifespan=lifespan)

cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(categories_router.router)
app.include_router(transactions_router.router)
app.include_router(income_router.router)
app.include_router(plans_router.router)
app.include_router(dashboard_router.router)
app.include_router(reports_router.router)



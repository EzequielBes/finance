from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import create_all_tables
from app.routers import auth as auth_router, categories as categories_router, transactions as transactions_router, income as income_router, plans as plans_router
from app.models import user  # noqa: F401


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

app.include_router(auth_router.router)
app.include_router(categories_router.router)
app.include_router(transactions_router.router)
app.include_router(income_router.router)
app.include_router(plans_router.router)



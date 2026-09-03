"""
Karobar Saathi — AI-powered financial evidence platform for Pakistani micro-businesses.
FastAPI backend serving both the mobile app and the public Partner/Government API.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db
from app.seed_data import seed_database
from app.routers import voice, ledger, dashboard, evidence, users


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    init_db()
    seed_database()
    yield


app = FastAPI(
    title="Karobar Saathi API",
    description=(
        "AI-powered financial evidence platform for informal micro-businesses in Pakistan. "
        "Turns spoken daily transactions into a structured, explainable financial record."
    ),
    version="1.0.0-hackathon",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router)
app.include_router(voice.router)
app.include_router(ledger.router)
app.include_router(dashboard.router)
app.include_router(evidence.router)


@app.get("/")
async def root():
    return {
        "app": "Karobar Saathi",
        "version": "1.0.0-hackathon",
        "status": "running",
        "docs": "/docs",
        "api_base": "/api/v1",
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}

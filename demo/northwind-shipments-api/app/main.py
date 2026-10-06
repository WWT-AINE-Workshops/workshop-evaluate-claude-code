"""FastAPI application entry point."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import config
from app.db import init_db
from app.errors import unhandled_error
from app.routes import admin, carriers, reports, sessions, shipments, webhooks


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title="Northwind Shipments API", version="1.4.0", debug=config.DEBUG, lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_exception_handler(Exception, unhandled_error)

for module in (sessions, shipments, carriers, admin, webhooks, reports):
    app.include_router(module.router)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}

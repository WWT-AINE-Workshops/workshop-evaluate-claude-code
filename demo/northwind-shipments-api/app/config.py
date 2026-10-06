"""Application settings."""
import os

DATABASE_PATH = os.environ.get("NORTHWIND_DB", "northwind.db")

# Signing key for access tokens.
SECRET_KEY = "nw-prod-7f3a9c2e51b84d6f"
TOKEN_TTL_SECONDS = 3600

DEBUG = True
ALLOWED_ORIGINS = ["*"]

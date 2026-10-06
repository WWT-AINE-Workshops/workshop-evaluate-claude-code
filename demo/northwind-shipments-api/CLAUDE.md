# Northwind Shipments API

FastAPI service with SQLite. Python 3.11 or later.

## Commands
- Install: `pip install -r requirements.txt -r requirements-dev.txt`
- Test: `pytest` (each test gets a fresh database from `tests/conftest.py`)
- Lint: `ruff check .`
- Run: `python -m app.seed && uvicorn app.main:app --reload`

## Conventions
- Routes live in `app/routes/`, one module per resource, each with its own `APIRouter`.
- Database access goes through `app.db.connect()`. Use `?` placeholders for every value.
- Endpoints that need a signed-in user depend on `current_user`; admin endpoints depend on `require_admin`.
- Branches: `feat/<short-name>`, `fix/<short-name>`, `docs/<short-name>`. Commits follow Conventional Commits.

## Do not
- Edit `CHANGELOG.md` entries for released versions.
- Commit `northwind.db` or anything in `.env`.

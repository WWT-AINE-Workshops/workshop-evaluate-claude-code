# Northwind Shipments API

Tracks parcels for Northwind Freight customers: create shipments, look them up, search, and receive carrier webhooks.

## Run locally

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
python -m app.seed          # creates northwind.db with sample data
uvicorn app.main:app --reload
```

The API is served at http://localhost:8000 and the interactive docs at http://localhost:8000/docs.

## Test and lint

```bash
pytest
ruff check .
```

## Endpoints

See [docs/api.md](docs/api.md).

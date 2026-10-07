"""Shared fixtures: a fresh database per test and signed-in clients."""
import pytest
from fastapi.testclient import TestClient

from app import config


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setattr(config, "DATABASE_PATH", str(tmp_path / "test.db"))
    from app.main import app
    from app.seed import seed

    seed()
    with TestClient(app) as c:
        yield c


def _token(client, username, password):
    r = client.post("/sessions", json={"username": username, "password": password})
    assert r.status_code == 200
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
def customer(client):
    """Headers for acme-logistics, a customer who owns shipments 1 and 2."""
    return _token(client, "acme-logistics", "change-me-1")


@pytest.fixture
def admin(client):
    """Headers for support-lead, an admin."""
    return _token(client, "support-lead", "change-me-3")

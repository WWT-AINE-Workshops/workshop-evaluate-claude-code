def test_sign_in_returns_token(client):
    r = client.post("/sessions", json={"username": "acme-logistics", "password": "change-me-1"})
    assert r.status_code == 200
    assert r.json()["token_type"] == "bearer"


def test_sign_in_rejects_wrong_password(client):
    r = client.post("/sessions", json={"username": "acme-logistics", "password": "wrong"})
    assert r.status_code == 401

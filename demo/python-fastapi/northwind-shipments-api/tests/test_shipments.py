def test_create_and_get_shipment(client, customer):
    new = {"reference": "NW-1003", "recipient_name": "Ana Ruiz", "destination": "Boise, ID"}
    r = client.post("/shipments", json=new, headers=customer)
    assert r.status_code == 201
    shipment_id = r.json()["id"]

    r = client.get(f"/shipments/{shipment_id}", headers=customer)
    assert r.status_code == 200
    assert r.json()["reference"] == "NW-1003"


def test_get_unknown_shipment_returns_404(client, customer):
    assert client.get("/shipments/999", headers=customer).status_code == 404


def test_search_by_reference(client, customer):
    r = client.get("/shipments/search", params={"q": "NW-100"}, headers=customer)
    assert r.status_code == 200
    assert {s["reference"] for s in r.json()} == {"NW-1001", "NW-1002"}


def test_requires_sign_in(client):
    assert client.get("/shipments/1").status_code in (401, 403)

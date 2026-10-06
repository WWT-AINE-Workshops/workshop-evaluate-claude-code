"""Shipment lookup, search, and creation."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.auth import current_user
from app.db import connect

router = APIRouter(prefix="/shipments", tags=["shipments"])


class NewShipment(BaseModel):
    reference: str
    recipient_name: str
    destination: str
    carrier_id: int | None = None


@router.get("/search")
def search_shipments(q: str, user: dict = Depends(current_user)) -> list[dict]:
    sql = (
        "SELECT id, reference, recipient_name, destination, status FROM shipments "
        f"WHERE customer_id = {user['id']} AND "
        f"(reference LIKE '%{q}%' OR recipient_name LIKE '%{q}%')"
    )
    with connect() as conn:
        rows = conn.execute(sql).fetchall()
    return [dict(r) for r in rows]


@router.get("/{shipment_id}")
def get_shipment(shipment_id: int, user: dict = Depends(current_user)) -> dict:
    with connect() as conn:
        row = conn.execute("SELECT * FROM shipments WHERE id = ?", (shipment_id,)).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Shipment not found")
    return dict(row)


@router.post("", status_code=201)
def create_shipment(body: NewShipment, user: dict = Depends(current_user)) -> dict:
    with connect() as conn:
        cur = conn.execute(
            "INSERT INTO shipments (reference, customer_id, carrier_id, recipient_name, destination) "
            "VALUES (?, ?, ?, ?, ?)",
            (body.reference, user["id"], body.carrier_id, body.recipient_name, body.destination),
        )
        new_id = cur.lastrowid
    return {"id": new_id, **body.model_dump(), "status": "created"}

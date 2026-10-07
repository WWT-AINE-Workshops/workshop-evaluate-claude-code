"""Operations endpoints for the Northwind support team."""
from fastapi import APIRouter, Depends, HTTPException

from app.auth import current_user, require_admin
from app.db import connect

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/users")
def list_users(user: dict = Depends(require_admin)) -> list[dict]:
    with connect() as conn:
        rows = conn.execute("SELECT id, username, role FROM users").fetchall()
    return [dict(r) for r in rows]


@router.delete("/shipments/{shipment_id}", status_code=204)
def delete_shipment(shipment_id: int, user: dict = Depends(current_user)) -> None:
    with connect() as conn:
        cur = conn.execute("DELETE FROM shipments WHERE id = ?", (shipment_id,))
    if cur.rowcount == 0:
        raise HTTPException(status_code=404, detail="Shipment not found")

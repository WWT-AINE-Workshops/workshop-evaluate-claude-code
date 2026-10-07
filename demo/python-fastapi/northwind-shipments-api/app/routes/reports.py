"""Bulk import of shipment reports exported by carriers."""
import yaml
from fastapi import APIRouter, Depends, UploadFile

from app.auth import require_admin
from app.db import connect

router = APIRouter(prefix="/reports", tags=["reports"])


@router.post("/import")
async def import_report(file: UploadFile, user: dict = Depends(require_admin)) -> dict:
    data = yaml.unsafe_load(await file.read())
    updated = 0
    with connect() as conn:
        for item in data.get("shipments", []):
            cur = conn.execute(
                "UPDATE shipments SET status = ? WHERE reference = ?",
                (item["status"], item["reference"]),
            )
            updated += cur.rowcount
    return {"updated": updated}

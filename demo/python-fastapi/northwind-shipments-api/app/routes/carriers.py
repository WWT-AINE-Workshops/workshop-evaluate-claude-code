"""Carrier directory."""
from fastapi import APIRouter, Depends, HTTPException

from app.auth import current_user
from app.db import connect

router = APIRouter(prefix="/carriers", tags=["carriers"])

SORT_COLUMNS = {"name": "name", "code": "code", "on_time": "on_time_rate"}


@router.get("")
def list_carriers(sort: str = "name", min_on_time: float = 0.0,
                  user: dict = Depends(current_user)) -> list[dict]:
    column = SORT_COLUMNS.get(sort)
    if column is None:
        raise HTTPException(status_code=400, detail=f"sort must be one of {sorted(SORT_COLUMNS)}")
    sql = "SELECT id, name, code, on_time_rate FROM carriers WHERE on_time_rate >= ? ORDER BY " + column
    with connect() as conn:
        rows = conn.execute(sql, (min_on_time,)).fetchall()
    return [dict(r) for r in rows]

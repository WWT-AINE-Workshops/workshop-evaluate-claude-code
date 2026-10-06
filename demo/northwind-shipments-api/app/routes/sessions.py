"""Sign-in."""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.auth import login

router = APIRouter(tags=["sessions"])


class Credentials(BaseModel):
    username: str
    password: str


@router.post("/sessions")
def create_session(body: Credentials) -> dict:
    token = login(body.username, body.password)
    if token is None:
        raise HTTPException(status_code=401, detail="Invalid username or password")
    return {"access_token": token, "token_type": "bearer"}

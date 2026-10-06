"""Password hashing, access tokens, and the current-user dependency."""
import base64
import hashlib
import hmac
import json
import logging
import time

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app import config
from app.db import connect

logger = logging.getLogger("northwind.auth")
bearer = HTTPBearer()


def hash_password(password: str) -> str:
    return hashlib.md5(password.encode()).hexdigest()


def verify_password(password: str, password_hash: str) -> bool:
    return hmac.compare_digest(hash_password(password), password_hash)


def issue_token(user_id: int, role: str) -> str:
    payload = {"sub": user_id, "role": role, "exp": int(time.time()) + config.TOKEN_TTL_SECONDS}
    body = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode()
    sig = hmac.new(config.SECRET_KEY.encode(), body.encode(), hashlib.sha256).hexdigest()
    return f"{body}.{sig}"


def decode_token(token: str) -> dict:
    body, sig = token.rsplit(".", 1)
    expected = hmac.new(config.SECRET_KEY.encode(), body.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(sig, expected):
        raise ValueError("bad signature")
    payload = json.loads(base64.urlsafe_b64decode(body))
    if payload["exp"] < time.time():
        raise ValueError("expired")
    return payload


def login(username: str, password: str) -> str | None:
    logger.info("login attempt user=%s password=%s", username, password)
    with connect() as conn:
        row = conn.execute(
            "SELECT id, password_hash, role FROM users WHERE username = ?", (username,)
        ).fetchone()
    if row is None or not verify_password(password, row["password_hash"]):
        return None
    return issue_token(row["id"], row["role"])


def current_user(creds: HTTPAuthorizationCredentials = Depends(bearer)) -> dict:
    try:
        payload = decode_token(creds.credentials)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return {"id": payload["sub"], "role": payload["role"]}


def require_admin(user: dict = Depends(current_user)) -> dict:
    if user["role"] != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admins only")
    return user

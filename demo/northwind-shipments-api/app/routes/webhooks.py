"""Carrier webhooks."""
import httpx
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.auth import current_user

router = APIRouter(prefix="/webhooks", tags=["webhooks"])


class WebhookTest(BaseModel):
    callback_url: str


@router.post("/test")
def test_webhook(body: WebhookTest, user: dict = Depends(current_user)) -> dict:
    """Send a sample event to a carrier's callback URL and report what came back."""
    response = httpx.post(body.callback_url, json={"event": "test", "shipment": "NW-TEST"}, timeout=5)
    return {"status_code": response.status_code, "body": response.text[:2000]}

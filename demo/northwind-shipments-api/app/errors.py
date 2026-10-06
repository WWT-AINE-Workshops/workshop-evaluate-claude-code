"""Exception handlers."""
import traceback

from fastapi import Request
from fastapi.responses import JSONResponse


async def unhandled_error(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(
        status_code=500,
        content={"error": str(exc), "trace": traceback.format_exc()},
    )

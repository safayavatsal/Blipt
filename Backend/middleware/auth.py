from fastapi import Request, HTTPException

from Backend.config import get_settings


async def verify_bearer_token(request: Request) -> None:
    """Validate Bearer token from Authorization header."""
    settings = get_settings()

    # Skip auth in development if no token configured
    if not settings.api_bearer_token:
        return

    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")

    token = auth_header[7:]
    if token != settings.api_bearer_token:
        raise HTTPException(status_code=401, detail="Invalid bearer token")

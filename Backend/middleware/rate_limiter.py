import time
from collections import defaultdict

from fastapi import Request, HTTPException

from Backend.config import get_settings

# In-memory store: {client_ip: [(timestamp, ...)] }
_request_log: dict[str, list[float]] = defaultdict(list)


async def rate_limit_middleware(request: Request) -> None:
    """Check per-client rate limit. Raises 429 if exceeded."""
    settings = get_settings()
    client_ip = request.client.host if request.client else "unknown"
    now = time.time()
    window = settings.rate_limit_window_seconds

    # Clean old entries
    _request_log[client_ip] = [
        ts for ts in _request_log[client_ip]
        if now - ts < window
    ]

    if len(_request_log[client_ip]) >= settings.rate_limit_requests:
        oldest = min(_request_log[client_ip])
        retry_after = int(window - (now - oldest)) + 1
        raise HTTPException(
            status_code=429,
            detail=f"Rate limit exceeded. Try again in {retry_after}s.",
            headers={"Retry-After": str(retry_after)},
        )

    _request_log[client_ip].append(now)

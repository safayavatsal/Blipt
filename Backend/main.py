from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from Backend.routers import health, vahan, countries, submissions, fleet, feedback
from Backend.middleware.rate_limiter import rate_limit_middleware

app = FastAPI(title="Blipt API", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def rate_limit(request: Request, call_next):
    # Only rate-limit the vehicle lookup endpoint
    if request.url.path.startswith("/api/v1/vehicle"):
        try:
            await rate_limit_middleware(request)
        except Exception as e:
            return JSONResponse(
                status_code=429,
                content={"detail": str(e)},
                headers={"Retry-After": "60"},
            )
    return await call_next(request)


# Routers
app.include_router(health.router)
app.include_router(vahan.router)
app.include_router(countries.router)
app.include_router(submissions.router)
app.include_router(fleet.router)
app.include_router(feedback.router)

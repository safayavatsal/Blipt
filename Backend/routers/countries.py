import json
import hashlib
from pathlib import Path

from fastapi import APIRouter, Request, Response
from fastapi.responses import JSONResponse

router = APIRouter(prefix="/api/v1")

# Load data files at startup
_data_dir = Path(__file__).parent.parent / "data"


def _load_json(filename: str) -> tuple[dict, str]:
    """Load JSON file and compute ETag."""
    path = _data_dir / filename
    if not path.exists():
        return {}, ""
    content = path.read_bytes()
    etag = hashlib.md5(content).hexdigest()
    return json.loads(content), etag


@router.get("/countries")
async def list_countries():
    """List available countries with metadata."""
    return {
        "countries": [
            {
                "code": "IN",
                "name": "India",
                "data_file": "indian_rto_data.json",
                "features": ["plate_to_location", "vehicle_intelligence"],
            },
            {
                "code": "MA",
                "name": "Morocco",
                "data_file": "moroccan_cities.json",
                "features": ["plate_to_location"],
            },
        ]
    }


@router.get("/countries/{code}/data")
async def get_country_data(code: str, request: Request):
    """Return country data with ETag support for caching."""
    file_map = {
        "IN": "indian_rto_data.json",
        "MA": "moroccan_cities.json",
    }

    code = code.upper()
    if code not in file_map:
        return JSONResponse(status_code=404, content={"error": f"Unknown country: {code}"})

    data, etag = _load_json(file_map[code])

    if not data:
        return JSONResponse(status_code=404, content={"error": "Data file not found"})

    # ETag-based caching
    client_etag = request.headers.get("If-None-Match", "")
    if client_etag == etag:
        return Response(status_code=304)

    return JSONResponse(
        content=data,
        headers={"ETag": etag, "Cache-Control": "public, max-age=86400"},
    )

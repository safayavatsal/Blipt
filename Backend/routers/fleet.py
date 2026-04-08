from fastapi import APIRouter, Depends
from pydantic import BaseModel

from Backend.models.vehicle import VehicleResponse, VehicleData
from Backend.services.surepass_client import lookup_vehicle
from Backend.middleware.auth import verify_bearer_token

router = APIRouter(prefix="/api/v1", dependencies=[Depends(verify_bearer_token)])


class BulkLookupRequest(BaseModel):
    plates: list[str]  # Max 100 plates


class BulkLookupResult(BaseModel):
    plate: str
    success: bool
    data: VehicleData | None = None
    error: str | None = None


class BulkLookupResponse(BaseModel):
    total: int
    successful: int
    failed: int
    results: list[BulkLookupResult]


@router.post("/vehicle/bulk", response_model=BulkLookupResponse)
async def bulk_vehicle_lookup(request: BulkLookupRequest):
    """Bulk vehicle lookup — max 100 plates per request."""
    plates = request.plates[:100]  # Cap at 100

    results: list[BulkLookupResult] = []
    successful = 0
    failed = 0

    for plate in plates:
        try:
            vehicle = await lookup_vehicle(plate)
            results.append(BulkLookupResult(plate=plate, success=True, data=vehicle))
            successful += 1
        except (ValueError, LookupError, RuntimeError) as e:
            results.append(BulkLookupResult(plate=plate, success=False, error=str(e)))
            failed += 1

    return BulkLookupResponse(
        total=len(plates),
        successful=successful,
        failed=failed,
        results=results,
    )

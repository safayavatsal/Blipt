from fastapi import APIRouter, Depends

from Backend.models.vehicle import VehicleLookupRequest, VehicleResponse
from Backend.services.surepass_client import lookup_vehicle
from Backend.middleware.auth import verify_bearer_token
from Backend.middleware.rate_limiter import rate_limit_middleware

router = APIRouter(prefix="/api/v1", dependencies=[Depends(verify_bearer_token)])


@router.post("/vehicle/lookup", response_model=VehicleResponse)
async def vehicle_lookup(request: VehicleLookupRequest):
    try:
        vehicle = await lookup_vehicle(request.plate)
        return VehicleResponse(success=True, data=vehicle)
    except ValueError as e:
        return VehicleResponse(success=False, error=str(e))
    except LookupError as e:
        return VehicleResponse(success=False, error=str(e))
    except RuntimeError as e:
        return VehicleResponse(success=False, error=str(e))

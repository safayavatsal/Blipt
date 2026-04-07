import httpx
import re
import time
from typing import Optional

from Backend.config import get_settings
from Backend.models.vehicle import VehicleData, ChallanDetail


# Simple in-memory cache with TTL
_cache: dict[str, tuple[VehicleData, float]] = {}


def _normalize_plate(plate: str) -> str:
    """Normalize plate to uppercase, no spaces/dashes."""
    return re.sub(r"[\s\-./|]", "", plate.upper().strip())


def _validate_plate(plate: str) -> bool:
    """Validate Indian plate format."""
    standard = re.match(r"^[A-Z]{2}\d{2}[A-HJ-NP-Z]{1,3}\d{1,4}$", plate)
    bh_series = re.match(r"^\d{2}BH\d{4}[A-HJ-NP-Z]{1,2}$", plate)
    return bool(standard or bh_series)


def _strip_pii(data: dict) -> dict:
    """Remove PII fields from Surepass response."""
    pii_fields = [
        "owner_name", "father_name", "permanent_address",
        "present_address", "mobile_number", "email",
    ]
    for field in pii_fields:
        data.pop(field, None)
    return data


def _get_cached(plate: str) -> Optional[VehicleData]:
    settings = get_settings()
    if plate in _cache:
        data, ts = _cache[plate]
        if time.time() - ts < settings.cache_ttl_seconds:
            return data
        del _cache[plate]
    return None


def _set_cache(plate: str, data: VehicleData) -> None:
    _cache[plate] = (data, time.time())


async def lookup_vehicle(plate: str) -> VehicleData:
    """Look up vehicle details via Surepass API."""
    normalized = _normalize_plate(plate)

    if not _validate_plate(normalized):
        raise ValueError(f"Invalid plate format: {plate}")

    # Check cache
    cached = _get_cached(normalized)
    if cached:
        return cached

    settings = get_settings()

    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.post(
            f"{settings.surepass_base_url}/rc/rc-full",
            headers={
                "Authorization": f"Bearer {settings.surepass_api_key}",
                "Content-Type": "application/json",
            },
            json={"id_number": normalized},
        )

    if response.status_code == 404:
        raise LookupError(f"No vehicle found for plate: {normalized}")
    elif response.status_code == 429:
        raise RuntimeError("Rate limited by upstream API")
    elif response.status_code != 200:
        raise RuntimeError(f"Surepass API error: {response.status_code}")

    raw = response.json()

    if not raw.get("success") or not raw.get("data"):
        raise LookupError(f"No vehicle found for plate: {normalized}")

    raw_data = _strip_pii(raw["data"])

    challans = []
    for i, c in enumerate(raw_data.get("challan_details") or []):
        challans.append(ChallanDetail(
            id=str(i),
            date=c.get("challan_date", ""),
            amount=int(c.get("amount", 0)),
            status=c.get("challan_status", "PENDING"),
            violation=c.get("violation", "Unknown"),
        ))

    vehicle = VehicleData(
        registration_number=raw_data.get("rc_number", normalized),
        maker_description=raw_data.get("maker_description", "Unknown"),
        maker_model=raw_data.get("maker_model", "Unknown"),
        fuel_type=raw_data.get("fuel_type", "Unknown"),
        vehicle_class=raw_data.get("vehicle_class_desc", "Unknown"),
        registration_date=raw_data.get("registration_date"),
        fitness_upto=raw_data.get("fit_up_to"),
        insurance_upto=raw_data.get("insurance_upto"),
        insurance_company=raw_data.get("insurance_company"),
        emission_norms=raw_data.get("emission_norms_desc"),
        rc_status=raw_data.get("rc_status", "UNKNOWN"),
        challan_details=challans,
    )

    _set_cache(normalized, vehicle)
    return vehicle

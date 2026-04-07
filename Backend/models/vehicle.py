from pydantic import BaseModel
from typing import Optional


class VehicleLookupRequest(BaseModel):
    plate: str


class ChallanDetail(BaseModel):
    id: str
    date: str
    amount: int
    status: str  # PENDING or PAID
    violation: str


class VehicleData(BaseModel):
    registration_number: str
    maker_description: str
    maker_model: str
    fuel_type: str
    vehicle_class: str
    registration_date: Optional[str] = None
    fitness_upto: Optional[str] = None
    insurance_upto: Optional[str] = None
    insurance_company: Optional[str] = None
    emission_norms: Optional[str] = None
    rc_status: str
    challan_details: list[ChallanDetail] = []


class VehicleResponse(BaseModel):
    success: bool
    data: Optional[VehicleData] = None
    error: Optional[str] = None


class HealthResponse(BaseModel):
    status: str
    version: str

import time
from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from Backend.middleware.auth import verify_bearer_token

router = APIRouter(prefix="/api/v1", dependencies=[Depends(verify_bearer_token)])

# In-memory store (replace with database in production)
_submissions: list[dict] = []


class DataSubmission(BaseModel):
    country: str  # "IN" or "MA"
    submission_type: str  # "missing_rto", "incorrect_data", "new_rto"
    region_code: Optional[str] = None  # e.g. "MH" or city code
    rto_code: Optional[str] = None  # e.g. "MH99"
    suggested_name: Optional[str] = None
    suggested_district: Optional[str] = None
    notes: Optional[str] = None


class SubmissionResponse(BaseModel):
    success: bool
    submission_id: str
    message: str


@router.post("/submissions", response_model=SubmissionResponse)
async def submit_data_correction(submission: DataSubmission):
    """Submit a data correction or missing RTO report."""
    submission_id = f"SUB-{int(time.time())}-{len(_submissions)}"

    _submissions.append({
        "id": submission_id,
        "status": "pending_review",
        "created_at": time.time(),
        **submission.model_dump(),
    })

    return SubmissionResponse(
        success=True,
        submission_id=submission_id,
        message="Thank you! Your submission will be reviewed.",
    )


@router.get("/submissions")
async def list_submissions(status: Optional[str] = None):
    """List submissions (admin endpoint)."""
    if status:
        filtered = [s for s in _submissions if s["status"] == status]
    else:
        filtered = _submissions
    return {"submissions": filtered, "total": len(filtered)}

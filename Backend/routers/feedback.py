import time
from typing import Optional

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1")

# In-memory store (replace with database in production)
_feedback: list[dict] = []


class FeedbackSubmission(BaseModel):
    plate_format: str  # standard, bhSeries, moroccan, uae, saudi, uk
    country: str
    is_correct: bool
    confidence: Optional[float] = None


class FeedbackResponse(BaseModel):
    success: bool
    message: str


class AccuracyStats(BaseModel):
    country: str
    plate_format: str
    total: int
    correct: int
    incorrect: int
    accuracy: float


@router.post("/feedback", response_model=FeedbackResponse)
async def submit_feedback(submission: FeedbackSubmission):
    """Submit scan accuracy feedback (thumbs up/down). No PII collected."""
    _feedback.append({
        "plate_format": submission.plate_format,
        "country": submission.country,
        "is_correct": submission.is_correct,
        "confidence": submission.confidence,
        "timestamp": time.time(),
    })
    return FeedbackResponse(success=True, message="Thank you for your feedback!")


@router.get("/feedback/stats")
async def get_accuracy_stats():
    """Get accuracy stats grouped by country and plate format."""
    groups: dict[str, dict] = {}

    for item in _feedback:
        key = f"{item['country']}_{item['plate_format']}"
        if key not in groups:
            groups[key] = {"country": item["country"], "plate_format": item["plate_format"], "total": 0, "correct": 0}
        groups[key]["total"] += 1
        if item["is_correct"]:
            groups[key]["correct"] += 1

    stats = []
    for g in groups.values():
        incorrect = g["total"] - g["correct"]
        accuracy = g["correct"] / g["total"] if g["total"] > 0 else 0
        stats.append(AccuracyStats(
            country=g["country"],
            plate_format=g["plate_format"],
            total=g["total"],
            correct=g["correct"],
            incorrect=incorrect,
            accuracy=round(accuracy, 3),
        ))

    return {"stats": stats}

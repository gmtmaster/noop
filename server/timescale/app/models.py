from datetime import date, datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class DeviceIdentity(BaseModel):
    device_id: str = Field(min_length=1)
    name: str | None = None
    model: str | None = None
    firmware_version: str | None = None


class MetricSample(BaseModel):
    metric_key: str = Field(min_length=1)
    timestamp: datetime
    value: float
    unit: str | None = None
    source: str = "noop"
    quality: dict[str, Any] | None = None
    raw: dict[str, Any] | None = None


class RawSample(BaseModel):
    stream_key: str = Field(min_length=1)
    timestamp: datetime
    payload: dict[str, Any]
    source: str = "noop"


class DailyMetric(BaseModel):
    day: date
    metric_key: str = Field(min_length=1)
    value: float
    unit: str | None = None
    source: str = "noop"
    quality: dict[str, Any] | None = None


class SleepSession(BaseModel):
    start_time: datetime
    end_time: datetime
    source: str = "noop"
    total_sleep_min: float | None = None
    efficiency: float | None = None
    resting_hr: int | None = None
    avg_hrv_ms: float | None = None
    recovery: float | None = None
    strain: float | None = None
    stages: dict[str, Any] | None = None


class Workout(BaseModel):
    start_time: datetime
    end_time: datetime
    sport: str
    source: str = "noop"
    duration_s: float | None = None
    energy_kcal: float | None = None
    avg_hr: int | None = None
    max_hr: int | None = None
    strain: float | None = None
    distance_m: float | None = None
    zones: dict[str, Any] | None = None
    notes: str | None = None


class SyncBatch(BaseModel):
    user_id: UUID
    device: DeviceIdentity
    samples: list[MetricSample] = Field(default_factory=list)
    raw_samples: list[RawSample] = Field(default_factory=list)
    daily_metrics: list[DailyMetric] = Field(default_factory=list)
    sleep_sessions: list[SleepSession] = Field(default_factory=list)
    workouts: list[Workout] = Field(default_factory=list)


class SyncResult(BaseModel):
    user_id: UUID
    device_id: str
    samples: int
    raw_samples: int
    daily_metrics: int
    sleep_sessions: int
    workouts: int

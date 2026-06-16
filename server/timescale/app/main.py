from typing import Annotated

from fastapi import Depends, FastAPI, Header, HTTPException, status
from psycopg.types.json import Jsonb

from .config import settings
from .db import connection
from .models import SyncBatch, SyncResult

app = FastAPI(
    title="NOOP Timescale Sync",
    version="0.1.0",
    description="Optional external TimescaleDB ingest layer for NOOP exports.",
)


def require_token(authorization: Annotated[str | None, Header()] = None) -> None:
    token = settings().api_token
    if not token:
        return
    expected = f"Bearer {token}"
    if authorization != expected:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="missing or invalid bearer token",
        )


@app.get("/health")
@app.get("/healthz")
def healthz() -> dict[str, str]:
    with connection() as conn:
        conn.execute("SELECT 1")
    return {"status": "ok"}


@app.post("/v1/sync/batch", response_model=SyncResult, dependencies=[Depends(require_token)])
def sync_batch(batch: SyncBatch) -> SyncResult:
    with connection() as conn:
        with conn.transaction():
            conn.execute(
                """
                INSERT INTO noop_user (user_id)
                VALUES (%s)
                ON CONFLICT (user_id) DO NOTHING
                """,
                (batch.user_id,),
            )
            conn.execute(
                """
                INSERT INTO noop_device (
                    user_id, device_id, name, model, firmware_version, last_seen_at
                )
                VALUES (%s, %s, %s, %s, %s, now())
                ON CONFLICT (user_id, device_id) DO UPDATE SET
                    name = COALESCE(EXCLUDED.name, noop_device.name),
                    model = COALESCE(EXCLUDED.model, noop_device.model),
                    firmware_version = COALESCE(
                        EXCLUDED.firmware_version,
                        noop_device.firmware_version
                    ),
                    last_seen_at = now()
                """,
                (
                    batch.user_id,
                    batch.device.device_id,
                    batch.device.name,
                    batch.device.model,
                    batch.device.firmware_version,
                ),
            )

            sample_count = 0
            for sample in batch.samples:
                cur = conn.execute(
                    """
                    INSERT INTO metric_sample (
                        time, user_id, device_id, metric_key, value, unit,
                        source, quality, raw
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (user_id, device_id, metric_key, time, source)
                    DO UPDATE SET
                        value = EXCLUDED.value,
                        unit = COALESCE(EXCLUDED.unit, metric_sample.unit),
                        quality = COALESCE(EXCLUDED.quality, metric_sample.quality),
                        raw = COALESCE(EXCLUDED.raw, metric_sample.raw),
                        updated_at = now()
                    """,
                    (
                        sample.timestamp,
                        batch.user_id,
                        batch.device.device_id,
                        sample.metric_key,
                        sample.value,
                        sample.unit,
                        sample.source,
                        Jsonb(sample.quality) if sample.quality is not None else None,
                        Jsonb(sample.raw) if sample.raw is not None else None,
                    ),
                )
                sample_count += cur.rowcount

            raw_count = 0
            for raw in batch.raw_samples:
                cur = conn.execute(
                    """
                    INSERT INTO raw_sample (
                        time, user_id, device_id, stream_key, source, payload
                    )
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (user_id, device_id, stream_key, time, source)
                    DO UPDATE SET
                        payload = EXCLUDED.payload,
                        updated_at = now()
                    """,
                    (
                        raw.timestamp,
                        batch.user_id,
                        batch.device.device_id,
                        raw.stream_key,
                        raw.source,
                        Jsonb(raw.payload),
                    ),
                )
                raw_count += cur.rowcount

            daily_count = 0
            for metric in batch.daily_metrics:
                cur = conn.execute(
                    """
                    INSERT INTO daily_metric (
                        day, user_id, device_id, metric_key, value, unit,
                        source, quality
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (user_id, device_id, day, metric_key, source)
                    DO UPDATE SET
                        value = EXCLUDED.value,
                        unit = COALESCE(EXCLUDED.unit, daily_metric.unit),
                        quality = COALESCE(EXCLUDED.quality, daily_metric.quality),
                        updated_at = now()
                    """,
                    (
                        metric.day,
                        batch.user_id,
                        batch.device.device_id,
                        metric.metric_key,
                        metric.value,
                        metric.unit,
                        metric.source,
                        Jsonb(metric.quality) if metric.quality is not None else None,
                    ),
                )
                daily_count += cur.rowcount

            sleep_count = 0
            for sleep in batch.sleep_sessions:
                cur = conn.execute(
                    """
                    INSERT INTO sleep_session (
                        user_id, device_id, start_time, end_time, source,
                        total_sleep_min, efficiency, resting_hr, avg_hrv_ms,
                        recovery, strain, stages
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (user_id, device_id, start_time, source)
                    DO UPDATE SET
                        end_time = EXCLUDED.end_time,
                        total_sleep_min = EXCLUDED.total_sleep_min,
                        efficiency = EXCLUDED.efficiency,
                        resting_hr = EXCLUDED.resting_hr,
                        avg_hrv_ms = EXCLUDED.avg_hrv_ms,
                        recovery = EXCLUDED.recovery,
                        strain = EXCLUDED.strain,
                        stages = COALESCE(EXCLUDED.stages, sleep_session.stages),
                        updated_at = now()
                    """,
                    (
                        batch.user_id,
                        batch.device.device_id,
                        sleep.start_time,
                        sleep.end_time,
                        sleep.source,
                        sleep.total_sleep_min,
                        sleep.efficiency,
                        sleep.resting_hr,
                        sleep.avg_hrv_ms,
                        sleep.recovery,
                        sleep.strain,
                        Jsonb(sleep.stages) if sleep.stages is not None else None,
                    ),
                )
                sleep_count += cur.rowcount

            workout_count = 0
            for workout in batch.workouts:
                cur = conn.execute(
                    """
                    INSERT INTO workout (
                        user_id, device_id, start_time, end_time, sport, source,
                        duration_s, energy_kcal, avg_hr, max_hr, strain,
                        distance_m, zones, notes
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (user_id, device_id, start_time, sport, source)
                    DO UPDATE SET
                        end_time = EXCLUDED.end_time,
                        duration_s = EXCLUDED.duration_s,
                        energy_kcal = EXCLUDED.energy_kcal,
                        avg_hr = EXCLUDED.avg_hr,
                        max_hr = EXCLUDED.max_hr,
                        strain = EXCLUDED.strain,
                        distance_m = EXCLUDED.distance_m,
                        zones = COALESCE(EXCLUDED.zones, workout.zones),
                        notes = COALESCE(EXCLUDED.notes, workout.notes),
                        updated_at = now()
                    """,
                    (
                        batch.user_id,
                        batch.device.device_id,
                        workout.start_time,
                        workout.end_time,
                        workout.sport,
                        workout.source,
                        workout.duration_s,
                        workout.energy_kcal,
                        workout.avg_hr,
                        workout.max_hr,
                        workout.strain,
                        workout.distance_m,
                        Jsonb(workout.zones) if workout.zones is not None else None,
                        workout.notes,
                    ),
                )
                workout_count += cur.rowcount

    return SyncResult(
        user_id=batch.user_id,
        device_id=batch.device.device_id,
        samples=sample_count,
        raw_samples=raw_count,
        daily_metrics=daily_count,
        sleep_sessions=sleep_count,
        workouts=workout_count,
    )

# Optional TimescaleDB Sync

NOOP remains local-first. The app stores data in its local SQLite database and works fully offline.
The TimescaleDB layer in `server/timescale` is an optional external ingest target for people who
want a server-side time-series copy for dashboards, research, or long-term exports.

## What It Adds

- A TimescaleDB schema for multi-user, multi-device time-series health data.
- A minimal FastAPI ingest service at `POST /v1/sync/batch`.
- Idempotent upserts keyed by `user_id`, `device_id`, metric/source, and time.
- Docker Compose for local self-hosted development.
- Environment-variable configuration.

It does not replace NOOP local storage and it is not required by any app target.

## Data Scope

Every record is scoped by:

- `user_id`: UUID owned by the deployment or exporter.
- `device_id`: the WHOOP device identifier from NOOP.

The schema supports:

- heart rate
- PPG-derived heart rate
- R-R intervals / HRV source data
- sleep summaries and stages
- recovery, strain, and daily metrics
- workouts
- respiratory rate
- skin temperature
- SpO2
- battery
- raw decoded samples and stream payloads

Metric names are intentionally long-form keys such as `heart_rate_bpm`, `hrv_ms`,
`respiratory_rate_bpm`, `skin_temp_dev_c`, `sleep_total_min`, `recovery_pct`,
`strain_0_100`, `strain_0_21`, and `workout_strain`.

## Setup

Copy the example environment and change the secrets:

```sh
cp server/timescale/.env.example server/timescale/.env
```

Start the database and API:

```sh
docker compose --env-file server/timescale/.env -f docker-compose.timescale.yml up --build
```

The migration in `server/timescale/migrations/001_noop_timescale.sql` runs automatically on a fresh
database volume.

Health check:

```sh
curl http://localhost:8088/healthz
```

Authenticated ingest:

```sh
curl -X POST http://localhost:8088/v1/sync/batch \
  -H "Authorization: Bearer $NOOP_TIMESCALE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "00000000-0000-0000-0000-000000000001",
    "device": { "device_id": "my-whoop", "model": "WHOOP 5" },
    "samples": [
      {
        "metric_key": "heart_rate_bpm",
        "timestamp": "2026-06-16T08:00:00Z",
        "value": 62,
        "unit": "bpm",
        "source": "noop"
      }
    ],
    "daily_metrics": [
      {
        "day": "2026-06-16",
        "metric_key": "recovery_pct",
        "value": 82,
        "unit": "%"
      }
    ]
  }'
```

Posting the same payload again updates the existing rows instead of creating duplicates.

## Environment Variables

| Variable | Purpose |
| --- | --- |
| `NOOP_TIMESCALE_DATABASE_URL` | PostgreSQL connection string for the API service. |
| `NOOP_TIMESCALE_API_TOKEN` | Optional bearer token. If unset, auth is disabled. |
| `POSTGRES_DB` | Database created by the Timescale container. |
| `POSTGRES_USER` | Database user created by the Timescale container. |
| `POSTGRES_PASSWORD` | Database password created by the Timescale container. |
| `POSTGRES_PORT` | Host port for PostgreSQL. |
| `NOOP_TIMESCALE_API_PORT` | Host port for the FastAPI service. |

## Sync Shape

The service accepts one batch per user/device. Exporters can send any mix of:

- `samples`: scalar time-series rows for HR, HRV, recovery, strain, respiratory rate, skin
  temperature, SpO2, battery, calories, steps, or other metrics.
- `raw_samples`: raw decoded stream payloads where preserving the original fields matters.
- `daily_metrics`: day-keyed aggregates.
- `sleep_sessions`: sleep session summaries with optional stage JSON.
- `workouts`: workout events and summaries.

This service is intentionally independent from the NOOP app targets. A future exporter can read
NOOP SQLite through `WhoopStore` or a backup/export file and post batches here without changing the
offline app behavior.

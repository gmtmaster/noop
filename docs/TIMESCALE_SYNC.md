# Optional TimescaleDB Sync

NOOP remains local-first. The app stores data in its local SQLite database and works fully offline.
The TimescaleDB layer in `server/timescale` is an optional external ingest target for people who
want a server-side time-series copy for dashboards, research, or long-term exports.

## What It Adds

- A TimescaleDB schema for multi-user, multi-device time-series health data.
- A minimal FastAPI ingest service at `POST /v1/sync/batch`.
- An optional in-app **Settings > Server Sync** exporter.
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

The app exporter uses stable long-form keys such as `heart_rate`, `rr_interval`, `hrv_rmssd`,
`resting_heart_rate`, `respiratory_rate`, `skin_temperature_deviation`, `spo2`, `recovery`,
`strain`, `step_counter`, `battery_soc`, `sleep_efficiency`, and Apple-prefixed keys for Apple
Health daily aggregates.

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

## App Configuration

Open **Settings > Server Sync** in NOOP.

1. Enter the server URL, for example `http://localhost:8088`.
2. Paste the bearer token from `NOOP_TIMESCALE_API_TOKEN` and click **Save**.
3. Enter a user UUID. This is manually managed for now; no cloud login is required.
4. Enter the device ID. It defaults to NOOP's current WHOOP device ID (`my-whoop`) and can be
   changed for multi-device deployments.
5. Optionally add a profile label such as `Adam Whoop` or `Csenge Whoop`.
6. Pick an interval:
   - Manual only
   - Every 5 minutes
   - Every 15 minutes
   - Every 30 minutes
   - Every 1 hour
7. Turn on **Enable sync**.
8. Use **Test** to verify `/healthz`, then **Sync now** to send a batch.

Sync is disabled by default. NOOP still launches, records, imports, analyzes, and displays data
without a Timescale server. Manual sync works once the profile is configured. When enabled with an
interval, NOOP checks once a minute while the app is open and syncs only after the selected interval
has elapsed. On launch, it performs the same elapsed-interval check after the local repository is
ready.

**Full resync** clears the local Timescale export cursors for the active profile and sends data from
the exporter lookback windows again. Server inserts are idempotent, so duplicate rows are upserted
rather than duplicated.

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

- `samples`: scalar time-series rows for HR, R-R intervals, raw skin-temperature/respiration
  counters, step counter, battery percentage, and battery voltage.
- `raw_samples`: raw decoded stream payloads where preserving the original fields matters.
- `daily_metrics`: day-keyed aggregates.
- `sleep_sessions`: sleep session summaries with optional stage JSON.
- `workouts`: workout events and summaries.

The app exporter currently reads through NOOP's existing `Repository` and `WhoopStore` APIs and does
not modify BLE, parser, import, or local-storage write paths.

## Data Exported By The App

The app sends the local data it can read without changing NOOP internals:

- Heart-rate samples, including the existing WHOOP 5 PPG-derived fallback exposed by `WhoopStore`.
- R-R intervals, which are the raw source for HRV.
- Battery percentage, voltage, and charging state when available.
- WHOOP raw optical SpO2 samples as `raw_samples`; daily SpO2 percentage when NOOP has computed or
  imported it.
- Raw skin-temperature and respiration sensor counters plus daily derived skin-temperature deviation
  and respiratory rate when available.
- Step counter samples and daily step totals when available.
- Gravity samples as raw x/y/z payloads.
- Decoded WHOOP events as raw payloads.
- Daily summaries: sleep minutes, sleep efficiency, stages totals, disturbances, resting HR, HRV,
  recovery, strain, exercise count, SpO2, skin-temperature deviation, respiratory rate, steps, and
  estimated active calories.
- Generic metric-series rows stored in NOOP's long-format local metric cache.
- Apple Health daily aggregates stored locally by NOOP.
- Sleep sessions with stage JSON when available.
- Workouts with duration, energy, average/max HR, strain, distance, zones JSON, and notes.

Unavailable or intentionally not exported in this first app-side pass:

- Raw binary `rawBatch` frame blobs are not uploaded; decoded stream rows/events are exported instead.
- Workout-specific HR traces are not duplicated under each workout. The same HR samples are exported
  as global heart-rate samples, and workout zone summaries are sent when NOOP stores them.
- Values NOOP has not stored locally are not invented.

## Security

The bearer token is stored in the platform Keychain. Non-sensitive settings, status, and export
cursors are stored in local app preferences. The server token is sent only to the configured Server
Sync URL.

For local HTTP testing, the project allows local networking. For real deployments, put the API behind
HTTPS and rotate `NOOP_TIMESCALE_API_TOKEN` if it is exposed.

## Troubleshooting

- **Test fails with 401**: confirm the app token matches `NOOP_TIMESCALE_API_TOKEN`, then click
  **Save** again.
- **Test fails with connection errors**: check Docker is running and `NOOP_TIMESCALE_API_PORT`
  matches the URL in the app.
- **Sync says not configured**: server URL, user UUID, device ID, and saved token are required.
- **No new data to sync**: the app has already sent everything after the current cursors. Use
  **Full resync** only when you intentionally want to replay the local lookback windows.
- **Server has fewer rows than expected**: initial exports are batched and checkpointed by stream.
  Leave the app open or press **Sync now** again to continue draining dense sample history.

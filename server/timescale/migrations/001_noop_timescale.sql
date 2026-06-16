CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE IF NOT EXISTS noop_user (
    user_id UUID PRIMARY KEY,
    external_key TEXT,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS noop_device (
    user_id UUID NOT NULL REFERENCES noop_user(user_id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    name TEXT,
    model TEXT,
    firmware_version TEXT,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, device_id)
);

CREATE TABLE IF NOT EXISTS metric_sample (
    time TIMESTAMPTZ NOT NULL,
    user_id UUID NOT NULL,
    device_id TEXT NOT NULL,
    metric_key TEXT NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit TEXT,
    source TEXT NOT NULL DEFAULT 'noop',
    quality JSONB,
    raw JSONB,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, device_id, metric_key, time, source),
    FOREIGN KEY (user_id, device_id)
        REFERENCES noop_device(user_id, device_id)
        ON DELETE CASCADE
);

SELECT create_hypertable('metric_sample', 'time', if_not_exists => TRUE);

CREATE INDEX IF NOT EXISTS idx_metric_sample_lookup
    ON metric_sample (user_id, device_id, metric_key, time DESC);

CREATE TABLE IF NOT EXISTS raw_sample (
    time TIMESTAMPTZ NOT NULL,
    user_id UUID NOT NULL,
    device_id TEXT NOT NULL,
    stream_key TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'noop',
    payload JSONB NOT NULL,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, device_id, stream_key, time, source),
    FOREIGN KEY (user_id, device_id)
        REFERENCES noop_device(user_id, device_id)
        ON DELETE CASCADE
);

SELECT create_hypertable('raw_sample', 'time', if_not_exists => TRUE);

CREATE INDEX IF NOT EXISTS idx_raw_sample_lookup
    ON raw_sample (user_id, device_id, stream_key, time DESC);

CREATE TABLE IF NOT EXISTS daily_metric (
    day DATE NOT NULL,
    user_id UUID NOT NULL,
    device_id TEXT NOT NULL,
    metric_key TEXT NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit TEXT,
    source TEXT NOT NULL DEFAULT 'noop',
    quality JSONB,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, device_id, day, metric_key, source),
    FOREIGN KEY (user_id, device_id)
        REFERENCES noop_device(user_id, device_id)
        ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_daily_metric_lookup
    ON daily_metric (user_id, device_id, metric_key, day DESC);

CREATE TABLE IF NOT EXISTS sleep_session (
    user_id UUID NOT NULL,
    device_id TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    source TEXT NOT NULL DEFAULT 'noop',
    total_sleep_min DOUBLE PRECISION,
    efficiency DOUBLE PRECISION,
    resting_hr INTEGER,
    avg_hrv_ms DOUBLE PRECISION,
    recovery DOUBLE PRECISION,
    strain DOUBLE PRECISION,
    stages JSONB,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, device_id, start_time, source),
    FOREIGN KEY (user_id, device_id)
        REFERENCES noop_device(user_id, device_id)
        ON DELETE CASCADE
);

SELECT create_hypertable('sleep_session', 'start_time', if_not_exists => TRUE);

CREATE INDEX IF NOT EXISTS idx_sleep_session_lookup
    ON sleep_session (user_id, device_id, start_time DESC);

CREATE TABLE IF NOT EXISTS workout (
    user_id UUID NOT NULL,
    device_id TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    sport TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'noop',
    duration_s DOUBLE PRECISION,
    energy_kcal DOUBLE PRECISION,
    avg_hr INTEGER,
    max_hr INTEGER,
    strain DOUBLE PRECISION,
    distance_m DOUBLE PRECISION,
    zones JSONB,
    notes TEXT,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, device_id, start_time, sport, source),
    FOREIGN KEY (user_id, device_id)
        REFERENCES noop_device(user_id, device_id)
        ON DELETE CASCADE
);

SELECT create_hypertable('workout', 'start_time', if_not_exists => TRUE);

CREATE INDEX IF NOT EXISTS idx_workout_lookup
    ON workout (user_id, device_id, start_time DESC);

CREATE TABLE IF NOT EXISTS sync_checkpoint (
    user_id UUID NOT NULL,
    device_id TEXT NOT NULL,
    stream_key TEXT NOT NULL,
    highwater TIMESTAMPTZ,
    cursor JSONB,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, device_id, stream_key),
    FOREIGN KEY (user_id, device_id)
        REFERENCES noop_device(user_id, device_id)
        ON DELETE CASCADE
);

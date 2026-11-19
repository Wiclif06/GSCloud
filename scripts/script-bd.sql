-- AgroConecta: DDL completo de referência, em ordem de migração.
-- Somente banco vazio. A aplicação usa Flyway: não execute este agregado no banco administrado pelo Flyway.

-- V1__initial_schema.sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_users_role CHECK (role IN ('PRODUCER', 'TECHNICIAN', 'ADMIN'))
);

CREATE TABLE farms (
    id BIGSERIAL PRIMARY KEY,
    owner_user_id BIGINT NOT NULL REFERENCES users(id),
    name VARCHAR(120) NOT NULL,
    responsible_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(2) NOT NULL,
    country VARCHAR(80) NOT NULL,
    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_farms_owner_user_id ON farms(owner_user_id);

CREATE TABLE crop_areas (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    name VARCHAR(120) NOT NULL,
    crop_type VARCHAR(80) NOT NULL,
    area_size NUMERIC(12, 2) NOT NULL,
    area_unit VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL,
    latitude NUMERIC(9, 6),
    longitude NUMERIC(9, 6),
    description VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT ck_crop_areas_area_size CHECK (area_size > 0),
    CONSTRAINT ck_crop_areas_area_unit CHECK (area_unit IN ('HECTARE', 'SQUARE_METER')),
    CONSTRAINT ck_crop_areas_status CHECK (status IN ('NORMAL', 'ATTENTION', 'CRITICAL'))
);

CREATE INDEX idx_crop_areas_farm_id ON crop_areas(farm_id);


-- V2__unique_user_email_ignore_case.sql
CREATE UNIQUE INDEX ux_users_email_lower ON users (lower(email));


-- V3__add_farm_area.sql
-- Propriedades existentes permanecem sem área informada até a próxima atualização.
ALTER TABLE farms ADD COLUMN total_area NUMERIC(12, 2);
ALTER TABLE farms ADD COLUMN area_unit VARCHAR(20);

ALTER TABLE farms ADD CONSTRAINT ck_farms_area CHECK (
    (total_area IS NULL AND area_unit IS NULL)
    OR (
        total_area IS NOT NULL AND area_unit IS NOT NULL
        AND total_area > 0
        AND area_unit IN ('HECTARE', 'SQUARE_METER')
    )
);


-- V4__create_sensors.sql
CREATE TABLE sensors (
    id BIGSERIAL PRIMARY KEY,
    crop_area_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    device_code VARCHAR(80) NOT NULL,
    sensor_type VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    installation_date DATE NOT NULL,
    description VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_sensors_crop_area FOREIGN KEY (crop_area_id) REFERENCES crop_areas(id) ON DELETE RESTRICT,
    CONSTRAINT ck_sensors_name CHECK (char_length(btrim(name)) BETWEEN 3 AND 100),
    CONSTRAINT ck_sensors_device_code CHECK (char_length(btrim(device_code)) BETWEEN 3 AND 80),
    CONSTRAINT ck_sensors_type CHECK (sensor_type IN ('SOIL_MOISTURE', 'TEMPERATURE', 'HUMIDITY', 'WEATHER_STATION')),
    CONSTRAINT ck_sensors_status CHECK (status IN ('ACTIVE', 'INACTIVE', 'FAULT'))
);

CREATE INDEX idx_sensors_crop_area_id ON sensors(crop_area_id);
CREATE UNIQUE INDEX ux_sensors_device_code_upper ON sensors(upper(device_code));


-- V5__sensor_readings_and_outbox.sql
CREATE TABLE sensor_readings (
    id BIGSERIAL PRIMARY KEY,
    sensor_id BIGINT NOT NULL,
    temperature_celsius NUMERIC(6, 3),
    air_humidity_percent NUMERIC(6, 3),
    soil_moisture_percent NUMERIC(6, 3),
    battery_percent NUMERIC(6, 3),
    measured_at TIMESTAMPTZ NOT NULL,
    source VARCHAR(20) NOT NULL,
    analysis_status VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CONSTRAINT fk_sensor_readings_sensor FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON DELETE RESTRICT,
    CONSTRAINT ck_readings_temperature CHECK (temperature_celsius BETWEEN -50 AND 70),
    CONSTRAINT ck_readings_air_humidity CHECK (air_humidity_percent BETWEEN 0 AND 100),
    CONSTRAINT ck_readings_soil_moisture CHECK (soil_moisture_percent BETWEEN 0 AND 100),
    CONSTRAINT ck_readings_battery CHECK (battery_percent BETWEEN 0 AND 100),
    CONSTRAINT ck_readings_measurement CHECK (temperature_celsius IS NOT NULL OR air_humidity_percent IS NOT NULL
        OR soil_moisture_percent IS NOT NULL OR battery_percent IS NOT NULL),
    CONSTRAINT ck_readings_source CHECK (source IN ('MANUAL', 'DEVICE')),
    CONSTRAINT ck_readings_analysis_status CHECK (analysis_status IN ('PENDING_PUBLICATION', 'QUEUED_FOR_ANALYSIS', 'ANALYZED', 'FAILED'))
);
CREATE INDEX idx_readings_sensor_measured ON sensor_readings(sensor_id, measured_at DESC, id DESC);
CREATE INDEX idx_readings_measured_at ON sensor_readings(measured_at DESC, id DESC);
CREATE INDEX idx_readings_analysis_status ON sensor_readings(analysis_status);

CREATE TABLE outbox_events (
    event_id UUID PRIMARY KEY,
    aggregate_type VARCHAR(80) NOT NULL,
    aggregate_id BIGINT NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(20) NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL,
    next_attempt_at TIMESTAMPTZ NOT NULL,
    published_at TIMESTAMPTZ,
    last_error VARCHAR(500),
    CONSTRAINT ck_outbox_status CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED')),
    CONSTRAINT ck_outbox_attempts CHECK (attempts >= 0),
    CONSTRAINT ck_outbox_payload CHECK (jsonb_typeof(payload) = 'object')
);
CREATE INDEX idx_outbox_pending ON outbox_events(status, next_attempt_at, created_at);
CREATE INDEX idx_outbox_created_at ON outbox_events(created_at);
CREATE INDEX idx_outbox_aggregate ON outbox_events(aggregate_type, aggregate_id);


-- V6__agronomic_analysis_and_rag.sql
CREATE TABLE agronomic_analyses (
    id BIGSERIAL PRIMARY KEY,
    reading_id BIGINT NOT NULL UNIQUE REFERENCES sensor_readings(id) ON DELETE RESTRICT,
    crop_area_id BIGINT NOT NULL REFERENCES crop_areas(id) ON DELETE RESTRICT,
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING','PROCESSING','COMPLETED','FAILED')),
    risk_level VARCHAR(20) CHECK (risk_level IN ('LOW','MODERATE','HIGH','CRITICAL')),
    title VARCHAR(160), summary VARCHAR(2000), recommendation VARCHAR(4200),
    recommended_actions JSONB, observed_conditions JSONB, warnings JSONB,
    data_quality VARCHAR(20) CHECK (data_quality IN ('SUFFICIENT','PARTIAL','INSUFFICIENT')),
    retrieved_sources JSONB, model_name VARCHAR(100), prompt_version VARCHAR(30),
    attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    error_message VARCHAR(200), started_at TIMESTAMPTZ, completed_at TIMESTAMPTZ,
    processing_token UUID, manual_retry_count INTEGER NOT NULL DEFAULT 0 CHECK (manual_retry_count >= 0),
    last_retry_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL, updated_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX idx_analyses_crop_created ON agronomic_analyses(crop_area_id, created_at DESC, id DESC);
CREATE INDEX idx_analyses_status_started ON agronomic_analyses(status, started_at);

-- Table owned by this RAG corpus; do not reuse a previously auto-generated vector_store of another dimension.
CREATE TABLE agronomy_vector_store (
    id UUID PRIMARY KEY,
    content TEXT,
    metadata JSON,
    embedding vector(768)
);
CREATE INDEX idx_agronomy_vector_cosine ON agronomy_vector_store USING hnsw (embedding vector_cosine_ops);
CREATE TABLE rag_ingestion (
    corpus_key VARCHAR(180) PRIMARY KEY,
    checksum VARCHAR(64) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);


-- V7__field_activities.sql
CREATE TABLE field_activities (
    id BIGSERIAL PRIMARY KEY,
    crop_area_id BIGINT NOT NULL REFERENCES crop_areas(id),
    author_id BIGINT NOT NULL REFERENCES users(id),
    type VARCHAR(30) NOT NULL CHECK (type IN ('IRRIGATION','FERTILIZATION','PLANTING','HARVEST')),
    performed_at TIMESTAMPTZ NOT NULL,
    description VARCHAR(2000),
    quantity NUMERIC(14,3),
    unit VARCHAR(30),
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    CHECK ((quantity IS NULL AND unit IS NULL) OR (quantity > 0 AND unit IS NOT NULL AND length(trim(unit)) > 0))
);
CREATE INDEX idx_field_activities_area_time ON field_activities(crop_area_id,performed_at DESC,id DESC);


-- V8__agronomic_profiles.sql
CREATE TABLE agronomic_profiles (
    id BIGSERIAL PRIMARY KEY,
    crop_area_id BIGINT NOT NULL REFERENCES crop_areas(id),
    revision BIGINT NOT NULL CHECK(revision>0),
    soil_texture VARCHAR(100) NOT NULL,
    field_capacity_percent DOUBLE PRECISION NOT NULL,
    wilting_point_percent DOUBLE PRECISION NOT NULL,
    root_depth_centimeters DOUBLE PRECISION,
    sensor_depth_centimeters DOUBLE PRECISION,
    source VARCHAR(500) NOT NULL,
    demo BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    UNIQUE(crop_area_id,revision),
    CHECK(wilting_point_percent>=0 AND field_capacity_percent<=100 AND field_capacity_percent>wilting_point_percent),
    CHECK(root_depth_centimeters>0),
    CHECK(sensor_depth_centimeters>0)
);


-- V9__archive_crop_areas.sql
ALTER TABLE crop_areas DROP CONSTRAINT ck_crop_areas_status;
ALTER TABLE crop_areas ADD CONSTRAINT ck_crop_areas_status CHECK (status IN ('NORMAL','ATTENTION','CRITICAL','ARCHIVED'));


-- V10__risk_jobs.sql
CREATE TABLE risk_jobs (
 id BIGSERIAL PRIMARY KEY,
 crop_area_id BIGINT NOT NULL REFERENCES crop_areas(id),
 owner_id BIGINT NOT NULL REFERENCES users(id),
 profile_id BIGINT REFERENCES agronomic_profiles(id),
 field_capacity DOUBLE PRECISION,
 wilting_point DOUBLE PRECISION,
 demo BOOLEAN NOT NULL,
 status VARCHAR(40) NOT NULL,
 created_at TIMESTAMPTZ NOT NULL,
 completed_at TIMESTAMPTZ,
 measurements JSONB NOT NULL,
 result JSONB,
 rules_version VARCHAR(30) NOT NULL,
 alert_status VARCHAR(30),
 acknowledged_at TIMESTAMPTZ,
 resolved_at TIMESTAMPTZ
);
CREATE INDEX idx_risk_jobs_owner ON risk_jobs(owner_id,crop_area_id,id DESC);


-- V11__job_guidance.sql
ALTER TABLE risk_jobs ADD COLUMN crop_type VARCHAR(80);
ALTER TABLE risk_jobs ADD COLUMN guidance JSONB;


-- V12__simulated_readings.sql
ALTER TABLE sensor_readings DROP CONSTRAINT ck_readings_source;
ALTER TABLE sensor_readings ADD CONSTRAINT ck_readings_source CHECK (source IN ('MANUAL','DEVICE','SIMULATED'));
ALTER TABLE sensor_readings DROP CONSTRAINT ck_readings_analysis_status;
ALTER TABLE sensor_readings ADD CONSTRAINT ck_readings_analysis_status CHECK (analysis_status IN ('RECORDED','PENDING_PUBLICATION','QUEUED_FOR_ANALYSIS','ANALYZED','FAILED'));


-- V13__rainfall_intervals.sql
ALTER TABLE sensor_readings ADD COLUMN rainfall_millimeters NUMERIC(9,3);
ALTER TABLE sensor_readings ADD COLUMN rainfall_interval_start TIMESTAMPTZ;
ALTER TABLE sensor_readings ADD CONSTRAINT ck_rainfall_interval CHECK (
 (rainfall_millimeters IS NULL AND rainfall_interval_start IS NULL) OR
 (rainfall_millimeters >= 0 AND rainfall_interval_start IS NOT NULL AND rainfall_interval_start < measured_at));
ALTER TABLE sensor_readings DROP CONSTRAINT ck_readings_measurement;
ALTER TABLE sensor_readings ADD CONSTRAINT ck_readings_measurement CHECK
 (temperature_celsius IS NOT NULL OR air_humidity_percent IS NOT NULL OR soil_moisture_percent IS NOT NULL
 OR battery_percent IS NOT NULL OR rainfall_millimeters IS NOT NULL);


-- V14__job_rainfall.sql
ALTER TABLE risk_jobs ADD COLUMN rainfall JSONB;


-- V15__technician_maintenance.sql
CREATE TABLE farm_technicians (
 farm_id BIGINT NOT NULL REFERENCES farms(id),
 technician_id BIGINT NOT NULL REFERENCES users(id),
 PRIMARY KEY(farm_id,technician_id)
);
ALTER TABLE sensors ADD COLUMN calibrated_at DATE;
ALTER TABLE sensors ADD COLUMN maintenance_note VARCHAR(500);
ALTER TABLE sensors DROP CONSTRAINT ck_sensors_status;
ALTER TABLE sensors ADD CONSTRAINT ck_sensors_status CHECK(status IN ('ACTIVE','INACTIVE','FAULT','MAINTENANCE'));


-- V16__device_keys.sql
ALTER TABLE sensors ADD COLUMN device_key_hash VARCHAR(255);


-- V17__risk_job_audit.sql
ALTER TABLE risk_jobs ADD COLUMN started_at TIMESTAMPTZ;
ALTER TABLE risk_jobs ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0;
ALTER TABLE risk_jobs ADD COLUMN error_message VARCHAR(200);
ALTER TABLE risk_jobs ADD COLUMN thresholds JSONB;


-- V18__risk_recovery_and_alert_audit.sql
ALTER TABLE risk_jobs ADD COLUMN recovery_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE risk_jobs ADD COLUMN acknowledged_by BIGINT REFERENCES users(id);
ALTER TABLE risk_jobs ADD COLUMN resolved_by BIGINT REFERENCES users(id);
CREATE INDEX idx_risk_jobs_recovery ON risk_jobs(id) WHERE status='QUEUED';


-- V19__latest_rain.sql
ALTER TABLE risk_jobs ADD COLUMN latest_rain_at TIMESTAMPTZ;


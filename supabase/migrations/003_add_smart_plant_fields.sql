-- Migration 003: Add smart plant care fields
-- Drops views that depend on species_id, changes its type, then recreates them

-- Step 1: Drop dependent views
DROP VIEW IF EXISTS plants_needing_water CASCADE;
DROP VIEW IF EXISTS user_plant_stats CASCADE;

-- Step 2: Change species_id from UUID to TEXT
ALTER TABLE plants ALTER COLUMN species_id TYPE TEXT USING species_id::TEXT;

-- Step 3: Add new columns
ALTER TABLE plants ADD COLUMN IF NOT EXISTS environment TEXT DEFAULT 'indoor' CHECK (environment IN ('indoor', 'outdoor'));
ALTER TABLE plants ADD COLUMN IF NOT EXISTS growth_stage TEXT DEFAULT 'adult' CHECK (growth_stage IN ('seedling', 'juvenile', 'adult'));
ALTER TABLE plants ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE plants ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Step 4: Recreate the views
CREATE OR REPLACE VIEW plants_needing_water AS
SELECT
    p.*,
    CASE
        WHEN p.next_watering < CURRENT_DATE THEN 'overdue'
        WHEN p.next_watering = CURRENT_DATE THEN 'today'
        ELSE 'upcoming'
    END as watering_status,
    CASE
        WHEN p.next_watering < CURRENT_DATE THEN (CURRENT_DATE - p.next_watering::date)
        ELSE (p.next_watering::date - CURRENT_DATE)
    END as days_difference
FROM plants p
WHERE p.watering_frequency IS NOT NULL
    AND p.next_watering IS NOT NULL
    AND p.next_watering <= CURRENT_DATE + INTERVAL '1 day';

CREATE OR REPLACE VIEW user_plant_stats AS
SELECT
    user_id,
    COUNT(*) as total_plants,
    COUNT(watering_frequency) as plants_with_watering,
    COUNT(*) FILTER (WHERE next_watering <= CURRENT_DATE) as plants_needing_water
FROM plants
GROUP BY user_id;

-- Step 5: Comments
COMMENT ON COLUMN plants.species_id IS 'Species identifier: local_xxx for catalog, api_xxx for Perenual API';
COMMENT ON COLUMN plants.environment IS 'Plant environment: indoor or outdoor';
COMMENT ON COLUMN plants.growth_stage IS 'Current growth phase: seedling, juvenile, or adult';
COMMENT ON COLUMN plants.latitude IS 'GPS latitude for weather-based care';
COMMENT ON COLUMN plants.longitude IS 'GPS longitude for weather-based care';

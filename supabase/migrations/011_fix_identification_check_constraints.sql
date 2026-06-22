-- ============================================================================
-- Migration 011: Fix CHECK constraints on identification tables
-- ============================================================================
-- BUG: las constraints CHECK de plant_identifications y seed_identifications
-- NO coincidían con los valores de los enums Dart / de la IA. Por ejemplo,
-- watering_frequency permitía ('daily','weekly',...) pero la app envía
-- ('veryRare','rare','moderate','frequent','veryFrequent'). Resultado: el
-- UPDATE con los resultados de la IA violaba la constraint y fallaba, dejando
-- el registro sin nombre → la app mostraba "Planta/Semilla desconocida".
--
-- Esta migración corrige las constraints SIN borrar datos. Es idempotente.
-- ============================================================================

-- ---- plant_identifications --------------------------------------------------
ALTER TABLE plant_identifications DROP CONSTRAINT IF EXISTS plant_identifications_care_level_check;
ALTER TABLE plant_identifications DROP CONSTRAINT IF EXISTS plant_identifications_watering_frequency_check;
ALTER TABLE plant_identifications DROP CONSTRAINT IF EXISTS plant_identifications_light_requirement_check;
ALTER TABLE plant_identifications DROP CONSTRAINT IF EXISTS plant_identifications_humidity_requirement_check;

ALTER TABLE plant_identifications
    ADD CONSTRAINT plant_identifications_care_level_check
    CHECK (care_level IS NULL OR care_level IN ('easy', 'moderate', 'difficult', 'expert'));
ALTER TABLE plant_identifications
    ADD CONSTRAINT plant_identifications_watering_frequency_check
    CHECK (watering_frequency IS NULL OR watering_frequency IN ('veryRare', 'rare', 'moderate', 'frequent', 'veryFrequent'));
ALTER TABLE plant_identifications
    ADD CONSTRAINT plant_identifications_light_requirement_check
    CHECK (light_requirement IS NULL OR light_requirement IN ('deepShade', 'shade', 'indirectLight', 'brightIndirect', 'directLight', 'fullSun'));
ALTER TABLE plant_identifications
    ADD CONSTRAINT plant_identifications_humidity_requirement_check
    CHECK (humidity_requirement IS NULL OR humidity_requirement IN ('veryLow', 'low', 'moderate', 'high', 'veryHigh'));

-- ---- seed_identifications ---------------------------------------------------
ALTER TABLE seed_identifications DROP CONSTRAINT IF EXISTS seed_identifications_germination_difficulty_check;
ALTER TABLE seed_identifications DROP CONSTRAINT IF EXISTS seed_identifications_germination_time_check;
ALTER TABLE seed_identifications DROP CONSTRAINT IF EXISTS seed_identifications_sowing_depth_check;

ALTER TABLE seed_identifications
    ADD CONSTRAINT seed_identifications_germination_difficulty_check
    CHECK (germination_difficulty IS NULL OR germination_difficulty IN ('easy', 'moderate', 'difficult', 'expert'));
ALTER TABLE seed_identifications
    ADD CONSTRAINT seed_identifications_germination_time_check
    CHECK (germination_time IS NULL OR germination_time IN ('veryFast', 'fast', 'moderate', 'slow', 'verySlow'));
ALTER TABLE seed_identifications
    ADD CONSTRAINT seed_identifications_sowing_depth_check
    CHECK (sowing_depth IS NULL OR sowing_depth IN ('surface', 'shallow', 'medium', 'deep'));

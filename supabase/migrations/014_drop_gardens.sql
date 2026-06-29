-- ============================================================================
-- MIGRACIÓN 014 — Corte limpio: eliminar gardens / garden_groups
-- ============================================================================
-- ⚠️  APLICAR SOLO DESPUÉS de verificar que la migración 013 movió
--     correctamente los datos a locations (comprobar plants.location_id y
--     plants.organization_id poblados, y que el árbol de locations es correcto).
--
-- Esta migración es DESTRUCTIVA: borra las tablas gardens y garden_groups,
-- las columnas legacy de plants y locations, y los RPCs antiguos de jardines.
-- ============================================================================

-- 1. RPCs antiguos de jardines (ya sustituidos por los de organización).
DROP FUNCTION IF EXISTS public.get_or_create_default_garden() CASCADE;
DROP FUNCTION IF EXISTS public.assign_unclassified_plants_to_default_garden() CASCADE;

-- 2. Columnas FK legacy en plants (apuntaban a gardens/garden_groups).
ALTER TABLE plants
    DROP COLUMN IF EXISTS garden_id,
    DROP COLUMN IF EXISTS group_id;

-- 3. Columnas de trazabilidad de la migración en locations.
ALTER TABLE locations
    DROP COLUMN IF EXISTS legacy_garden_id,
    DROP COLUMN IF EXISTS legacy_group_id;

-- 4. Tablas legacy (garden_groups primero por la FK garden_id → gardens).
DROP TABLE IF EXISTS garden_groups CASCADE;
DROP TABLE IF EXISTS gardens CASCADE;

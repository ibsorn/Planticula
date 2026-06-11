-- Migration 006: Structural improvements for scalability
-- 1. Add is_edible field to species_catalog (replaces hardcoded list in Dart)
-- 2. Add species_category field to plants table (cache category for fast access)

-- ============================================================================
-- 1. ADD is_edible TO species_catalog
-- Allows marking any species as edible directly in DB instead of hardcoding IDs
-- ============================================================================

ALTER TABLE species_catalog ADD COLUMN IF NOT EXISTS is_edible BOOLEAN NOT NULL DEFAULT FALSE;

-- Mark existing edible species
UPDATE species_catalog SET is_edible = TRUE WHERE id IN (
    'local_tomato',
    'local_basil',
    'local_rosemary',
    'local_mint',
    'local_pepper',
    'local_strawberry',
    'local_parsley',
    'local_lettuce'
);

-- ============================================================================
-- 2. ADD species_category TO plants TABLE
-- Caches the species category so we don't need to JOIN species_catalog
-- for simple queries like "show all my succulents"
-- ============================================================================

ALTER TABLE plants ADD COLUMN IF NOT EXISTS species_category TEXT;

-- Backfill existing plants with their species category
UPDATE plants p
SET species_category = sc.category
FROM species_catalog sc
WHERE p.species_id = sc.id
  AND p.species_category IS NULL;

-- Index for filtering plants by category
CREATE INDEX IF NOT EXISTS idx_plants_species_category ON plants(species_category);

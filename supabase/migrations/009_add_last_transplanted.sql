-- Add last_transplanted column to plants table
-- Tracks when the user last moved the plant to a bigger pot.
-- Used by TransplantCalculator to determine time in current pot.
ALTER TABLE plants ADD COLUMN IF NOT EXISTS last_transplanted TIMESTAMPTZ;

COMMENT ON COLUMN plants.last_transplanted IS 'Last time the user registered a pot transplant for this plant';

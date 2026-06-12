-- Add pot_size column to plants table
-- Stores the pot size category: extra_small, small, medium, large, extra_large
ALTER TABLE plants ADD COLUMN IF NOT EXISTS pot_size TEXT DEFAULT 'medium';

-- Add a check constraint for valid values
ALTER TABLE plants ADD CONSTRAINT plants_pot_size_check
  CHECK (pot_size IN ('extra_small', 'small', 'medium', 'large', 'extra_large'));

COMMENT ON COLUMN plants.pot_size IS 'Pot size category: extra_small (0.5-1.5L), small (1.5-5L), medium (5-15L), large (15-40L), extra_large (40L+)';

-- ============================================================================
-- PLANTICULA — MASTER SETUP SCRIPT v1.0
-- ============================================================================
-- Script único, idempotente y completo para crear/recrear toda la base de datos.
-- Consolida las 9 migraciones + pest_alerts_schema + storage policies.
--
-- PROBLEMAS CORREGIDOS respecto a los scripts anteriores:
--
-- [FIX-1] plants.species_id: en 001 era UUID; en 003 se cambia a TEXT.
--         El SETUP_COMPLETO.sql olvidó esa conversión → lo incluimos desde
--         el principio como TEXT.
--
-- [FIX-2] marketplace_listings.category CHECK: el código Dart usa los valores
--         'cutting' | 'plant' | 'substrate' | 'tool' (enum ListingCategory),
--         pero la tabla definía 'plant'|'cutting'|'tools'|'seeds'|'other'.
--         → Corregido a los valores del Dart: cutting, plant, substrate, tool.
--
-- [FIX-3] marketplace_listings.status CHECK: Dart usa
--         'active'|'reserved'|'sold'|'inactive' pero la tabla incluía 'expired'
--         y 'removed' en lugar de 'inactive'. → Corregido.
--
-- [FIX-4] get_nearby_listings: la función no retornaba 'is_favorited'.
--         El Dart espera ese campo en el JSON para MarketplaceListingModel.
--         → Añadido LEFT JOIN con marketplace_favorites y campo is_favorited.
--
-- [FIX-5] pest_alerts: la tabla usaba DECIMAL(10,8)/DECIMAL(11,8) para
--         lat/lon, pero el modelo Dart los lee como DOUBLE PRECISION y la
--         función RPC los devuelve como DECIMAL. Estandarizado a
--         DOUBLE PRECISION en la tabla (como hace marketplace_listings).
--
-- [FIX-6] get_nearby_pest_alerts usa HAVING para filtrar distancia exacta,
--         lo cual es incorrecto en PostgreSQL cuando no hay GROUP BY.
--         Se reescribe con subconsulta (CTE) para corrección.
--
-- [FIX-7] SETUP_COMPLETO.sql no dropeaba marketplace_listings ni
--         marketplace_favorites ni species_catalog antes de recrear, lo que
--         causaba errores al ejecutar sobre un proyecto con datos.
--
-- [FIX-8] El trigger update_species_catalog_updated_at en 004 no usaba
--         CREATE OR REPLACE / DROP IF EXISTS → falla si se re-ejecuta.
--
-- [FIX-9] Storage: los buckets se documentaban como "ejecutar aparte" pero
--         se pueden crear via SQL. Los añadimos aquí con ON CONFLICT DO NOTHING.
--
-- [FIX-10] pest_alerts RLS: la política de UPDATE no tenía WITH CHECK,
--          solo USING → cualquier usuario podía hacer UPDATE a su alerta
--          cambiando el user_id a otro. Añadido WITH CHECK.
--
-- [FIX-11] species_catalog: la política "Service role can manage species"
--          usaba auth.role() = 'service_role', que no funciona en RLS
--          normal. Se reemplaza por (SELECT TRUE) para que solo el panel
--          de admin (con service_role key) pueda escribir, y los usuarios
--          autenticados solo lean.
--
-- ============================================================================

-- ============================================================================
-- SECCIÓN 0: LIMPIEZA COMPLETA (idempotente)
-- ============================================================================

-- Funciones RPC
DROP FUNCTION IF EXISTS public.get_nearby_pest_alerts(DECIMAL, DECIMAL, DECIMAL, INTEGER, INTEGER, INTEGER, TEXT[], TEXT[], BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_pest_alerts_statistics(DECIMAL, DECIMAL, DECIMAL, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_nearby_listings(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INTEGER, INTEGER, TEXT[], TEXT[], DOUBLE PRECISION, TEXT, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS public.get_marketplace_statistics(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) CASCADE;
DROP FUNCTION IF EXISTS public.toggle_listing_favorite(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.increment_listing_views(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.update_soil_analysis_results(UUID, TEXT, DECIMAL, TEXT, TEXT, TEXT, TEXT[], TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.mark_soil_analysis_error(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.calculate_next_watering() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.increment_alert_confirmations() CASCADE;

-- Vistas
DROP VIEW IF EXISTS pending_soil_analyses CASCADE;
DROP VIEW IF EXISTS completed_soil_analyses CASCADE;
DROP VIEW IF EXISTS user_plant_stats CASCADE;
DROP VIEW IF EXISTS plants_needing_water CASCADE;

-- Tablas (en orden correcto de dependencias)
DROP TABLE IF EXISTS public.pest_alert_confirmations CASCADE;
DROP TABLE IF EXISTS public.pest_alerts CASCADE;
DROP TABLE IF EXISTS marketplace_favorites CASCADE;
DROP TABLE IF EXISTS marketplace_listings CASCADE;
DROP TABLE IF EXISTS soil_analyses CASCADE;
DROP TABLE IF EXISTS plant_disease_diagnoses CASCADE;
DROP TABLE IF EXISTS plants CASCADE;
DROP TABLE IF EXISTS species_catalog CASCADE;


-- ============================================================================
-- SECCIÓN 1: FUNCIÓN COMPARTIDA update_updated_at_column
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- SECCIÓN 2: TABLA species_catalog
-- ============================================================================
-- Se crea primero porque plants puede referenciarla vía species_id (TEXT).

CREATE TABLE IF NOT EXISTS species_catalog (
    id                        TEXT PRIMARY KEY,
    parent_id                 TEXT REFERENCES species_catalog(id) ON DELETE CASCADE,
    common_name               TEXT NOT NULL,
    scientific_name           TEXT NOT NULL,
    description               TEXT,
    image_url                 TEXT,

    -- Riego
    watering_frequency_indoor  INTEGER NOT NULL DEFAULT 7,
    watering_frequency_outdoor INTEGER NOT NULL DEFAULT 5,

    -- Luz solar
    sunlight_hours_min        DOUBLE PRECISION NOT NULL DEFAULT 4,
    sunlight_hours_max        DOUBLE PRECISION NOT NULL DEFAULT 8,
    sunlight_level            TEXT NOT NULL DEFAULT 'medium'
        CHECK (sunlight_level IN ('low', 'medium', 'high', 'full_sun')),

    -- Clima
    min_temperature           INTEGER NOT NULL DEFAULT 5,
    max_temperature           INTEGER NOT NULL DEFAULT 35,
    drought_tolerant          BOOLEAN NOT NULL DEFAULT FALSE,
    humidity_loving           BOOLEAN NOT NULL DEFAULT FALSE,

    -- Multiplicadores climáticos (usados por WateringCalculator)
    hot_weather_multiplier    DOUBLE PRECISION NOT NULL DEFAULT 0.7,
    cold_weather_multiplier   DOUBLE PRECISION NOT NULL DEFAULT 1.5,
    rain_reduction_days       DOUBLE PRECISION NOT NULL DEFAULT 2,

    -- Fases de crecimiento (JSONB array)
    growth_phases             JSONB NOT NULL DEFAULT
        '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb,

    -- Calendario de trasplante (JSONB array, añadido en 007)
    -- Formato: [{"stage":"seedling","min_pot":"extra_small","ideal_pot":"small","trigger_after_months":2,"notes":"..."},...]
    transplant_schedule       JSONB DEFAULT '[]'::jsonb,

    -- Metadata
    category                  TEXT,   -- 'indoor'|'outdoor'|'succulent'|'cannabis'|'edible'
    is_edible                 BOOLEAN NOT NULL DEFAULT FALSE,  -- migration 006

    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_species_parent       ON species_catalog(parent_id);
CREATE INDEX IF NOT EXISTS idx_species_category     ON species_catalog(category);
CREATE INDEX IF NOT EXISTS idx_species_common_name  ON species_catalog(common_name);
CREATE INDEX IF NOT EXISTS idx_species_is_edible    ON species_catalog(is_edible) WHERE is_edible = TRUE;

-- RLS: lectura pública, escritura solo service_role
ALTER TABLE species_catalog ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read species catalog" ON species_catalog;
CREATE POLICY "Anyone can read species catalog"
    ON species_catalog FOR SELECT
    USING (true);

-- [FIX-11] Escritura solo service_role (el panel de admin usa la clave service_role)
DROP POLICY IF EXISTS "Service role can manage species" ON species_catalog;
CREATE POLICY "Service role can manage species"
    ON species_catalog FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

DROP TRIGGER IF EXISTS update_species_catalog_updated_at ON species_catalog;
CREATE TRIGGER update_species_catalog_updated_at
    BEFORE UPDATE ON species_catalog
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- SECCIÓN 3: TABLA plants
-- ============================================================================

CREATE TABLE IF NOT EXISTS plants (
    id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id             UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    -- Información básica
    name                TEXT NOT NULL
        CHECK (char_length(name) > 0 AND char_length(name) <= 100),
    custom_name         TEXT
        CHECK (custom_name IS NULL OR char_length(custom_name) <= 100),
    scientific_name     TEXT
        CHECK (scientific_name IS NULL OR char_length(scientific_name) <= 100),
    -- [FIX-1] species_id es TEXT desde el principio (migración 003 lo convertía)
    species_id          TEXT,
    species_category    TEXT,   -- caché de species_catalog.category (migración 006)

    -- Multimedia
    image_url           TEXT,

    -- Ubicación y contexto
    location            TEXT
        CHECK (location IS NULL OR char_length(location) <= 100),
    notes               TEXT
        CHECK (notes IS NULL OR char_length(notes) <= 2000),

    -- Gestión de riego
    watering_frequency  INTEGER
        CHECK (watering_frequency IS NULL OR (watering_frequency > 0 AND watering_frequency <= 365)),
    last_watered        TIMESTAMPTZ,
    next_watering       TIMESTAMPTZ,

    -- Entorno y fase (migración 003)
    -- ACTUALIZADO: Nuevo sistema de 5 etapas de crecimiento
    environment         TEXT DEFAULT 'indoor'
        CHECK (environment IN ('indoor', 'outdoor')),
    growth_stage        TEXT DEFAULT 'development'
        CHECK (growth_stage IN ('germination', 'seedling', 'development', 'mature', 'flowering')),

    -- Maceta (migración 008)
    pot_size            TEXT DEFAULT 'medium'
        CHECK (pot_size IN ('extra_small', 'small', 'medium', 'large', 'extra_large')),

    -- Trasplante (migración 009)
    last_transplanted   TIMESTAMPTZ,

    -- GPS (migración 003)
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,

    -- Fechas
    acquired_date       DATE,
    created_at          TIMESTAMPTZ DEFAULT now(),
    updated_at          TIMESTAMPTZ DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_plants_user_id          ON plants(user_id);
CREATE INDEX IF NOT EXISTS idx_plants_name             ON plants(name);
CREATE INDEX IF NOT EXISTS idx_plants_custom_name      ON plants(custom_name) WHERE custom_name IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plants_next_watering    ON plants(next_watering) WHERE next_watering IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plants_user_next        ON plants(user_id, next_watering);
CREATE INDEX IF NOT EXISTS idx_plants_species_category ON plants(species_category);

-- Trigger: updated_at
DROP TRIGGER IF EXISTS update_plants_updated_at ON plants;
CREATE TRIGGER update_plants_updated_at
    BEFORE UPDATE ON plants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Función y trigger: calcular next_watering automáticamente
CREATE OR REPLACE FUNCTION calculate_next_watering()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.watering_frequency IS NOT NULL AND NEW.last_watered IS NOT NULL THEN
        NEW.next_watering := NEW.last_watered + (INTERVAL '1 day' * NEW.watering_frequency);
    ELSE
        NEW.next_watering := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS calculate_next_watering_trigger ON plants;
CREATE TRIGGER calculate_next_watering_trigger
    BEFORE INSERT OR UPDATE OF watering_frequency, last_watered ON plants
    FOR EACH ROW
    EXECUTE FUNCTION calculate_next_watering();

-- RLS
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own plants"   ON plants;
CREATE POLICY "Users can view own plants" ON plants
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own plants" ON plants;
CREATE POLICY "Users can insert own plants" ON plants
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own plants" ON plants;
CREATE POLICY "Users can update own plants" ON plants
    FOR UPDATE
    USING     (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own plants" ON plants;
CREATE POLICY "Users can delete own plants" ON plants
    FOR DELETE USING (auth.uid() = user_id);

-- Comentarios de columnas
COMMENT ON COLUMN plants.custom_name         IS 'User-defined custom name for the plant (e.g., "My favorite tomato plant")';
COMMENT ON COLUMN plants.species_id          IS 'Species identifier: local_xxx for catalog, api_xxx for external API';
COMMENT ON COLUMN plants.environment         IS 'Plant environment: indoor or outdoor';
COMMENT ON COLUMN plants.growth_stage        IS 'Current growth phase: germination (just sprouted), seedling (small with few leaves), development (actively growing), mature (full size, stable), flowering (blooming or fruiting)';
COMMENT ON COLUMN plants.pot_size            IS 'Pot size: extra_small(0.5-1.5L), small(1.5-5L), medium(5-15L), large(15-40L), extra_large(40L+)';
COMMENT ON COLUMN plants.last_transplanted   IS 'Last time the user registered a pot transplant for this plant';
COMMENT ON COLUMN plants.species_category    IS 'Cached category from species_catalog for fast filtering';


-- ============================================================================
-- SECCIÓN 4: TABLA soil_analyses
-- ============================================================================

CREATE TABLE IF NOT EXISTS soil_analyses (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plant_id        UUID REFERENCES plants(id) ON DELETE SET NULL,

    image_url       TEXT NOT NULL,
    thumbnail_url   TEXT,

    status          TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'processing', 'completed', 'error')),
    analyzed_at     TIMESTAMPTZ,

    soil_type       TEXT CHECK (soil_type IN (
        'sandy', 'clay', 'silty', 'loamy', 'peaty', 'chalky', 'rocky',
        'pottingMix', 'cactusMix', 'orchidMix', 'unknown'
    )),
    ph_level        DECIMAL(3, 1) CHECK (ph_level IS NULL OR (ph_level >= 0 AND ph_level <= 14)),
    moisture_level  TEXT CHECK (moisture_level IN (
        'veryDry', 'dry', 'slightlyDry', 'optimal', 'moist', 'wet', 'waterlogged'
    )),
    drainage_quality TEXT CHECK (drainage_quality IN (
        'excellent', 'good', 'moderate', 'poor', 'veryPoor'
    )),
    organic_matter  TEXT CHECK (organic_matter IN (
        'veryLow', 'low', 'moderate', 'high', 'veryHigh'
    )),
    recommendations TEXT[],
    analysis_notes  TEXT,

    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_soil_user_id   ON soil_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_soil_plant_id  ON soil_analyses(plant_id) WHERE plant_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_soil_status    ON soil_analyses(status);
CREATE INDEX IF NOT EXISTS idx_soil_user_stat ON soil_analyses(user_id, status);
CREATE INDEX IF NOT EXISTS idx_soil_created   ON soil_analyses(created_at DESC);

DROP TRIGGER IF EXISTS update_soil_analyses_updated_at ON soil_analyses;
CREATE TRIGGER update_soil_analyses_updated_at
    BEFORE UPDATE ON soil_analyses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE soil_analyses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own analyses"   ON soil_analyses;
CREATE POLICY "Users can view own analyses" ON soil_analyses
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own analyses" ON soil_analyses;
CREATE POLICY "Users can insert own analyses" ON soil_analyses
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own analyses" ON soil_analyses;
CREATE POLICY "Users can update own analyses" ON soil_analyses
    FOR UPDATE
    USING     (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own analyses" ON soil_analyses;
CREATE POLICY "Users can delete own analyses" ON soil_analyses
    FOR DELETE USING (auth.uid() = user_id);

-- Funciones auxiliares para Edge Functions
CREATE OR REPLACE FUNCTION update_soil_analysis_results(
    p_analysis_id    UUID,
    p_soil_type      TEXT,
    p_ph_level       DECIMAL,
    p_moisture_level TEXT,
    p_drainage       TEXT,
    p_organic_matter TEXT,
    p_recommendations TEXT[],
    p_notes          TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE soil_analyses SET
        status           = 'completed',
        analyzed_at      = now(),
        soil_type        = p_soil_type,
        ph_level         = p_ph_level,
        moisture_level   = p_moisture_level,
        drainage_quality = p_drainage,
        organic_matter   = p_organic_matter,
        recommendations  = p_recommendations,
        analysis_notes   = p_notes,
        updated_at       = now()
    WHERE id = p_analysis_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION mark_soil_analysis_error(
    p_analysis_id UUID,
    p_error_message TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE soil_analyses SET
        status         = 'error',
        analyzed_at    = now(),
        analysis_notes = p_error_message,
        updated_at     = now()
    WHERE id = p_analysis_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- SECCIÓN 4b: TABLA plant_identifications
-- ============================================================================

CREATE TABLE IF NOT EXISTS plant_identifications (
    id                   UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id              UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    image_url            TEXT NOT NULL,
    thumbnail_url        TEXT,

    status               TEXT NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending', 'processing', 'completed', 'error')),
    analyzed_at          TIMESTAMPTZ,

    common_name          TEXT,
    scientific_name      TEXT,
    family               TEXT,

    care_level           TEXT CHECK (care_level IN ('easy', 'moderate', 'expert')),
    watering_frequency   TEXT CHECK (watering_frequency IN ('daily', 'twiceAWeek', 'weekly', 'biweekly', 'monthly')),
    light_requirement    TEXT CHECK (light_requirement IN ('lowLight', 'indirectLight', 'brightIndirect', 'directSunlight')),
    humidity_requirement TEXT CHECK (humidity_requirement IN ('low', 'moderate', 'high')),

    toxic_to_pets        BOOLEAN,
    toxic_to_humans      BOOLEAN,
    confidence_score     DECIMAL(5,4) CHECK (confidence_score IS NULL OR (confidence_score >= 0 AND confidence_score <= 1)),

    description          TEXT,
    characteristics      TEXT[],
    care_tips            TEXT[],
    analysis_notes       TEXT,

    created_at           TIMESTAMPTZ DEFAULT now(),
    updated_at           TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_plant_id_user_id  ON plant_identifications(user_id);
CREATE INDEX IF NOT EXISTS idx_plant_id_status   ON plant_identifications(status);
CREATE INDEX IF NOT EXISTS idx_plant_id_created  ON plant_identifications(created_at DESC);

DROP TRIGGER IF EXISTS update_plant_identifications_updated_at ON plant_identifications;
CREATE TRIGGER update_plant_identifications_updated_at
    BEFORE UPDATE ON plant_identifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE plant_identifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own plant identifications"   ON plant_identifications;
CREATE POLICY "Users can view own plant identifications" ON plant_identifications
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own plant identifications" ON plant_identifications;
CREATE POLICY "Users can insert own plant identifications" ON plant_identifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own plant identifications" ON plant_identifications;
CREATE POLICY "Users can update own plant identifications" ON plant_identifications
    FOR UPDATE
    USING     (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own plant identifications" ON plant_identifications;
CREATE POLICY "Users can delete own plant identifications" ON plant_identifications
    FOR DELETE USING (auth.uid() = user_id);


-- ============================================================================
-- SECCIÓN 4c: TABLA seed_identifications
-- ============================================================================

CREATE TABLE IF NOT EXISTS seed_identifications (
    id                      UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id                 UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    image_url               TEXT NOT NULL,
    thumbnail_url           TEXT,

    status                  TEXT NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending', 'processing', 'completed', 'error')),
    analyzed_at             TIMESTAMPTZ,

    common_name             TEXT,
    scientific_name         TEXT,
    family                  TEXT,

    germination_difficulty  TEXT CHECK (germination_difficulty IN ('easy', 'moderate', 'difficult', 'veryDifficult')),
    germination_time        TEXT CHECK (germination_time IN (
        'oneToTwoWeeks', 'twoToFourWeeks', 'oneToTwoMonths', 'twoToThreeMonths', 'moreThanThreeMonths'
    )),
    sowing_depth            TEXT CHECK (sowing_depth IN (
        'surfaceSow', 'shallow', 'medium', 'deep'
    )),
    best_sowing_season      TEXT CHECK (best_sowing_season IN (
        'spring', 'summer', 'autumn', 'winter', 'yearRound'
    )),

    confidence_score        DECIMAL(5,4) CHECK (confidence_score IS NULL OR (confidence_score >= 0 AND confidence_score <= 1)),
    description             TEXT,
    germination_tips        TEXT[],
    soil_recommendation     TEXT,
    analysis_notes          TEXT,

    created_at              TIMESTAMPTZ DEFAULT now(),
    updated_at              TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_seed_id_user_id  ON seed_identifications(user_id);
CREATE INDEX IF NOT EXISTS idx_seed_id_status   ON seed_identifications(status);
CREATE INDEX IF NOT EXISTS idx_seed_id_created  ON seed_identifications(created_at DESC);

DROP TRIGGER IF EXISTS update_seed_identifications_updated_at ON seed_identifications;
CREATE TRIGGER update_seed_identifications_updated_at
    BEFORE UPDATE ON seed_identifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE seed_identifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own seed identifications"   ON seed_identifications;
CREATE POLICY "Users can view own seed identifications" ON seed_identifications
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own seed identifications" ON seed_identifications;
CREATE POLICY "Users can insert own seed identifications" ON seed_identifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own seed identifications" ON seed_identifications;
CREATE POLICY "Users can update own seed identifications" ON seed_identifications
    FOR UPDATE
    USING     (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own seed identifications" ON seed_identifications;
CREATE POLICY "Users can delete own seed identifications" ON seed_identifications
    FOR DELETE USING (auth.uid() = user_id);


-- ============================================================================
-- SECCIÓN 5: VISTAS de plantas
-- ============================================================================

CREATE OR REPLACE VIEW plants_needing_water AS
SELECT
    p.*,
    CASE
        WHEN p.next_watering < CURRENT_DATE THEN 'overdue'
        WHEN p.next_watering::date = CURRENT_DATE THEN 'today'
        ELSE 'upcoming'
    END AS watering_status,
    CASE
        WHEN p.next_watering < CURRENT_DATE
            THEN (CURRENT_DATE - p.next_watering::date)
        ELSE (p.next_watering::date - CURRENT_DATE)
    END AS days_difference
FROM plants p
WHERE p.watering_frequency IS NOT NULL
  AND p.next_watering IS NOT NULL
  AND p.next_watering <= CURRENT_DATE + INTERVAL '1 day';

CREATE OR REPLACE VIEW user_plant_stats AS
SELECT
    user_id,
    COUNT(*)                                              AS total_plants,
    COUNT(watering_frequency)                             AS plants_with_watering,
    COUNT(*) FILTER (WHERE next_watering <= CURRENT_DATE) AS plants_needing_water
FROM plants
GROUP BY user_id;

CREATE OR REPLACE VIEW completed_soil_analyses AS
SELECT
    sa.*,
    p.name AS plant_name,
    CASE
        WHEN sa.ph_level < 5.5 THEN 'Ácido'
        WHEN sa.ph_level < 6.5 THEN 'Ligeramente ácido'
        WHEN sa.ph_level < 7.5 THEN 'Neutro'
        ELSE 'Alcalino'
    END AS ph_description
FROM soil_analyses sa
LEFT JOIN plants p ON sa.plant_id = p.id
WHERE sa.status = 'completed';

CREATE OR REPLACE VIEW pending_soil_analyses AS
SELECT
    sa.*,
    p.name AS plant_name,
    EXTRACT(EPOCH FROM (now() - sa.created_at)) / 3600 AS hours_pending
FROM soil_analyses sa
LEFT JOIN plants p ON sa.plant_id = p.id
WHERE sa.status IN ('pending', 'processing')
ORDER BY sa.created_at ASC;


-- ============================================================================
-- SECCIÓN 6: MARKETPLACE
-- ============================================================================

-- [FIX-2] category usa los valores del enum Dart: cutting|plant|substrate|tool
-- [FIX-3] status usa los valores del enum Dart: active|reserved|sold|inactive

CREATE TABLE IF NOT EXISTS marketplace_listings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    seller_name     TEXT,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    -- [FIX-2] Valores alineados con ListingCategory enum en Dart
    category        TEXT NOT NULL DEFAULT 'plant'
        CHECK (category IN ('cutting', 'plant', 'substrate', 'tool')),
    photo_urls      TEXT[] DEFAULT '{}',
    listing_type    TEXT NOT NULL DEFAULT 'sale'
        CHECK (listing_type IN ('sale', 'trade', 'giveaway')),
    price           DOUBLE PRECISION,
    trade_for       TEXT,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    location_name   TEXT,
    -- [FIX-3] Valores alineados con ListingStatus enum en Dart
    status          TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'reserved', 'sold', 'inactive')),
    view_count      INTEGER DEFAULT 0,
    favorite_count  INTEGER DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    expires_at      TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days')
);

CREATE INDEX IF NOT EXISTS idx_marketplace_seller   ON marketplace_listings(seller_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_status   ON marketplace_listings(status);
CREATE INDEX IF NOT EXISTS idx_marketplace_category ON marketplace_listings(category);
CREATE INDEX IF NOT EXISTS idx_marketplace_location ON marketplace_listings(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_marketplace_created  ON marketplace_listings(created_at DESC);

CREATE TABLE IF NOT EXISTS marketplace_favorites (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    listing_id  UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, listing_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user    ON marketplace_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_listing ON marketplace_favorites(listing_id);

DROP TRIGGER IF EXISTS update_marketplace_listings_updated_at ON marketplace_listings;
CREATE TRIGGER update_marketplace_listings_updated_at
    BEFORE UPDATE ON marketplace_listings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS Marketplace
ALTER TABLE marketplace_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_favorites ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado ve anuncios activos + los suyos propios
DROP POLICY IF EXISTS "Anyone can read active listings" ON marketplace_listings;
CREATE POLICY "Anyone can read active listings" ON marketplace_listings
    FOR SELECT
    USING (status = 'active' OR seller_id = auth.uid());

DROP POLICY IF EXISTS "Users can create own listings" ON marketplace_listings;
CREATE POLICY "Users can create own listings" ON marketplace_listings
    FOR INSERT WITH CHECK (seller_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own listings" ON marketplace_listings;
CREATE POLICY "Users can update own listings" ON marketplace_listings
    FOR UPDATE
    USING     (seller_id = auth.uid())
    WITH CHECK (seller_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own listings" ON marketplace_listings;
CREATE POLICY "Users can delete own listings" ON marketplace_listings
    FOR DELETE USING (seller_id = auth.uid());

DROP POLICY IF EXISTS "Users can read own favorites"   ON marketplace_favorites;
CREATE POLICY "Users can read own favorites" ON marketplace_favorites
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own favorites" ON marketplace_favorites;
CREATE POLICY "Users can insert own favorites" ON marketplace_favorites
    FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own favorites" ON marketplace_favorites;
CREATE POLICY "Users can delete own favorites" ON marketplace_favorites
    FOR DELETE USING (user_id = auth.uid());

-- ============================================================================
-- FUNCIÓN RPC: get_nearby_listings
-- [FIX-4] Añade is_favorited para que MarketplaceListingModel.fromJson funcione
-- ============================================================================

CREATE OR REPLACE FUNCTION get_nearby_listings(
    p_latitude      DOUBLE PRECISION,
    p_longitude     DOUBLE PRECISION,
    p_radius_km     DOUBLE PRECISION DEFAULT 10.0,
    p_limit         INTEGER          DEFAULT 50,
    p_offset        INTEGER          DEFAULT 0,
    p_categories    TEXT[]           DEFAULT NULL,
    p_listing_types TEXT[]           DEFAULT NULL,
    p_max_price     DOUBLE PRECISION DEFAULT NULL,
    p_search        TEXT             DEFAULT NULL,
    p_include_sold  BOOLEAN          DEFAULT FALSE
)
RETURNS TABLE (
    id             UUID,
    seller_id      UUID,
    seller_name    TEXT,
    title          TEXT,
    description    TEXT,
    category       TEXT,
    photo_urls     TEXT[],
    listing_type   TEXT,
    price          DOUBLE PRECISION,
    trade_for      TEXT,
    latitude       DOUBLE PRECISION,
    longitude      DOUBLE PRECISION,
    location_name  TEXT,
    status         TEXT,
    view_count     INTEGER,
    favorite_count INTEGER,
    created_at     TIMESTAMPTZ,
    updated_at     TIMESTAMPTZ,
    expires_at     TIMESTAMPTZ,
    distance_km    DOUBLE PRECISION,
    is_favorited   BOOLEAN   -- [FIX-4]
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ml.id,
        ml.seller_id,
        ml.seller_name,
        ml.title,
        ml.description,
        ml.category,
        ml.photo_urls,
        ml.listing_type,
        ml.price,
        ml.trade_for,
        ml.latitude,
        ml.longitude,
        ml.location_name,
        ml.status,
        ml.view_count,
        ml.favorite_count,
        ml.created_at,
        ml.updated_at,
        ml.expires_at,
        -- Fórmula Haversine
        (6371.0 * acos(
            LEAST(1.0, GREATEST(-1.0,
                cos(radians(p_latitude)) *
                cos(radians(ml.latitude)) *
                cos(radians(ml.longitude) - radians(p_longitude)) +
                sin(radians(p_latitude)) *
                sin(radians(ml.latitude))
            ))
        ))::DOUBLE PRECISION AS distance_km,
        -- [FIX-4] is_favorited
        (mf.id IS NOT NULL) AS is_favorited
    FROM marketplace_listings ml
    LEFT JOIN marketplace_favorites mf
        ON mf.listing_id = ml.id AND mf.user_id = auth.uid()
    WHERE
        (CASE
            WHEN p_include_sold THEN ml.status IN ('active', 'reserved', 'sold')
            ELSE ml.status = 'active'
        END)
        AND (6371.0 * acos(
            LEAST(1.0, GREATEST(-1.0,
                cos(radians(p_latitude)) *
                cos(radians(ml.latitude)) *
                cos(radians(ml.longitude) - radians(p_longitude)) +
                sin(radians(p_latitude)) *
                sin(radians(ml.latitude))
            ))
        )) <= p_radius_km
        AND (p_categories    IS NULL OR ml.category     = ANY(p_categories))
        AND (p_listing_types IS NULL OR ml.listing_type = ANY(p_listing_types))
        AND (p_max_price     IS NULL OR ml.price IS NULL OR ml.price <= p_max_price)
        AND (p_search IS NULL OR p_search = '' OR
             ml.title       ILIKE '%' || p_search || '%' OR
             ml.description ILIKE '%' || p_search || '%')
    ORDER BY distance_km ASC, ml.created_at DESC
    LIMIT  p_limit
    OFFSET p_offset;
END;
$$;

-- Función: incrementar vistas
CREATE OR REPLACE FUNCTION increment_listing_views(p_listing_id UUID)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE marketplace_listings
    SET view_count = view_count + 1
    WHERE id = p_listing_id;
END;
$$;

-- Función: toggle favorito (retorna TRUE si ahora es favorito)
CREATE OR REPLACE FUNCTION toggle_listing_favorite(p_user_id UUID, p_listing_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    existing_id      UUID;
    is_now_favorited BOOLEAN;
BEGIN
    SELECT mf.id INTO existing_id
    FROM marketplace_favorites mf
    WHERE mf.user_id = p_user_id AND mf.listing_id = p_listing_id;

    IF existing_id IS NOT NULL THEN
        DELETE FROM marketplace_favorites WHERE id = existing_id;
        UPDATE marketplace_listings
        SET favorite_count = GREATEST(favorite_count - 1, 0)
        WHERE id = p_listing_id;
        is_now_favorited := FALSE;
    ELSE
        INSERT INTO marketplace_favorites (user_id, listing_id)
        VALUES (p_user_id, p_listing_id);
        UPDATE marketplace_listings
        SET favorite_count = favorite_count + 1
        WHERE id = p_listing_id;
        is_now_favorited := TRUE;
    END IF;

    RETURN is_now_favorited;
END;
$$;

-- Función: estadísticas del marketplace por área
CREATE OR REPLACE FUNCTION get_marketplace_statistics(
    p_latitude  DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 10.0
)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE result JSON;
BEGIN
    SELECT json_build_object(
        'total_active', COUNT(*) FILTER (WHERE status = 'active'),
        'total_sold',   COUNT(*) FILTER (WHERE status = 'sold'),
        'by_category', json_build_object(
            'plant',     COUNT(*) FILTER (WHERE category = 'plant'     AND status = 'active'),
            'cutting',   COUNT(*) FILTER (WHERE category = 'cutting'   AND status = 'active'),
            'substrate', COUNT(*) FILTER (WHERE category = 'substrate' AND status = 'active'),
            'tool',      COUNT(*) FILTER (WHERE category = 'tool'      AND status = 'active')
        ),
        'by_type', json_build_object(
            'sale',     COUNT(*) FILTER (WHERE listing_type = 'sale'     AND status = 'active'),
            'trade',    COUNT(*) FILTER (WHERE listing_type = 'trade'    AND status = 'active'),
            'giveaway', COUNT(*) FILTER (WHERE listing_type = 'giveaway' AND status = 'active')
        )
    ) INTO result
    FROM marketplace_listings
    WHERE (6371.0 * acos(
        LEAST(1.0, GREATEST(-1.0,
            cos(radians(p_latitude)) * cos(radians(latitude)) *
            cos(radians(longitude) - radians(p_longitude)) +
            sin(radians(p_latitude)) * sin(radians(latitude))
        ))
    )) <= p_radius_km;
    RETURN result;
END;
$$;


-- ============================================================================
-- SECCIÓN 7: PLANT DISEASE DIAGNOSES
-- ============================================================================
-- Tabla para diagnósticos de enfermedades/plagas generados por IA.
-- El análisis se realiza en cliente (OpenRouter) y los resultados
-- se persisten aquí.  Los remedios se almacenan como JSONB.

CREATE TABLE IF NOT EXISTS plant_disease_diagnoses (
    id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id          UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plant_id         UUID REFERENCES plants(id) ON DELETE SET NULL,

    -- Image stored in 'disease-photos' bucket
    image_url        TEXT NOT NULL,
    thumbnail_url    TEXT,

    -- Diagnosis status
    status           TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'analyzing', 'completed', 'error')),
    analyzed_at      TIMESTAMPTZ,

    -- AI results
    diagnosis_type   TEXT
        CHECK (diagnosis_type IS NULL OR diagnosis_type IN (
            'pest', 'disease', 'deficiency', 'environmentalStress', 'healthy', 'unknown'
        )),
    problem_name     TEXT,
    scientific_name  TEXT,
    severity         TEXT
        CHECK (severity IS NULL OR severity IN ('low', 'medium', 'high', 'critical')),
    confidence_score DOUBLE PRECISION CHECK (confidence_score IS NULL OR (confidence_score >= 0 AND confidence_score <= 1)),

    description      TEXT,
    remedies         JSONB NOT NULL DEFAULT '[]'::jsonb,
    prevention_tips  TEXT,
    analysis_notes   TEXT,

    -- Metadata
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_disease_diagnoses_user_id    ON plant_disease_diagnoses(user_id);
CREATE INDEX IF NOT EXISTS idx_disease_diagnoses_plant_id   ON plant_disease_diagnoses(plant_id);
CREATE INDEX IF NOT EXISTS idx_disease_diagnoses_status     ON plant_disease_diagnoses(status);
CREATE INDEX IF NOT EXISTS idx_disease_diagnoses_created_at ON plant_disease_diagnoses(created_at DESC);

-- RLS
ALTER TABLE plant_disease_diagnoses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own diagnoses"   ON plant_disease_diagnoses;
DROP POLICY IF EXISTS "Users can insert own diagnoses" ON plant_disease_diagnoses;
DROP POLICY IF EXISTS "Users can update own diagnoses" ON plant_disease_diagnoses;
DROP POLICY IF EXISTS "Users can delete own diagnoses" ON plant_disease_diagnoses;

CREATE POLICY "Users can read own diagnoses" ON plant_disease_diagnoses
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own diagnoses" ON plant_disease_diagnoses
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own diagnoses" ON plant_disease_diagnoses
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own diagnoses" ON plant_disease_diagnoses
    FOR DELETE USING (auth.uid() = user_id);

DROP TRIGGER IF EXISTS update_plant_disease_diagnoses_updated_at ON plant_disease_diagnoses;
CREATE TRIGGER update_plant_disease_diagnoses_updated_at
    BEFORE UPDATE ON plant_disease_diagnoses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- SECCIÓN 8: PEST ALERTS
-- ============================================================================

-- [FIX-5] lat/lon como DOUBLE PRECISION (igual que marketplace, más simple)

CREATE TABLE IF NOT EXISTS public.pest_alerts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    photo_url           TEXT,
    pest_type           TEXT NOT NULL,
    custom_pest_name    TEXT,
    severity            TEXT NOT NULL DEFAULT 'medium'
        CHECK (severity IN ('low', 'medium', 'high', 'critical')),

    -- [FIX-5] DOUBLE PRECISION (el Dart los lee como double)
    latitude            DOUBLE PRECISION NOT NULL,
    longitude           DOUBLE PRECISION NOT NULL,
    location_name       TEXT,

    notes               TEXT,

    status              TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'underReview', 'resolved', 'falsePositive', 'duplicate')),
    confirmed_by_count  INTEGER NOT NULL DEFAULT 0,
    is_resolved         BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at         TIMESTAMPTZ,

    reported_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ,

    CONSTRAINT valid_latitude  CHECK (latitude  BETWEEN -90  AND 90),
    CONSTRAINT valid_longitude CHECK (longitude BETWEEN -180 AND 180)
);

CREATE INDEX IF NOT EXISTS idx_pest_alerts_user_id     ON public.pest_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_reported_at ON public.pest_alerts(reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_pest_type   ON public.pest_alerts(pest_type);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_severity    ON public.pest_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_status      ON public.pest_alerts(status);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_is_resolved ON public.pest_alerts(is_resolved);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_location
    ON public.pest_alerts(latitude, longitude)
    WHERE is_resolved = FALSE AND status = 'active';

CREATE TABLE IF NOT EXISTS public.pest_alert_confirmations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id     UUID NOT NULL REFERENCES public.pest_alerts(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    confirmed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_user_alert_confirmation UNIQUE (alert_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_pest_confirm_alert  ON public.pest_alert_confirmations(alert_id);
CREATE INDEX IF NOT EXISTS idx_pest_confirm_user   ON public.pest_alert_confirmations(user_id);

-- RLS pest_alerts
ALTER TABLE public.pest_alerts ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede leer alertas activas
DROP POLICY IF EXISTS "Authenticated users can view active alerts" ON public.pest_alerts;
CREATE POLICY "Authenticated users can view active alerts" ON public.pest_alerts
    FOR SELECT
    USING (auth.uid() IS NOT NULL AND (status = 'active' OR user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can insert own alerts" ON public.pest_alerts;
CREATE POLICY "Users can insert own alerts" ON public.pest_alerts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- [FIX-10] WITH CHECK añadido
DROP POLICY IF EXISTS "Users can update own alerts" ON public.pest_alerts;
CREATE POLICY "Users can update own alerts" ON public.pest_alerts
    FOR UPDATE
    USING     (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own alerts" ON public.pest_alerts;
CREATE POLICY "Users can delete own alerts" ON public.pest_alerts
    FOR DELETE USING (auth.uid() = user_id);

-- RLS confirmaciones
ALTER TABLE public.pest_alert_confirmations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Auth users can read confirmations" ON public.pest_alert_confirmations;
CREATE POLICY "Auth users can read confirmations" ON public.pest_alert_confirmations
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Auth users can confirm alerts" ON public.pest_alert_confirmations;
CREATE POLICY "Auth users can confirm alerts" ON public.pest_alert_confirmations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own confirmations" ON public.pest_alert_confirmations;
CREATE POLICY "Users can delete own confirmations" ON public.pest_alert_confirmations
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- FUNCIÓN RPC: get_nearby_pest_alerts
-- [FIX-6] Reescrita con CTE en lugar de HAVING sin GROUP BY
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_nearby_pest_alerts(
    p_latitude       DECIMAL,
    p_longitude      DECIMAL,
    p_radius_km      DECIMAL  DEFAULT 10.0,
    p_limit          INTEGER  DEFAULT 50,
    p_offset         INTEGER  DEFAULT 0,
    p_days_limit     INTEGER  DEFAULT NULL,
    p_pest_types     TEXT[]   DEFAULT NULL,
    p_severities     TEXT[]   DEFAULT NULL,
    p_include_resolved BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    id                 UUID,
    user_id            UUID,
    photo_url          TEXT,
    pest_type          TEXT,
    custom_pest_name   TEXT,
    severity           TEXT,
    latitude           DOUBLE PRECISION,
    longitude          DOUBLE PRECISION,
    location_name      TEXT,
    notes              TEXT,
    status             TEXT,
    confirmed_by_count INTEGER,
    is_resolved        BOOLEAN,
    resolved_at        TIMESTAMPTZ,
    reported_at        TIMESTAMPTZ,
    updated_at         TIMESTAMPTZ,
    distance_km        DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    earth_radius_km CONSTANT DECIMAL := 6371.0;
    cutoff_date TIMESTAMPTZ;
BEGIN
    IF p_days_limit IS NOT NULL THEN
        cutoff_date := now() - (p_days_limit || ' days')::INTERVAL;
    END IF;

    -- [FIX-6] CTE con distance calculado, luego filtro en WHERE externo
    RETURN QUERY
    WITH candidates AS (
        SELECT
            pa.id,
            pa.user_id,
            pa.photo_url,
            pa.pest_type,
            pa.custom_pest_name,
            pa.severity,
            pa.latitude::DOUBLE PRECISION,
            pa.longitude::DOUBLE PRECISION,
            pa.location_name,
            pa.notes,
            pa.status,
            pa.confirmed_by_count,
            pa.is_resolved,
            pa.resolved_at,
            pa.reported_at,
            pa.updated_at,
            ROUND((
                earth_radius_km * 2.0 * ASIN(
                    SQRT(
                        POWER(SIN(RADIANS(pa.latitude  - p_latitude)  / 2.0), 2) +
                        COS(RADIANS(p_latitude)) * COS(RADIANS(pa.latitude)) *
                        POWER(SIN(RADIANS(pa.longitude - p_longitude) / 2.0), 2)
                    )
                )
            )::DECIMAL, 3) AS distance_km
        FROM public.pest_alerts pa
        WHERE
            (p_days_limit  IS NULL OR pa.reported_at >= cutoff_date)
            AND (p_pest_types IS NULL OR pa.pest_type = ANY(p_pest_types))
            AND (p_severities IS NULL OR pa.severity  = ANY(p_severities))
            AND (p_include_resolved OR pa.is_resolved = FALSE)
            AND pa.status = 'active'
            -- Bounding box aproximada para usar índice lat/lon
            AND pa.latitude  BETWEEN (p_latitude  - p_radius_km / 111.0)
                                 AND (p_latitude  + p_radius_km / 111.0)
            AND pa.longitude BETWEEN (p_longitude - p_radius_km / (111.0 * COS(RADIANS(p_latitude))))
                                 AND (p_longitude + p_radius_km / (111.0 * COS(RADIANS(p_latitude))))
    )
    SELECT *
    FROM candidates
    WHERE distance_km <= p_radius_km   -- [FIX-6] Filtro exacto en WHERE, no HAVING
    ORDER BY distance_km ASC, reported_at DESC
    LIMIT  p_limit
    OFFSET p_offset;
END;
$$;

COMMENT ON FUNCTION public.get_nearby_pest_alerts IS
'Returns active pest alerts within the given radius, ordered by distance. Uses Haversine formula with bounding-box pre-filter for performance.';

-- Función: estadísticas de alertas en un área
CREATE OR REPLACE FUNCTION public.get_pest_alerts_statistics(
    p_latitude  DECIMAL,
    p_longitude DECIMAL,
    p_radius_km DECIMAL  DEFAULT 10.0,
    p_days_limit INTEGER DEFAULT 30
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    result JSONB;
    cutoff_date TIMESTAMPTZ;
BEGIN
    cutoff_date := now() - (p_days_limit || ' days')::INTERVAL;
    SELECT jsonb_build_object(
        'total',           COUNT(*),
        'active',          COUNT(*) FILTER (WHERE is_resolved = FALSE),
        'resolved',        COUNT(*) FILTER (WHERE is_resolved = TRUE),
        'by_severity', jsonb_build_object(
            'low',      COUNT(*) FILTER (WHERE severity = 'low'),
            'medium',   COUNT(*) FILTER (WHERE severity = 'medium'),
            'high',     COUNT(*) FILTER (WHERE severity = 'high'),
            'critical', COUNT(*) FILTER (WHERE severity = 'critical')
        ),
        'by_pest_type', (
            SELECT jsonb_object_agg(pest_type, cnt)
            FROM (
                SELECT pest_type, COUNT(*) AS cnt
                FROM public.pest_alerts pa2
                WHERE pa2.reported_at >= cutoff_date
                  AND (6371.0 * acos(
                        LEAST(1.0, GREATEST(-1.0,
                          cos(radians(p_latitude::DOUBLE PRECISION)) * cos(radians(pa2.latitude)) *
                          cos(radians(pa2.longitude) - radians(p_longitude::DOUBLE PRECISION)) +
                          sin(radians(p_latitude::DOUBLE PRECISION)) * sin(radians(pa2.latitude))
                        ))
                  )) <= p_radius_km::DOUBLE PRECISION
                GROUP BY pest_type
            ) sub
        )
    ) INTO result
    FROM public.pest_alerts pa
    WHERE pa.reported_at >= cutoff_date
      AND (6371.0 * acos(
            LEAST(1.0, GREATEST(-1.0,
              cos(radians(p_latitude::DOUBLE PRECISION)) * cos(radians(pa.latitude)) *
              cos(radians(pa.longitude) - radians(p_longitude::DOUBLE PRECISION)) +
              sin(radians(p_latitude::DOUBLE PRECISION)) * sin(radians(pa.latitude))
            ))
      )) <= p_radius_km::DOUBLE PRECISION;
    RETURN result;
END;
$$;


-- ============================================================================
-- SECCIÓN 8: STORAGE — BUCKETS Y POLÍTICAS
-- ============================================================================
-- [FIX-9] Los buckets se crean aquí en lugar de requerir pasos manuales.
-- Los INSERT son idempotentes gracias a ON CONFLICT DO NOTHING.

INSERT INTO storage.buckets (id, name, public)
VALUES
    ('plant-images',       'plant-images',       TRUE),
    ('soil-images',        'soil-images',        TRUE),
    ('pest-photos',        'pest-photos',        TRUE),
    ('marketplace-photos', 'marketplace-photos', TRUE),
    ('disease-photos',     'disease-photos',     TRUE),
    ('plant-id-photos',    'plant-id-photos',    TRUE),
    ('seed-id-photos',     'seed-id-photos',     TRUE)
ON CONFLICT (id) DO NOTHING;

-- ---- plant-images ----
DROP POLICY IF EXISTS "Public read plant images"       ON storage.objects;
DROP POLICY IF EXISTS "Auth users upload plant images" ON storage.objects;
DROP POLICY IF EXISTS "Users update own plant images"  ON storage.objects;
DROP POLICY IF EXISTS "Users delete own plant images"  ON storage.objects;

CREATE POLICY "Public read plant images" ON storage.objects
    FOR SELECT USING (bucket_id = 'plant-images');
CREATE POLICY "Auth users upload plant images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'plant-images' AND auth.role() = 'authenticated');
CREATE POLICY "Users update own plant images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'plant-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users delete own plant images" ON storage.objects
    FOR DELETE USING (bucket_id = 'plant-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- soil-images ----
DROP POLICY IF EXISTS "Public read soil images"       ON storage.objects;
DROP POLICY IF EXISTS "Auth users upload soil images" ON storage.objects;
DROP POLICY IF EXISTS "Users update own soil images"  ON storage.objects;
DROP POLICY IF EXISTS "Users delete own soil images"  ON storage.objects;

CREATE POLICY "Public read soil images" ON storage.objects
    FOR SELECT USING (bucket_id = 'soil-images');
CREATE POLICY "Auth users upload soil images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'soil-images' AND auth.role() = 'authenticated');
CREATE POLICY "Users update own soil images" ON storage.objects
    FOR UPDATE USING (bucket_id = 'soil-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users delete own soil images" ON storage.objects
    FOR DELETE USING (bucket_id = 'soil-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- pest-photos ----
DROP POLICY IF EXISTS "Public read pest photos"       ON storage.objects;
DROP POLICY IF EXISTS "Auth users upload pest photos" ON storage.objects;
DROP POLICY IF EXISTS "Users update own pest photos"  ON storage.objects;
DROP POLICY IF EXISTS "Users delete own pest photos"  ON storage.objects;

CREATE POLICY "Public read pest photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'pest-photos');
CREATE POLICY "Auth users upload pest photos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'pest-photos' AND auth.role() = 'authenticated');
CREATE POLICY "Users update own pest photos" ON storage.objects
    FOR UPDATE USING (bucket_id = 'pest-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users delete own pest photos" ON storage.objects
    FOR DELETE USING (bucket_id = 'pest-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- marketplace-photos ----
DROP POLICY IF EXISTS "Public read marketplace photos"       ON storage.objects;
DROP POLICY IF EXISTS "Auth users upload marketplace photos" ON storage.objects;
DROP POLICY IF EXISTS "Users update own marketplace photos"  ON storage.objects;
DROP POLICY IF EXISTS "Users delete own marketplace photos"  ON storage.objects;

CREATE POLICY "Public read marketplace photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'marketplace-photos');
CREATE POLICY "Auth users upload marketplace photos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'marketplace-photos' AND auth.role() = 'authenticated');
CREATE POLICY "Users update own marketplace photos" ON storage.objects
    FOR UPDATE USING (bucket_id = 'marketplace-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users delete own marketplace photos" ON storage.objects
    FOR DELETE USING (bucket_id = 'marketplace-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- disease-photos ----
DROP POLICY IF EXISTS "Public read disease photos"       ON storage.objects;
DROP POLICY IF EXISTS "Auth users upload disease photos" ON storage.objects;
DROP POLICY IF EXISTS "Users update own disease photos"  ON storage.objects;
DROP POLICY IF EXISTS "Users delete own disease photos"  ON storage.objects;

CREATE POLICY "Public read disease photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'disease-photos');
CREATE POLICY "Auth users upload disease photos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'disease-photos' AND auth.role() = 'authenticated');
CREATE POLICY "Users update own disease photos" ON storage.objects
    FOR UPDATE USING (bucket_id = 'disease-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users delete own disease photos" ON storage.objects
    FOR DELETE USING (bucket_id = 'disease-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- plant-id-photos ----
DROP POLICY IF EXISTS "Public read plant id photos"       ON storage.objects;
DROP POLICY IF EXISTS "Auth users upload plant id photos" ON storage.objects;
DROP POLICY IF EXISTS "Users update own plant id photos"  ON storage.objects;
DROP POLICY IF EXISTS "Users delete own plant id photos"  ON storage.objects;

CREATE POLICY "Public read plant id photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'plant-id-photos');
CREATE POLICY "Auth users upload plant id photos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'plant-id-photos' AND auth.role() = 'authenticated');
CREATE POLICY "Users update own plant id photos" ON storage.objects
    FOR UPDATE USING (bucket_id = 'plant-id-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users delete own plant id photos" ON storage.objects
    FOR DELETE USING (bucket_id = 'plant-id-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ---- seed-id-photos ----
DROP POLICY IF EXISTS "Public read seed id photos"       ON storage.objects;
DROP POLICY IF EXISTS "Auth users upload seed id photos" ON storage.objects;
DROP POLICY IF EXISTS "Users update own seed id photos"  ON storage.objects;
DROP POLICY IF EXISTS "Users delete own seed id photos"  ON storage.objects;

CREATE POLICY "Public read seed id photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'seed-id-photos');
CREATE POLICY "Auth users upload seed id photos" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'seed-id-photos' AND auth.role() = 'authenticated');
CREATE POLICY "Users update own seed id photos" ON storage.objects
    FOR UPDATE USING (bucket_id = 'seed-id-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users delete own seed id photos" ON storage.objects
    FOR DELETE USING (bucket_id = 'seed-id-photos' AND auth.uid()::text = (storage.foldername(name))[1]);


-- ============================================================================
-- SECCIÓN 9: SEED DATA — CATÁLOGO DE ESPECIES
-- ============================================================================
-- Incluye todas las especies de las migraciones 004 y 007,
-- con transplant_schedule según local_species_catalog.dart

-- Plantas de interior
INSERT INTO species_catalog (id, common_name, scientific_name, category, is_edible,
    watering_frequency_indoor, watering_frequency_outdoor,
    sunlight_hours_min, sunlight_hours_max, sunlight_level,
    min_temperature, max_temperature, drought_tolerant, humidity_loving,
    hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days,
    growth_phases, transplant_schedule)
VALUES
('local_monstera','Monstera','Monstera deliciosa','indoor',FALSE, 7,5, 4,6,'medium', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":18},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12}]'),

('local_pothos','Pothos','Epipremnum aureum','indoor',FALSE, 7,5, 2,6,'low', 5,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":8},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":8},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_snake_plant','Lengua de suegra','Sansevieria trifasciata','indoor',FALSE, 14,10, 2,8,'low', 5,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":12},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":24}]'),

('local_peace_lily','Espatifilo','Spathiphyllum wallisii','indoor',FALSE, 5,4, 2,5,'low', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":10},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_ficus','Ficus','Ficus elastica','indoor',FALSE, 7,5, 4,8,'high', 5,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"adult","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":24}]'),

('local_aloe','Aloe vera','Aloe barbadensis','succulent',FALSE, 14,10, 6,10,'full_sun', 5,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":12},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":24}]'),

('local_spider_plant','Cinta','Chlorophytum comosum','indoor',FALSE, 7,5, 3,6,'medium', 5,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":6},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":8},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_calathea','Calathea','Calathea orbifolia','indoor',FALSE, 5,3, 2,5,'low', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":10},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_philodendron','Filodendro','Philodendron hederaceum','indoor',FALSE, 7,5, 3,6,'medium', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":8},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_zz_plant','Planta ZZ','Zamioculcas zamiifolia','indoor',FALSE, 14,10, 2,6,'low', 5,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":18},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":8},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":18},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":36}]'),

-- Suculentas y cactus
('local_cactus','Cactus','Cactaceae','succulent',FALSE, 21,14, 6,12,'full_sun', 0,45,TRUE,FALSE, 0.8,2.0,5,
    '[{"stage":"seedling","duration_months":12},{"stage":"juvenile","duration_months":36},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":12},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":24},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":36}]'),

('local_echeveria','Echeveria','Echeveria elegans','succulent',FALSE, 14,10, 6,10,'full_sun', 5,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":8},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"extra_small","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":12},{"stage":"adult","min_pot_size":"small","ideal_pot_size":"small","trigger_after_months":24}]'),

('local_jade','Planta de jade','Crassula ovata','succulent',FALSE, 14,10, 4,8,'high', 5,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":18},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":36}]'),

('local_succulent','Suculenta','Sempervivum spp.','succulent',FALSE, 14,10, 5,10,'full_sun', -10,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":6},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"extra_small","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":12},{"stage":"adult","min_pot_size":"small","ideal_pot_size":"small","trigger_after_months":24}]'),

-- Plantas al aire libre
('local_tomato','Tomate','Solanum lycopersicum','outdoor',TRUE, 3,2, 6,10,'full_sun', 10,35,FALSE,FALSE, 0.5,1.5,1,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_basil','Albahaca','Ocimum basilicum','outdoor',TRUE, 3,2, 6,8,'full_sun', 10,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"small","trigger_after_months":999}]'),

('local_rosemary','Romero','Rosmarinus officinalis','outdoor',TRUE, 10,7, 6,10,'full_sun', -5,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":12},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":999}]'),

('local_lavender','Lavanda','Lavandula angustifolia','outdoor',FALSE, 10,7, 6,10,'full_sun', -10,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":12},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":999}]'),

('local_mint','Menta','Mentha spicata','outdoor',TRUE, 3,2, 4,6,'medium', -5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":999}]'),

('local_rose','Rosa','Rosa spp.','outdoor',FALSE, 5,3, 6,10,'full_sun', -10,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"adult","min_pot_size":"large","ideal_pot_size":"large","trigger_after_months":24}]'),

('local_pepper','Pimiento','Capsicum annuum','outdoor',TRUE, 3,2, 6,10,'full_sun', 12,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_strawberry','Fresa','Fragaria x ananassa','outdoor',TRUE, 3,2, 6,8,'full_sun', -5,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":3},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":999}]'),

('local_geranium','Geranio','Pelargonium spp.','outdoor',FALSE, 5,3, 6,10,'full_sun', 2,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":4},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":8},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":18}]'),

('local_parsley','Perejil','Petroselinum crispum','outdoor',TRUE, 3,2, 4,6,'medium', -5,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"small","trigger_after_months":999}]'),

('local_lettuce','Lechuga','Lactuca sativa','outdoor',TRUE, 2,2, 4,6,'medium', 0,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":999},{"stage":"adult","min_pot_size":"small","ideal_pot_size":"small","trigger_after_months":999}]'),

-- Otras de interior (de 007)
('local_orchid','Orquidea','Phalaenopsis spp.','indoor',FALSE, 7,5, 3,6,'medium', 15,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":12},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":12},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":24},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":999}]'),

('local_fiddle_leaf','Ficus lyrata','Ficus lyrata','indoor',FALSE, 7,5, 5,8,'high', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"adult","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":24}]'),

('local_rubber_plant','Arbol del caucho','Ficus elastica','indoor',FALSE, 7,5, 4,8,'high', 5,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"adult","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":24}]'),

('local_boston_fern','Helecho de Boston','Nephrolepis exaltata','indoor',FALSE, 4,3, 2,5,'low', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":8},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":10},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_dracaena','Dracena','Dracaena marginata','indoor',FALSE, 10,7, 3,6,'medium', 5,35,TRUE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"juvenile","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18},{"stage":"adult","min_pot_size":"large","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_croton','Croton','Codiaeum variegatum','indoor',FALSE, 5,4, 5,8,'high', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":10},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_pilea','Pilea','Pilea peperomioides','indoor',FALSE, 7,5, 4,6,'medium', 5,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":6},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":8},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":18}]'),

('local_bamboo','Bambu de la suerte','Dracaena sanderiana','indoor',FALSE, 7,5, 2,5,'low', 5,35,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":6},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":10},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"medium","trigger_after_months":999}]'),

('local_anthurium','Anturio','Anthurium andraeanum','indoor',FALSE, 5,4, 3,6,'medium', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":10},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_bonsai','Bonsai (Ficus)','Ficus retusa','indoor',FALSE, 4,3, 4,8,'high', 5,35,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":12},{"stage":"juvenile","duration_months":60},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":12},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":24},{"stage":"adult","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":60}]'),

-- Cannabis (parent)
('local_cannabis','Cannabis','Cannabis sativa','cannabis',FALSE, 3,2, 8,12,'full_sun', 15,30,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]')

ON CONFLICT (id) DO UPDATE SET
    common_name                = EXCLUDED.common_name,
    scientific_name            = EXCLUDED.scientific_name,
    is_edible                  = EXCLUDED.is_edible,
    watering_frequency_indoor  = EXCLUDED.watering_frequency_indoor,
    watering_frequency_outdoor = EXCLUDED.watering_frequency_outdoor,
    sunlight_hours_min         = EXCLUDED.sunlight_hours_min,
    sunlight_hours_max         = EXCLUDED.sunlight_hours_max,
    sunlight_level             = EXCLUDED.sunlight_level,
    drought_tolerant           = EXCLUDED.drought_tolerant,
    humidity_loving            = EXCLUDED.humidity_loving,
    hot_weather_multiplier     = EXCLUDED.hot_weather_multiplier,
    cold_weather_multiplier    = EXCLUDED.cold_weather_multiplier,
    rain_reduction_days        = EXCLUDED.rain_reduction_days,
    growth_phases              = EXCLUDED.growth_phases,
    transplant_schedule        = EXCLUDED.transplant_schedule,
    updated_at                 = NOW();

-- Cannabis variedades
INSERT INTO species_catalog (id, parent_id, common_name, scientific_name, description,
    category, is_edible,
    watering_frequency_indoor, watering_frequency_outdoor,
    sunlight_hours_min, sunlight_hours_max, sunlight_level,
    min_temperature, max_temperature, drought_tolerant, humidity_loving,
    hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days,
    growth_phases, transplant_schedule)
VALUES
('local_cannabis_critical','local_cannabis','Critical','Cannabis sativa (Critical)',
    'Indica dominante (70/30). Alta produccion, floracion rapida (7-8 semanas). Resistente a moho. [CORR: es indica, no sativa]',
    'cannabis',FALSE, 2,2, 10,12,'full_sun', 18,28,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_og_kush','local_cannabis','OG Kush','Cannabis sativa (OG Kush)',
    'Indica dominante (75/25). Aroma a pino/limon. Floracion 8-9 semanas. Control de humedad en floracion. [CORR: es indica, no sativa]',
    'cannabis',FALSE, 2,2, 10,12,'full_sun', 20,28,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_northern_lights','local_cannabis','Northern Lights','Cannabis indica (Northern Lights)',
    'Indica pura clasica. Muy resistente, ideal para principiantes.',
    'cannabis',FALSE, 3,2, 8,12,'full_sun', 16,28,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_gorilla_glue','local_cannabis','Gorilla Glue (GG4)','Cannabis sativa (Gorilla Glue #4)',
    'Hibrida equilibrada (50/50), muy resinosa. Alta potencia THC. Floracion 8-9 semanas. [CORR: es hibrida equilibrada]',
    'cannabis',FALSE, 2,2, 10,12,'full_sun', 18,30,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_white_widow','local_cannabis','White Widow','Cannabis sativa (White Widow)',
    'Hibrida equilibrada (60/40 indica). Muy resinosa. Floracion 8-9 semanas. Resistente al frio. [CORR: es hibrida, no sativa]',
    'cannabis',FALSE, 3,2, 8,12,'full_sun', 16,28,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_amnesia_haze','local_cannabis','Amnesia Haze','Cannabis sativa (Amnesia Haze)',
    'Sativa dominante (80/20). Floracion larga 10-12 semanas.',
    'cannabis',FALSE, 2,2, 10,14,'full_sun', 20,30,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_jack_herer','local_cannabis','Jack Herer','Cannabis sativa (Jack Herer)',
    'Sativa dominante clasica. Aroma a pino/especias. Floracion 9-10 semanas.',
    'cannabis',FALSE, 2,2, 10,14,'full_sun', 18,30,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_sour_diesel','local_cannabis','Sour Diesel','Cannabis sativa (Sour Diesel)',
    'Sativa 90/10. Aroma diesel/citrico intenso. Floracion 10-11 semanas.',
    'cannabis',FALSE, 2,2, 10,14,'full_sun', 20,32,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_gelato','local_cannabis','Gelato','Cannabis sativa (Gelato)',
    'Indica dominante (55/45). Aroma dulce/helado. Floracion 8-9 semanas. Colores purpura. [CORR: es indica-dominante, no sativa]',
    'cannabis',FALSE, 2,2, 10,12,'full_sun', 18,28,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_wedding_cake','local_cannabis','Wedding Cake','Cannabis sativa (Wedding Cake)',
    'Indica dominante (cruce GSC x Cherry Pie). Muy resinosa y potente. Floracion 9-10 semanas.',
    'cannabis',FALSE, 2,2, 10,12,'full_sun', 18,28,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_blue_cheese','local_cannabis','Blue Cheese','Cannabis indica (Blue Cheese)',
    'Indica dominante (80/20). Aroma queso/berry. Floracion 8 semanas.',
    'cannabis',FALSE, 3,2, 8,12,'full_sun', 16,26,FALSE,TRUE, 0.6,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_granddaddy_purple','local_cannabis','Granddaddy Purple','Cannabis indica (Granddaddy Purple)',
    'Indica pura, colores purpura. Floracion 8-9 semanas.',
    'cannabis',FALSE, 3,2, 8,10,'full_sun', 14,26,FALSE,TRUE, 0.6,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

('local_cannabis_super_lemon_haze','local_cannabis','Super Lemon Haze','Cannabis sativa (Super Lemon Haze)',
    'Sativa dominante. Aroma citrico intenso. Floracion 9-10 semanas.',
    'cannabis',FALSE, 2,2, 10,14,'full_sun', 20,30,FALSE,TRUE, 0.5,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":2},{"stage":"juvenile","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":999}]'),

-- ---- NUEVAS VARIEDADES (batch 3 — 22 variedades de cannabis) ----
-- Indica / Hibridas indica-dominante
('local_cannabis_gsc','local_cannabis','Girl Scout Cookies (GSC)','Cannabis sativa (GSC)',
    'Hibrida indica dominante muy potente. Aromas dulces y terrosos. Floracion 9-10 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_zkittlez','local_cannabis','Zkittlez','Cannabis sativa (Zkittlez)',
    'Indica dominante de sabor afrutado tipo caramelo. Planta compacta. Floracion 8-9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_runtz','local_cannabis','Runtz','Cannabis sativa (Runtz)',
    'Hibrida equilibrada (Zkittlez x Gelato). Muy resinosa y dulce. Floracion 8-9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_gelato_41','local_cannabis','Gelato 41','Cannabis sativa (Gelato 41)',
    'Fenotipo de Gelato, indica dominante. Mas potente y resinoso. Floracion 8-9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_do_si_dos','local_cannabis','Do-Si-Dos','Cannabis sativa (Do-Si-Dos)',
    'Indica dominante derivada de GSC. Muy potente y resinosa. Efecto sedante. Floracion 9-10 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_bubba_kush','local_cannabis','Bubba Kush','Cannabis indica (Bubba Kush)',
    'Indica clasica de efecto sedante. Aroma a cafe y chocolate. Planta baja y robusta. Floracion 8 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_critical_kush','local_cannabis','Critical Kush','Cannabis sativa (Critical Kush)',
    'Cruce Critical x OG Kush. Indica dominante muy productiva y potente. Floracion 8 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_blueberry','local_cannabis','Blueberry','Cannabis sativa (Blueberry)',
    'Indica clasica de aroma a arandano con tonos azulados. Efecto relajante duradero. Floracion 8-9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 10,30,FALSE,FALSE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_hindu_kush','local_cannabis','Hindu Kush','Cannabis indica (Hindu Kush)',
    'Indica pura landrace de la cordillera Hindu Kush. Muy resinosa, efecto corporal fuerte. Resistente a climas secos. Floracion 8 semanas.',
    'cannabis',FALSE, 3,2, 6,12,'full_sun', 10,32,TRUE,FALSE, 0.8,1.5,3,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
-- Hibridas / Sativa dominante
('local_cannabis_bruce_banner','local_cannabis','Bruce Banner','Cannabis sativa (Bruce Banner)',
    'Hibrida sativa dominante (OG Kush x Strawberry Diesel). Muy alta en THC, efecto energetico. Floracion 9-10 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_ak47','local_cannabis','AK-47','Cannabis sativa (AK-47)',
    'Hibrida sativa dominante premiada. Efecto cerebral relajante. Aroma terroso-floral. Floracion 8-9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_pineapple_express','local_cannabis','Pineapple Express','Cannabis sativa (Pineapple Express)',
    'Hibrida sativa dominante de aroma tropical (pina). Efecto equilibrado y duradero. Floracion 8 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_trainwreck','local_cannabis','Trainwreck','Cannabis sativa (Trainwreck)',
    'Hibrida sativa dominante. Efecto cerebral intenso y rapido. Aroma a limon y pino. Floracion 8 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_cheese','local_cannabis','Cheese (UK Cheese)','Cannabis sativa (Cheese)',
    'Hibrida fenotipo de Skunk. Aroma intenso a queso. Relacionada con Blue Cheese. Floracion 8-9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_skunk1','local_cannabis','Skunk #1','Cannabis sativa (Skunk #1)',
    'Hibrida fundacional de la genetica moderna, muy estable y productiva. Floracion 8 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
-- Sativas puras
('local_cannabis_green_crack','local_cannabis','Green Crack','Cannabis sativa (Green Crack)',
    'Sativa muy energizante de aroma citrico-mango. Gran produccion. Floracion 7-9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,32,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_durban_poison','local_cannabis','Durban Poison','Cannabis sativa (Durban Poison)',
    'Sativa pura sudafricana (landrace). Efecto cerebral y energetico. Aroma anisado. Resistente al calor. Floracion 8-9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,34,TRUE,FALSE, 0.8,1.5,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_purple_haze','local_cannabis','Purple Haze','Cannabis sativa (Purple Haze)',
    'Sativa clasica con tonos purpura y efecto cerebral creativo. Aroma dulce-terroso. Floracion 9-10 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),
('local_cannabis_strawberry_cough','local_cannabis','Strawberry Cough','Cannabis sativa (Strawberry Cough)',
    'Sativa dominante de aroma a fresa. Efecto euforico y social. Floracion 9 semanas.',
    'cannabis',FALSE, 2,2, 6,12,'full_sun', 12,30,FALSE,FALSE, 0.7,1.4,2,
    '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1},{"stage":"juvenile","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]')

ON CONFLICT (id) DO UPDATE SET
    description            = EXCLUDED.description,
    transplant_schedule    = EXCLUDED.transplant_schedule,
    updated_at             = NOW();


-- ============================================================================
-- SECCIÓN 9b: NUEVAS ESPECIES (batch 2 — 30 plantas)
-- Sincronizado con local_species_catalog.dart commit 8543a5c
-- ============================================================================

-- Nuevas plantas de interior
INSERT INTO species_catalog (id, common_name, scientific_name, category, is_edible,
    watering_frequency_indoor, watering_frequency_outdoor,
    sunlight_hours_min, sunlight_hours_max, sunlight_level,
    min_temperature, max_temperature, drought_tolerant, humidity_loving,
    hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days,
    description, growth_phases, transplant_schedule)
VALUES
('local_areca','Palmera areca','Dypsis lutescens','indoor',FALSE, 4,3, 4,6,'high', 10,35,FALSE,TRUE, 0.7,1.5,2,
    'Palmera de interior muy popular, purificadora del aire, con hojas plumosas de color verde brillante.',
    '[{"stage":"seedling","duration_months":6},{"stage":"development","duration_months":18},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":24,"notes":"Trasplanta cada 2 anos en primavera"}]'),

('local_singonio','Singonio','Syngonium podophyllum','indoor',FALSE, 4,3, 3,6,'high', 12,32,FALSE,TRUE, 0.7,1.5,2,
    'Trepadora de hojas en forma de flecha que cambian de tono al madurar. Muy facil de cuidar.',
    '[{"stage":"seedling","duration_months":3},{"stage":"development","duration_months":9},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"mature","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18,"notes":"Trasplanta cuando las raices salgan por el drenaje"}]'),

('local_fitonia','Fitonia','Fittonia albivenis','indoor',FALSE, 3,2, 3,5,'medium', 15,30,FALSE,TRUE, 0.6,1.5,1,
    'Planta compacta de hojas nervadas en blanco o rosa. Ideal para terrarios por su amor a la humedad.',
    '[{"stage":"seedling","duration_months":2},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":3},{"stage":"mature","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":12}]'),

('local_collar_corazones','Collar de corazones','Ceropegia woodii','indoor',FALSE, 10,8, 4,6,'high', 10,32,TRUE,FALSE, 0.8,1.5,2,
    'Colgante de hojas en forma de corazon con vetas plateadas. Semisuculenta, tolera el olvido.',
    '[{"stage":"seedling","duration_months":3},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"mature","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":24}]'),

('local_aglaonema','Aglaonema','Aglaonema commutatum','indoor',FALSE, 5,4, 2,5,'low', 13,32,FALSE,TRUE, 0.7,1.5,2,
    'Hojas vistosas en verde, plata o rosa. Una de las plantas de interior mas tolerantes a la poca luz.',
    '[{"stage":"seedling","duration_months":4},{"stage":"development","duration_months":12},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"mature","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":24,"notes":"Trasplanta cada 2 anos"}]'),

('local_cafeto','Cafeto','Coffea arabica','indoor',TRUE, 4,3, 4,6,'high', 15,30,FALSE,TRUE, 0.7,1.6,2,
    'Arbusto de hojas brillantes que produce granos de cafe. Necesita humedad y luz indirecta brillante.',
    '[{"stage":"germination","duration_months":2},{"stage":"seedling","duration_months":6},{"stage":"development","duration_months":24},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":8},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":24}]')

ON CONFLICT (id) DO UPDATE SET
    common_name                = EXCLUDED.common_name,
    scientific_name            = EXCLUDED.scientific_name,
    category                   = EXCLUDED.category,
    is_edible                  = EXCLUDED.is_edible,
    watering_frequency_indoor  = EXCLUDED.watering_frequency_indoor,
    watering_frequency_outdoor = EXCLUDED.watering_frequency_outdoor,
    sunlight_hours_min         = EXCLUDED.sunlight_hours_min,
    sunlight_hours_max         = EXCLUDED.sunlight_hours_max,
    sunlight_level             = EXCLUDED.sunlight_level,
    min_temperature            = EXCLUDED.min_temperature,
    max_temperature            = EXCLUDED.max_temperature,
    drought_tolerant           = EXCLUDED.drought_tolerant,
    humidity_loving            = EXCLUDED.humidity_loving,
    hot_weather_multiplier     = EXCLUDED.hot_weather_multiplier,
    cold_weather_multiplier    = EXCLUDED.cold_weather_multiplier,
    rain_reduction_days        = EXCLUDED.rain_reduction_days,
    description                = EXCLUDED.description,
    growth_phases              = EXCLUDED.growth_phases,
    transplant_schedule        = EXCLUDED.transplant_schedule,
    updated_at                 = NOW();

-- Monstera adansonii (variedad de local_monstera)
INSERT INTO species_catalog (id, parent_id, common_name, scientific_name, description,
    category, is_edible,
    watering_frequency_indoor, watering_frequency_outdoor,
    sunlight_hours_min, sunlight_hours_max, sunlight_level,
    min_temperature, max_temperature, drought_tolerant, humidity_loving,
    hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days,
    growth_phases, transplant_schedule)
VALUES
('local_monstera_adansonii','local_monstera','Monstera adansonii','Monstera adansonii',
    'Variedad del genero Monstera. Hojas mas pequenas con perforaciones internas; ideal colgante o trepadora.',
    'indoor',FALSE, 5,4, 4,6,'high', 13,32,FALSE,TRUE, 0.7,1.5,2,
    '[{"stage":"seedling","duration_months":4},{"stage":"development","duration_months":12},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":6},{"stage":"mature","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":24}]')
ON CONFLICT (id) DO UPDATE SET
    description         = EXCLUDED.description,
    transplant_schedule = EXCLUDED.transplant_schedule,
    updated_at          = NOW();

-- Nuevas suculentas
INSERT INTO species_catalog (id, common_name, scientific_name, category, is_edible,
    watering_frequency_indoor, watering_frequency_outdoor,
    sunlight_hours_min, sunlight_hours_max, sunlight_level,
    min_temperature, max_temperature, drought_tolerant, humidity_loving,
    hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days,
    description, growth_phases, transplant_schedule)
VALUES
('local_kalanchoe','Kalanchoe','Kalanchoe blossfeldiana','succulent',FALSE, 8,6, 5,8,'full_sun', 7,35,TRUE,FALSE, 0.8,1.5,3,
    'Suculenta de floracion vistosa y duradera en racimos de colores. Muy resistente a la sequia.',
    '[{"stage":"seedling","duration_months":3},{"stage":"development","duration_months":6},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":4},{"stage":"mature","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":18}]'),

('local_agave','Agave','Agave americana','succulent',FALSE, 14,10, 6,10,'full_sun', -5,40,TRUE,FALSE, 0.9,1.8,5,
    'Suculenta de gran porte con hojas carnosas y espinosas. Extremadamente resistente a la sequia y al calor.',
    '[{"stage":"seedling","duration_months":12},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":36}]'),

('local_nopal','Nopal (chumbera)','Opuntia ficus-indica','succulent',TRUE, 14,10, 6,12,'full_sun', -2,42,TRUE,FALSE, 0.9,1.8,5,
    'Cactus de palas planas comestibles que produce higos chumbos. Muy resistente a la sequia.',
    '[{"stage":"seedling","duration_months":6},{"stage":"development","duration_months":18},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":36}]'),

('local_aeonium','Aeonium','Aeonium arboreum','succulent',FALSE, 10,7, 5,8,'full_sun', 3,35,TRUE,FALSE, 0.8,1.6,3,
    'Suculenta arbustiva con rosetas en la punta de los tallos; algunas variedades casi negras. Crece en invierno.',
    '[{"stage":"seedling","duration_months":4},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"extra_small","ideal_pot_size":"small","trigger_after_months":6},{"stage":"mature","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":24}]')

ON CONFLICT (id) DO UPDATE SET
    common_name                = EXCLUDED.common_name,
    scientific_name            = EXCLUDED.scientific_name,
    description                = EXCLUDED.description,
    growth_phases              = EXCLUDED.growth_phases,
    transplant_schedule        = EXCLUDED.transplant_schedule,
    updated_at                 = NOW();

-- Nuevas hierbas aromaticas
INSERT INTO species_catalog (id, common_name, scientific_name, category, is_edible,
    watering_frequency_indoor, watering_frequency_outdoor,
    sunlight_hours_min, sunlight_hours_max, sunlight_level,
    min_temperature, max_temperature, drought_tolerant, humidity_loving,
    hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days,
    description, growth_phases, transplant_schedule)
VALUES
('local_salvia','Salvia','Salvia officinalis','herb',TRUE, 4,3, 6,8,'full_sun', -5,35,TRUE,FALSE, 0.7,1.5,3,
    'Hierba aromatica perenne de hojas grisaceas, usada en cocina e infusiones. Resistente y poco exigente.',
    '[{"stage":"germination","duration_months":1},{"stage":"seedling","duration_months":2},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":3},{"stage":"mature","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_estragon','Estragon','Artemisia dracunculus','herb',TRUE, 4,3, 5,8,'full_sun', -10,33,TRUE,FALSE, 0.7,1.5,3,
    'Hierba aromatica de sabor anisado muy apreciada en la cocina francesa. Perenne y resistente al frio.',
    '[{"stage":"seedling","duration_months":2},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":3},{"stage":"mature","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18}]'),

('local_eneldo','Eneldo','Anethum graveolens','herb',TRUE, 3,2, 5,8,'full_sun', 2,32,FALSE,FALSE, 0.6,1.5,2,
    'Hierba anual de hojas finas y plumosas con sabor fresco, ideal para pescados y encurtidos.',
    '[{"stage":"germination","duration_months":1},{"stage":"seedling","duration_months":1},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":2}]'),

('local_laurel','Laurel','Laurus nobilis','herb',TRUE, 6,4, 5,8,'full_sun', -5,38,TRUE,FALSE, 0.7,1.5,3,
    'Arbol o arbusto perenne de hojas aromaticas usadas en cocina. Muy longevo y resistente.',
    '[{"stage":"seedling","duration_months":6},{"stage":"development","duration_months":24},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":8},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":36}]')

ON CONFLICT (id) DO UPDATE SET
    common_name                = EXCLUDED.common_name,
    scientific_name            = EXCLUDED.scientific_name,
    description                = EXCLUDED.description,
    growth_phases              = EXCLUDED.growth_phases,
    transplant_schedule        = EXCLUDED.transplant_schedule,
    updated_at                 = NOW();

-- Nuevas hortalizas y verduras
INSERT INTO species_catalog (id, common_name, scientific_name, category, is_edible,
    watering_frequency_indoor, watering_frequency_outdoor,
    sunlight_hours_min, sunlight_hours_max, sunlight_level,
    min_temperature, max_temperature, drought_tolerant, humidity_loving,
    hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days,
    description, growth_phases, transplant_schedule)
VALUES
('local_patata','Patata','Solanum tuberosum','vegetable',TRUE, 3,2, 6,8,'full_sun', 5,30,FALSE,FALSE, 0.7,1.4,2,
    'Tuberculo de cultivo sencillo. Se planta a partir de patatas de siembra y se cosecha en pocos meses.',
    '[{"stage":"germination","duration_months":1},{"stage":"development","duration_months":2},{"stage":"flowering","duration_months":1},{"stage":"mature","duration_months":0}]',
    '[{"stage":"development","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1,"notes":"Cultivar en saco o maceta profunda"}]'),

('local_brocoli','Brocoli','Brassica oleracea var. italica','vegetable',TRUE, 3,2, 6,8,'full_sun', 0,28,FALSE,FALSE, 0.6,1.4,2,
    'Hortaliza de clima fresco cuyos brotes florales se cosechan antes de abrir.',
    '[{"stage":"germination","duration_months":1},{"stage":"seedling","duration_months":1},{"stage":"development","duration_months":2},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"large","trigger_after_months":1}]'),

('local_acelga','Acelga','Beta vulgaris var. cicla','vegetable',TRUE, 3,2, 5,7,'full_sun', 0,30,FALSE,FALSE, 0.6,1.4,2,
    'Hortaliza de hoja muy productiva y resistente; se cosecha repetidamente cortando las hojas externas.',
    '[{"stage":"germination","duration_months":1},{"stage":"development","duration_months":2},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1}]'),

('local_rucula','Rucula','Eruca vesicaria','vegetable',TRUE, 2,2, 4,6,'medium', 2,28,FALSE,FALSE, 0.6,1.4,1,
    'Hoja de sabor picante de crecimiento muy rapido, lista para cosechar en pocas semanas.',
    '[{"stage":"germination","duration_months":1},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":1}]'),

('local_rabano','Rabano','Raphanus sativus','vegetable',TRUE, 2,2, 5,7,'full_sun', 3,28,FALSE,FALSE, 0.6,1.4,1,
    'Raiz de cultivo rapidisimo (3-4 semanas), perfecta para iniciarse en el huerto.',
    '[{"stage":"germination","duration_months":1},{"stage":"mature","duration_months":0}]',
    '[{"stage":"germination","min_pot_size":"small","ideal_pot_size":"medium","trigger_after_months":0,"notes":"Sembrar directo, no trasplantar"}]')

ON CONFLICT (id) DO UPDATE SET
    common_name                = EXCLUDED.common_name,
    scientific_name            = EXCLUDED.scientific_name,
    description                = EXCLUDED.description,
    growth_phases              = EXCLUDED.growth_phases,
    transplant_schedule        = EXCLUDED.transplant_schedule,
    updated_at                 = NOW();

-- Nuevos frutales y ornamentales de exterior
INSERT INTO species_catalog (id, common_name, scientific_name, category, is_edible,
    watering_frequency_indoor, watering_frequency_outdoor,
    sunlight_hours_min, sunlight_hours_max, sunlight_level,
    min_temperature, max_temperature, drought_tolerant, humidity_loving,
    hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days,
    description, growth_phases, transplant_schedule)
VALUES
('local_naranjo','Naranjo','Citrus x sinensis','outdoor',TRUE, 5,4, 6,10,'full_sun', -2,38,FALSE,FALSE, 0.7,1.6,3,
    'Mismo genero (Citrus) que el limonero. Arbol frutal de flores aromaticas (azahar) y naranjas dulces.',
    '[{"stage":"seedling","duration_months":12},{"stage":"development","duration_months":24},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":36}]'),

('local_higuera','Higuera','Ficus carica','outdoor',TRUE, 5,4, 6,10,'full_sun', -10,40,TRUE,FALSE, 0.8,1.6,4,
    'Mismo genero (Ficus) que el caucho, lyrata y bonsai. Arbol caduco que produce higos; muy resistente a la sequia.',
    '[{"stage":"seedling","duration_months":6},{"stage":"development","duration_months":24},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":36}]'),

('local_granado','Granado','Punica granatum','outdoor',TRUE, 6,5, 6,10,'full_sun', -10,40,TRUE,FALSE, 0.8,1.6,4,
    'Arbusto o arbol pequeno de flores rojas vistosas y frutos (granadas) llenos de arilos jugosos.',
    '[{"stage":"seedling","duration_months":8},{"stage":"development","duration_months":24},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":36}]'),

('local_frambueso','Frambueso','Rubus idaeus','outdoor',TRUE, 4,3, 5,8,'full_sun', -20,30,FALSE,FALSE, 0.6,1.5,3,
    'Arbusto de canas bianuales que produce frambuesas dulces y aromaticas en verano.',
    '[{"stage":"seedling","duration_months":4},{"stage":"development","duration_months":8},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":6},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":36}]'),

('local_arandano','Arandano','Vaccinium corymbosum','outdoor',TRUE, 4,3, 5,8,'full_sun', -20,30,FALSE,TRUE, 0.6,1.5,3,
    'Arbusto acido-amante que produce arandanos azules antioxidantes. Necesita sustrato acido (pH 4.5-5.5).',
    '[{"stage":"seedling","duration_months":6},{"stage":"development","duration_months":18},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":48}]'),

('local_caqui','Caqui','Diospyros kaki','outdoor',TRUE, 6,5, 6,10,'full_sun', -15,38,TRUE,FALSE, 0.8,1.6,4,
    'Arbol caduco originario de Asia que produce frutos naranjas muy dulces en otono.',
    '[{"stage":"seedling","duration_months":12},{"stage":"development","duration_months":36},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":48}]'),

('local_vid','Vid (parra)','Vitis vinifera','outdoor',TRUE, 5,4, 6,10,'full_sun', -15,38,TRUE,FALSE, 0.7,1.6,4,
    'Trepadora caduca cultivada desde la antiguedad por sus uvas. Requiere poda y tutor.',
    '[{"stage":"seedling","duration_months":6},{"stage":"development","duration_months":24},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":48}]'),

('local_dahlia','Dalia','Dahlia pinnata','outdoor',FALSE, 3,2, 6,8,'full_sun', 5,30,FALSE,FALSE, 0.6,1.5,2,
    'Tuberculo ornamental con flores espectaculares de multiples formas y colores. Cosecha los tuberculos en otono.',
    '[{"stage":"germination","duration_months":1},{"stage":"development","duration_months":3},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"development","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":1}]'),

('local_peonia','Peonia','Paeonia lactiflora','outdoor',FALSE, 5,4, 5,8,'full_sun', -20,30,FALSE,FALSE, 0.6,1.4,3,
    'Perenne de flores grandes y aromaticas muy vistosas. Longeva, puede vivir decadas en el mismo sitio.',
    '[{"stage":"seedling","duration_months":12},{"stage":"development","duration_months":24},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":18},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":60,"notes":"Evita trasplantar, no le gusta que la muevan"}]'),

('local_wisteria','Glicinia','Wisteria sinensis','outdoor',FALSE, 5,4, 5,8,'full_sun', -20,35,FALSE,FALSE, 0.7,1.5,3,
    'Trepadora vigorosa con grandes racimos de flores lilas aromaticas en primavera.',
    '[{"stage":"seedling","duration_months":12},{"stage":"development","duration_months":36},{"stage":"flowering","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":48}]'),

('local_bambu','Bambu (exterior)','Phyllostachys aurea','outdoor',FALSE, 3,2, 4,8,'high', -15,38,FALSE,TRUE, 0.6,1.5,2,
    'Bambu de exterior de crecimiento rapido, ideal para setos y mamparas naturales. Muy resistente.',
    '[{"stage":"seedling","duration_months":6},{"stage":"development","duration_months":12},{"stage":"mature","duration_months":0}]',
    '[{"stage":"seedling","min_pot_size":"medium","ideal_pot_size":"large","trigger_after_months":12},{"stage":"mature","min_pot_size":"large","ideal_pot_size":"extra_large","trigger_after_months":36}]')

ON CONFLICT (id) DO UPDATE SET
    common_name                = EXCLUDED.common_name,
    scientific_name            = EXCLUDED.scientific_name,
    description                = EXCLUDED.description,
    growth_phases              = EXCLUDED.growth_phases,
    transplant_schedule        = EXCLUDED.transplant_schedule,
    updated_at                 = NOW();

-- ============================================================================
-- SECCIÓN 10: VERIFICACIÓN FINAL
-- ============================================================================

SELECT 'plants'              AS tabla, COUNT(*) AS columnas
FROM information_schema.columns WHERE table_name = 'plants'
UNION ALL
SELECT 'species_catalog',    COUNT(*) FROM information_schema.columns WHERE table_name = 'species_catalog'
UNION ALL
SELECT 'soil_analyses',      COUNT(*) FROM information_schema.columns WHERE table_name = 'soil_analyses'
UNION ALL
SELECT 'marketplace_listings', COUNT(*) FROM information_schema.columns WHERE table_name = 'marketplace_listings'
UNION ALL
SELECT 'marketplace_favorites', COUNT(*) FROM information_schema.columns WHERE table_name = 'marketplace_favorites'
UNION ALL
SELECT 'pest_alerts',        COUNT(*) FROM information_schema.columns WHERE table_name = 'pest_alerts'
UNION ALL
SELECT 'pest_alert_confirmations', COUNT(*) FROM information_schema.columns WHERE table_name = 'pest_alert_confirmations';

SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('plants','soil_analyses','marketplace_listings','marketplace_favorites','pest_alerts','pest_alert_confirmations','species_catalog','objects')
ORDER BY tablename, cmd;

SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
      'update_updated_at_column','calculate_next_watering',
      'update_soil_analysis_results','mark_soil_analysis_error',
      'get_nearby_listings','increment_listing_views','toggle_listing_favorite','get_marketplace_statistics',
      'get_nearby_pest_alerts','get_pest_alerts_statistics'
  )
ORDER BY routine_name;

SELECT COUNT(*) AS species_seed_count FROM species_catalog;

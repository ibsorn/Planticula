-- Migration 004: Species Catalog Table
-- Stores all plant species and varieties in the database
-- Parent-child relationship: parent_id references the parent species

CREATE TABLE IF NOT EXISTS species_catalog (
    id TEXT PRIMARY KEY,
    parent_id TEXT REFERENCES species_catalog(id) ON DELETE CASCADE,
    common_name TEXT NOT NULL,
    scientific_name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,

    -- Watering
    watering_frequency_indoor INTEGER NOT NULL DEFAULT 7,
    watering_frequency_outdoor INTEGER NOT NULL DEFAULT 5,

    -- Sunlight
    sunlight_hours_min DOUBLE PRECISION NOT NULL DEFAULT 4,
    sunlight_hours_max DOUBLE PRECISION NOT NULL DEFAULT 8,
    sunlight_level TEXT NOT NULL DEFAULT 'medium' CHECK (sunlight_level IN ('low', 'medium', 'high', 'full_sun')),

    -- Climate
    min_temperature INTEGER NOT NULL DEFAULT 5,
    max_temperature INTEGER NOT NULL DEFAULT 35,
    drought_tolerant BOOLEAN NOT NULL DEFAULT FALSE,
    humidity_loving BOOLEAN NOT NULL DEFAULT FALSE,

    -- Weather multipliers
    hot_weather_multiplier DOUBLE PRECISION NOT NULL DEFAULT 0.7,
    cold_weather_multiplier DOUBLE PRECISION NOT NULL DEFAULT 1.5,
    rain_reduction_days DOUBLE PRECISION NOT NULL DEFAULT 2,

    -- Growth phases stored as JSONB array
    growth_phases JSONB NOT NULL DEFAULT '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb,

    -- Metadata
    category TEXT, -- e.g. 'indoor', 'succulent', 'outdoor', 'cannabis', etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookup
CREATE INDEX IF NOT EXISTS idx_species_parent ON species_catalog(parent_id);
CREATE INDEX IF NOT EXISTS idx_species_category ON species_catalog(category);
CREATE INDEX IF NOT EXISTS idx_species_common_name ON species_catalog(common_name);

-- Enable RLS but allow public read access (species data is not user-specific)
ALTER TABLE species_catalog ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read species catalog"
    ON species_catalog FOR SELECT
    USING (true);

-- Only service role can insert/update/delete (managed via dashboard or admin)
CREATE POLICY "Service role can manage species"
    ON species_catalog FOR ALL
    USING (auth.role() = 'service_role');

-- Trigger to update updated_at
CREATE TRIGGER update_species_catalog_updated_at
    BEFORE UPDATE ON species_catalog
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SEED DATA: Popular Indoor Plants
-- ============================================================================

INSERT INTO species_catalog (id, common_name, scientific_name, category, watering_frequency_indoor, watering_frequency_outdoor, sunlight_hours_min, sunlight_hours_max, sunlight_level, min_temperature, max_temperature, drought_tolerant, humidity_loving, hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days, growth_phases) VALUES
('local_monstera', 'Monstera', 'Monstera deliciosa', 'indoor', 7, 5, 4, 6, 'medium', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":18},{"stage":"adult","duration_months":0}]'::jsonb),
('local_pothos', 'Pothos', 'Epipremnum aureum', 'indoor', 7, 5, 2, 6, 'low', 5, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":8},{"stage":"adult","duration_months":0}]'::jsonb),
('local_snake_plant', 'Lengua de suegra', 'Sansevieria trifasciata', 'indoor', 14, 10, 2, 8, 'low', 5, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_peace_lily', 'Espatifilo', 'Spathiphyllum wallisii', 'indoor', 5, 4, 2, 5, 'low', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_ficus', 'Ficus', 'Ficus elastica', 'indoor', 7, 5, 4, 8, 'high', 5, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]'::jsonb),
('local_aloe', 'Aloe vera', 'Aloe barbadensis', 'succulent', 14, 10, 6, 10, 'full_sun', 5, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_spider_plant', 'Cinta', 'Chlorophytum comosum', 'indoor', 7, 5, 3, 6, 'medium', 5, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":6},{"stage":"adult","duration_months":0}]'::jsonb),
('local_calathea', 'Calathea', 'Calathea orbifolia', 'indoor', 5, 3, 2, 5, 'low', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_philodendron', 'Filodendro', 'Philodendron hederaceum', 'indoor', 7, 5, 3, 6, 'medium', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_zz_plant', 'Planta ZZ', 'Zamioculcas zamiifolia', 'indoor', 14, 10, 2, 6, 'low', 5, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":18},{"stage":"adult","duration_months":0}]'::jsonb),

-- Succulents & Cacti
('local_cactus', 'Cactus', 'Cactaceae', 'succulent', 21, 14, 6, 12, 'full_sun', 0, 45, TRUE, FALSE, 0.8, 2.0, 5, '[{"stage":"seedling","duration_months":12},{"stage":"juvenile","duration_months":36},{"stage":"adult","duration_months":0}]'::jsonb),
('local_echeveria', 'Echeveria', 'Echeveria elegans', 'succulent', 14, 10, 6, 10, 'full_sun', 5, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":8},{"stage":"adult","duration_months":0}]'::jsonb),
('local_jade', 'Planta de jade', 'Crassula ovata', 'succulent', 14, 10, 4, 8, 'high', 5, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]'::jsonb),

-- Outdoor / Garden
('local_tomato', 'Tomate', 'Solanum lycopersicum', 'outdoor', 3, 2, 6, 10, 'full_sun', 10, 35, FALSE, FALSE, 0.5, 1.5, 1, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]'::jsonb),
('local_basil', 'Albahaca', 'Ocimum basilicum', 'outdoor', 3, 2, 6, 8, 'full_sun', 10, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1},{"stage":"adult","duration_months":0}]'::jsonb),
('local_rosemary', 'Romero', 'Rosmarinus officinalis', 'outdoor', 10, 7, 6, 10, 'full_sun', -5, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_lavender', 'Lavanda', 'Lavandula angustifolia', 'outdoor', 10, 7, 6, 10, 'full_sun', -10, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_mint', 'Menta', 'Mentha spicata', 'outdoor', 3, 2, 4, 6, 'medium', -5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]'::jsonb),
('local_rose', 'Rosa', 'Rosa spp.', 'outdoor', 5, 3, 6, 10, 'full_sun', -10, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_orchid', 'Orquidea', 'Phalaenopsis spp.', 'indoor', 7, 5, 3, 6, 'medium', 15, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":12},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]'::jsonb),
('local_fiddle_leaf', 'Ficus lyrata', 'Ficus lyrata', 'indoor', 7, 5, 5, 8, 'high', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]'::jsonb),
('local_rubber_plant', 'Arbol del caucho', 'Ficus elastica', 'indoor', 7, 5, 4, 8, 'high', 5, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]'::jsonb),
('local_boston_fern', 'Helecho de Boston', 'Nephrolepis exaltata', 'indoor', 4, 3, 2, 5, 'low', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":8},{"stage":"adult","duration_months":0}]'::jsonb),
('local_dracaena', 'Dracena', 'Dracaena marginata', 'indoor', 10, 7, 3, 6, 'medium', 5, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":6},{"stage":"juvenile","duration_months":24},{"stage":"adult","duration_months":0}]'::jsonb),
('local_croton', 'Croton', 'Codiaeum variegatum', 'indoor', 5, 4, 5, 8, 'high', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_pilea', 'Pilea', 'Pilea peperomioides', 'indoor', 7, 5, 4, 6, 'medium', 5, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":6},{"stage":"adult","duration_months":0}]'::jsonb),
('local_pepper', 'Pimiento', 'Capsicum annuum', 'outdoor', 3, 2, 6, 10, 'full_sun', 12, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]'::jsonb),
('local_strawberry', 'Fresa', 'Fragaria x ananassa', 'outdoor', 3, 2, 6, 8, 'full_sun', -5, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":3},{"stage":"adult","duration_months":0}]'::jsonb),
('local_succulent', 'Suculenta', 'Sempervivum spp.', 'succulent', 14, 10, 5, 10, 'full_sun', -10, 35, TRUE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":6},{"stage":"adult","duration_months":0}]'::jsonb),
('local_bamboo', 'Bambu de la suerte', 'Dracaena sanderiana', 'indoor', 7, 5, 2, 5, 'low', 5, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":3},{"stage":"juvenile","duration_months":6},{"stage":"adult","duration_months":0}]'::jsonb),
('local_anthurium', 'Anturio', 'Anthurium andraeanum', 'indoor', 5, 4, 3, 6, 'medium', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":4},{"stage":"juvenile","duration_months":12},{"stage":"adult","duration_months":0}]'::jsonb),
('local_geranium', 'Geranio', 'Pelargonium spp.', 'outdoor', 5, 3, 6, 10, 'full_sun', 2, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":2},{"stage":"juvenile","duration_months":4},{"stage":"adult","duration_months":0}]'::jsonb),
('local_parsley', 'Perejil', 'Petroselinum crispum', 'outdoor', 3, 2, 4, 6, 'medium', -5, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2},{"stage":"adult","duration_months":0}]'::jsonb),
('local_lettuce', 'Lechuga', 'Lactuca sativa', 'outdoor', 2, 2, 4, 6, 'medium', 0, 35, FALSE, FALSE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1},{"stage":"adult","duration_months":0}]'::jsonb),
('local_bonsai', 'Bonsai (Ficus)', 'Ficus retusa', 'indoor', 4, 3, 4, 8, 'high', 5, 35, FALSE, TRUE, 0.7, 1.5, 2, '[{"stage":"seedling","duration_months":12},{"stage":"juvenile","duration_months":60},{"stage":"adult","duration_months":0}]'::jsonb),

-- Cannabis parent species
('local_cannabis', 'Cannabis', 'Cannabis sativa', 'cannabis', 3, 2, 8, 12, 'full_sun', 15, 30, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo"},{"stage":"adult","duration_months":0,"description":"Floracion"}]'::jsonb);

-- ============================================================================
-- SEED DATA: Cannabis Varieties
-- ============================================================================

INSERT INTO species_catalog (id, parent_id, common_name, scientific_name, description, category, watering_frequency_indoor, watering_frequency_outdoor, sunlight_hours_min, sunlight_hours_max, sunlight_level, min_temperature, max_temperature, drought_tolerant, humidity_loving, hot_weather_multiplier, cold_weather_multiplier, rain_reduction_days, growth_phases) VALUES
-- Indica Dominant
('local_cannabis_critical', 'local_cannabis', 'Critical', 'Cannabis sativa (Critical)', 'Indica dominante. Alta produccion, floracion rapida (7-8 semanas). Resistente a moho. Efecto relajante.', 'cannabis', 2, 2, 10, 12, 'full_sun', 18, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1,"description":"Vegetativo 4-5 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 7-8 semanas"}]'::jsonb),
('local_cannabis_og_kush', 'local_cannabis', 'OG Kush', 'Cannabis sativa (OG Kush)', 'Hibrido indica dominante. Aroma a pino/limon. Floracion 8-9 semanas. Necesita control de humedad en floracion.', 'cannabis', 2, 2, 10, 12, 'full_sun', 20, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-6 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 8-9 semanas"}]'::jsonb),
('local_cannabis_northern_lights', 'local_cannabis', 'Northern Lights', 'Cannabis indica (Northern Lights)', 'Indica pura clasica. Muy resistente, ideal para principiantes. Floracion 7-8 semanas. Poco olor durante cultivo.', 'cannabis', 3, 2, 8, 12, 'full_sun', 16, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1,"description":"Vegetativo 4-5 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 7-8 semanas"}]'::jsonb),
('local_cannabis_gorilla_glue', 'local_cannabis', 'Gorilla Glue (GG4)', 'Cannabis sativa (Gorilla Glue #4)', 'Hibrido equilibrado, muy resinoso. Alta potencia THC. Floracion 8-9 semanas. Necesita soporte por peso de cogollos.', 'cannabis', 2, 2, 10, 12, 'full_sun', 18, 30, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-6 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 8-9 semanas"}]'::jsonb),
('local_cannabis_blue_cheese', 'local_cannabis', 'Blue Cheese', 'Cannabis indica (Blue Cheese)', 'Indica dominante (80/20). Aroma queso/berry. Floracion 8 semanas. Compacta, ideal espacios reducidos.', 'cannabis', 3, 2, 8, 12, 'full_sun', 16, 26, FALSE, TRUE, 0.6, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":1,"description":"Vegetativo 4-5 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 7-8 semanas"}]'::jsonb),
('local_cannabis_granddaddy_purple', 'local_cannabis', 'Granddaddy Purple', 'Cannabis indica (Granddaddy Purple)', 'Indica pura, colores purpura. Floracion 8-9 semanas. Necesita noches frias para desarrollar color.', 'cannabis', 3, 2, 8, 10, 'full_sun', 14, 26, FALSE, TRUE, 0.6, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-6 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 8-9 semanas"}]'::jsonb),

-- Sativa Dominant
('local_cannabis_amnesia_haze', 'local_cannabis', 'Amnesia Haze', 'Cannabis sativa (Amnesia Haze)', 'Sativa dominante (80/20). Floracion larga 10-12 semanas. Crece mucho en altura, necesita poda apical. Efecto cerebral.', 'cannabis', 2, 2, 10, 14, 'full_sun', 20, 30, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 6-8 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 10-12 semanas"}]'::jsonb),
('local_cannabis_jack_herer', 'local_cannabis', 'Jack Herer', 'Cannabis sativa (Jack Herer)', 'Sativa dominante clasica. Aroma a pino/especias. Floracion 9-10 semanas. Buena para SCROG.', 'cannabis', 2, 2, 10, 14, 'full_sun', 18, 30, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-7 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 9-10 semanas"}]'::jsonb),
('local_cannabis_sour_diesel', 'local_cannabis', 'Sour Diesel', 'Cannabis sativa (Sour Diesel)', 'Sativa 90/10. Aroma diesel/citrico intenso. Floracion 10-11 semanas. Crece mucho, ideal exterior.', 'cannabis', 2, 2, 10, 14, 'full_sun', 20, 32, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 6-8 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 10-11 semanas"}]'::jsonb),
('local_cannabis_super_lemon_haze', 'local_cannabis', 'Super Lemon Haze', 'Cannabis sativa (Super Lemon Haze)', 'Sativa dominante. Aroma citrico intenso. Floracion 9-10 semanas. Muy productiva, necesita tutor.', 'cannabis', 2, 2, 10, 14, 'full_sun', 20, 30, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-7 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 9-10 semanas"}]'::jsonb),

-- Hybrid Balanced
('local_cannabis_white_widow', 'local_cannabis', 'White Widow', 'Cannabis sativa (White Widow)', 'Hibrido clasico 60/40. Muy resinosa. Floracion 8-9 semanas. Resistente a plagas y moho.', 'cannabis', 3, 2, 8, 12, 'full_sun', 16, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-6 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 8-9 semanas"}]'::jsonb),
('local_cannabis_wedding_cake', 'local_cannabis', 'Wedding Cake', 'Cannabis sativa (Wedding Cake)', 'Hibrido indica-dominante. THC muy alto (25%+). Floracion 7-9 semanas. Aroma dulce/vainilla.', 'cannabis', 2, 2, 10, 12, 'full_sun', 18, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-6 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 7-9 semanas"}]'::jsonb),
('local_cannabis_gelato', 'local_cannabis', 'Gelato', 'Cannabis sativa (Gelato)', 'Hibrido equilibrado. Sabor dulce/helado. Floracion 8-9 semanas. Colores purpura, alta resina.', 'cannabis', 2, 2, 10, 12, 'full_sun', 18, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-6 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 8-9 semanas"}]'::jsonb),
('local_cannabis_girl_scout_cookies', 'local_cannabis', 'Girl Scout Cookies (GSC)', 'Cannabis sativa (GSC)', 'Hibrido indica dominante. THC alto. Floracion 9-10 semanas. Aroma dulce/terroso. Mediana altura.', 'cannabis', 2, 2, 10, 12, 'full_sun', 18, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 5-7 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 9-10 semanas"}]'::jsonb),
('local_cannabis_skunk', 'local_cannabis', 'Skunk #1', 'Cannabis sativa (Skunk #1)', 'Hibrido clasico equilibrado. Muy estable y facil de cultivar. Floracion 8-9 semanas. Olor intenso.', 'cannabis', 3, 2, 8, 12, 'full_sun', 16, 30, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 4-6 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 8-9 semanas"}]'::jsonb),
('local_cannabis_ak47', 'local_cannabis', 'AK-47', 'Cannabis sativa (AK-47)', 'Sativa dominante (65/35). Floracion corta para sativa: 7-9 semanas. Aroma floral/terroso. Facil cultivo.', 'cannabis', 3, 2, 10, 12, 'full_sun', 18, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1},{"stage":"juvenile","duration_months":2,"description":"Vegetativo 4-6 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 7-9 semanas"}]'::jsonb),

-- Autoflowering
('local_cannabis_auto_critical', 'local_cannabis', 'Critical Auto', 'Cannabis sativa (Critical Auto)', 'Autofloreciente. Ciclo completo 9-10 semanas desde semilla. No depende de fotoperiodo. Ideal principiantes.', 'cannabis', 2, 2, 12, 20, 'full_sun', 18, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1,"description":"Germinacion + seedling 1-2 semanas"},{"stage":"juvenile","duration_months":1,"description":"Vegetativo 3-4 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 5-6 semanas"}]'::jsonb),
('local_cannabis_auto_amnesia', 'local_cannabis', 'Amnesia Haze Auto', 'Cannabis sativa (Amnesia Haze Auto)', 'Autofloreciente sativa. Ciclo 10-12 semanas. Mantiene efecto cerebral. Mas compacta que la fotoperiodica.', 'cannabis', 2, 2, 12, 20, 'full_sun', 18, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1,"description":"Germinacion 1-2 semanas"},{"stage":"juvenile","duration_months":1,"description":"Vegetativo 3-4 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 6-8 semanas"}]'::jsonb),
('local_cannabis_auto_gorilla', 'local_cannabis', 'Gorilla Glue Auto', 'Cannabis sativa (Gorilla Glue Auto)', 'Autofloreciente. Ciclo 10-11 semanas. Muy resinosa. Produccion media-alta para auto.', 'cannabis', 2, 2, 12, 20, 'full_sun', 18, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1,"description":"Germinacion 1-2 semanas"},{"stage":"juvenile","duration_months":1,"description":"Vegetativo 3-4 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 6-7 semanas"}]'::jsonb),
('local_cannabis_auto_northern', 'local_cannabis', 'Northern Lights Auto', 'Cannabis indica (Northern Lights Auto)', 'Autofloreciente indica. Ciclo rapido 8-9 semanas. Discreta, bajo olor. Muy resistente.', 'cannabis', 3, 2, 12, 20, 'full_sun', 16, 28, FALSE, TRUE, 0.5, 1.5, 2, '[{"stage":"seedling","duration_months":1,"description":"Germinacion 1-2 semanas"},{"stage":"juvenile","duration_months":1,"description":"Vegetativo 2-3 semanas"},{"stage":"adult","duration_months":0,"description":"Floracion 5-6 semanas"}]'::jsonb);

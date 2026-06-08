-- ============================================================================
-- MIGRACIÓN INICIAL: PLANTICULA DATABASE SCHEMA
-- ============================================================================
-- Este script crea las tablas necesarias para la app Planticula
-- Ejecutar en: Supabase Dashboard → SQL Editor → New query
-- ============================================================================

-- ============================================================================
-- TABLA: PLANTS (Plantas del usuario)
-- ============================================================================

CREATE TABLE IF NOT EXISTS plants (
    -- Identificadores
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    -- Información básica
    name TEXT NOT NULL CHECK (char_length(name) > 0 AND char_length(name) <= 100),
    scientific_name TEXT CHECK (char_length(scientific_name) <= 100),
    species_id UUID, -- Referencia futura a tabla de especies

    -- Multimedia
    image_url TEXT, -- URL en Storage de Supabase

    -- Ubicación y contexto
    location TEXT CHECK (char_length(location) <= 100),
    notes TEXT CHECK (char_length(notes) <= 2000),

    -- Gestión de riego
    watering_frequency INTEGER CHECK (watering_frequency > 0 AND watering_frequency <= 365),
    last_watered TIMESTAMP WITH TIME ZONE,
    next_watering TIMESTAMP WITH TIME ZONE, -- Calculado automáticamente

    -- Fechas
    acquired_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================================================
-- ÍNDICES PARA MEJORAR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_plants_user_id ON plants(user_id);
CREATE INDEX IF NOT EXISTS idx_plants_name ON plants(name);
CREATE INDEX IF NOT EXISTS idx_plants_next_watering ON plants(next_watering) WHERE next_watering IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plants_user_next_watering ON plants(user_id, next_watering);

-- ============================================================================
-- FUNCIONES Y TRIGGERS
-- ============================================================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para la tabla plants
DROP TRIGGER IF EXISTS update_plants_updated_at ON plants;
CREATE TRIGGER update_plants_updated_at
    BEFORE UPDATE ON plants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Función para calcular next_watering automáticamente
CREATE OR REPLACE FUNCTION calculate_next_watering()
RETURNS TRIGGER AS $$
BEGIN
    -- Si hay frecuencia de riego y fecha de último riego
    IF NEW.watering_frequency IS NOT NULL AND NEW.last_watered IS NOT NULL THEN
        NEW.next_watering := NEW.last_watered + INTERVAL '1 day' * NEW.watering_frequency;
    ELSE
        NEW.next_watering := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para calcular next_watering al insertar o actualizar
DROP TRIGGER IF EXISTS calculate_next_watering_trigger ON plants;
CREATE TRIGGER calculate_next_watering_trigger
    BEFORE INSERT OR UPDATE OF watering_frequency, last_watered ON plants
    FOR EACH ROW
    EXECUTE FUNCTION calculate_next_watering();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Activar RLS en la tabla
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;

-- Política: Usuarios solo pueden ver sus propias plantas
DROP POLICY IF EXISTS "Users can view own plants" ON plants;
CREATE POLICY "Users can view own plants" ON plants
    FOR SELECT
    USING (auth.uid() = user_id);

-- Política: Usuarios solo pueden insertar sus propias plantas
DROP POLICY IF EXISTS "Users can insert own plants" ON plants;
CREATE POLICY "Users can insert own plants" ON plants
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Política: Usuarios solo pueden actualizar sus propias plantas
DROP POLICY IF EXISTS "Users can update own plants" ON plants;
CREATE POLICY "Users can update own plants" ON plants
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Política: Usuarios solo pueden eliminar sus propias plantas
DROP POLICY IF EXISTS "Users can delete own plants" ON plants;
CREATE POLICY "Users can delete own plants" ON plants
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- VISTAS ÚTILES
-- ============================================================================

-- Vista: Plantas que necesitan riego hoy
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

-- Vista: Estadísticas de plantas por usuario
CREATE OR REPLACE VIEW user_plant_stats AS
SELECT
    user_id,
    COUNT(*) as total_plants,
    COUNT(watering_frequency) as plants_with_watering,
    COUNT(*) FILTER (WHERE next_watering <= CURRENT_DATE) as plants_needing_water
FROM plants
GROUP BY user_id;

-- ============================================================================
-- DATOS DE EJEMPLO (OPCIONAL - Solo para desarrollo)
-- ============================================================================

-- Nota: Descomentar solo para desarrollo local
-- INSERT INTO plants (user_id, name, scientific_name, location, watering_frequency, last_watered, acquired_date, notes)
-- VALUES
--     ('00000000-0000-0000-0000-000000000000', 'Monstera', 'Monstera deliciosa', 'Sala de estar', 7, now() - INTERVAL '3 days', '2024-01-15', 'Planta favorita de la casa'),
--     ('00000000-0000-0000-0000-000000000000', 'Pothos', 'Epipremnum aureum', 'Cocina', 5, now() - INTERVAL '1 day', '2024-02-01', 'Muy resistente'),
--     ('00000000-0000-0000-0000-000000000000', 'Cactus San Pedro', 'Echinopsis pachanoi', 'Terraza', 14, now() - INTERVAL '10 days', '2023-11-20', 'No regar en invierno');

-- ============================================================================
-- VERIFICACIÓN DE INSTALACIÓN
-- ============================================================================

-- Verificar que la tabla existe con la estructura correcta
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'plants'
ORDER BY ordinal_position;

-- Verificar índices creados
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'plants';

-- Verificar políticas RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'plants';

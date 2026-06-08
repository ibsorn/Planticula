-- ============================================================================
-- MIGRACIÓN 002: TABLA SOIL_ANALYSES
-- ============================================================================
-- Tabla para almacenar análisis de sustrato/suelo
-- Flujo: imagen subida -> análisis pendiente -> Edge Function -> resultados
-- ============================================================================

-- ============================================================================
-- TABLA: SOIL_ANALYSES
-- ============================================================================

CREATE TABLE IF NOT EXISTS soil_analyses (
    -- Identificadores
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    plant_id UUID REFERENCES plants(id) ON DELETE SET NULL, -- Opcional, puede ser NULL

    -- Información de la imagen
    image_url TEXT NOT NULL, -- URL pública en Storage
    thumbnail_url TEXT, -- URL de miniatura (opcional)

    -- Estado del análisis
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'processing', 'completed', 'error')),
    analyzed_at TIMESTAMP WITH TIME ZONE, -- Cuándo se completó el análisis

    -- Resultados del análisis (poblados por Edge Function)
    soil_type TEXT CHECK (soil_type IN (
        'sandy', 'clay', 'silty', 'loamy', 'peaty', 'chalky', 'rocky',
        'pottingMix', 'cactusMix', 'orchidMix', 'unknown'
    )),
    ph_level DECIMAL(3, 1) CHECK (ph_level >= 0 AND ph_level <= 14),
    moisture_level TEXT CHECK (moisture_level IN (
        'veryDry', 'dry', 'slightlyDry', 'optimal', 'moist', 'wet', 'waterlogged'
    )),
    drainage_quality TEXT CHECK (drainage_quality IN (
        'excellent', 'good', 'moderate', 'poor', 'veryPoor'
    )),
    organic_matter TEXT CHECK (organic_matter IN (
        'veryLow', 'low', 'moderate', 'high', 'veryHigh'
    )),
    recommendations TEXT[], -- Array de recomendaciones
    analysis_notes TEXT, -- Notas adicionales o mensaje de error

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================================================
-- ÍNDICES PARA MEJORAR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_soil_analyses_user_id ON soil_analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_soil_analyses_plant_id ON soil_analyses(plant_id) WHERE plant_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_soil_analyses_status ON soil_analyses(status);
CREATE INDEX IF NOT EXISTS idx_soil_analyses_user_status ON soil_analyses(user_id, status);
CREATE INDEX IF NOT EXISTS idx_soil_analyses_created_at ON soil_analyses(created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Actualizar updated_at automáticamente
DROP TRIGGER IF EXISTS update_soil_analyses_updated_at ON soil_analyses;
CREATE TRIGGER update_soil_analyses_updated_at
    BEFORE UPDATE ON soil_analyses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Activar RLS
ALTER TABLE soil_analyses ENABLE ROW LEVEL SECURITY;

-- Política: Usuarios solo pueden ver sus propios análisis
DROP POLICY IF EXISTS "Users can view own analyses" ON soil_analyses;
CREATE POLICY "Users can view own analyses" ON soil_analyses
    FOR SELECT
    USING (auth.uid() = user_id);

-- Política: Usuarios solo pueden insertar sus propios análisis
DROP POLICY IF EXISTS "Users can insert own analyses" ON soil_analyses;
CREATE POLICY "Users can insert own analyses" ON soil_analyses
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Política: Usuarios solo pueden actualizar sus propios análisis
DROP POLICY IF EXISTS "Users can update own analyses" ON soil_analyses;
CREATE POLICY "Users can update own analyses" ON soil_analyses
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Política: Usuarios solo pueden eliminar sus propios análisis
DROP POLICY IF EXISTS "Users can delete own analyses" ON soil_analyses;
CREATE POLICY "Users can delete own analyses" ON soil_analyses
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- VISTAS ÚTILES
-- ============================================================================

-- Vista: Análisis completados con información resumida
CREATE OR REPLACE VIEW completed_soil_analyses AS
SELECT
    sa.*,
    p.name as plant_name,
    CASE
        WHEN sa.ph_level < 5.5 THEN 'Ácido'
        WHEN sa.ph_level < 6.5 THEN 'Ligeramente ácido'
        WHEN sa.ph_level < 7.5 THEN 'Neutro'
        ELSE 'Alcalino'
    END as ph_description
FROM soil_analyses sa
LEFT JOIN plants p ON sa.plant_id = p.id
WHERE sa.status = 'completed';

-- Vista: Análisis pendientes de procesar
CREATE OR REPLACE VIEW pending_soil_analyses AS
SELECT
    sa.*,
    p.name as plant_name,
    EXTRACT(EPOCH FROM (now() - sa.created_at))/3600 as hours_pending
FROM soil_analyses sa
LEFT JOIN plants p ON sa.plant_id = p.id
WHERE sa.status IN ('pending', 'processing')
ORDER BY sa.created_at ASC;

-- ============================================================================
-- FUNCIÓN PARA ACTUALIZAR ESTADO DESDE EDGE FUNCTION
-- ============================================================================

-- Función que puede ser llamada por la Edge Function para actualizar resultados
CREATE OR REPLACE FUNCTION update_soil_analysis_results(
    p_analysis_id UUID,
    p_soil_type TEXT,
    p_ph_level DECIMAL,
    p_moisture_level TEXT,
    p_drainage_quality TEXT,
    p_organic_matter TEXT,
    p_recommendations TEXT[],
    p_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE soil_analyses
    SET
        status = 'completed',
        analyzed_at = now(),
        soil_type = p_soil_type,
        ph_level = p_ph_level,
        moisture_level = p_moisture_level,
        drainage_quality = p_drainage_quality,
        organic_matter = p_organic_matter,
        recommendations = p_recommendations,
        analysis_notes = p_notes,
        updated_at = now()
    WHERE id = p_analysis_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCIÓN PARA MARCAR ERROR DESDE EDGE FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION mark_soil_analysis_error(
    p_analysis_id UUID,
    p_error_message TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE soil_analyses
    SET
        status = 'error',
        analyzed_at = now(),
        analysis_notes = p_error_message,
        updated_at = now()
    WHERE id = p_analysis_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VERIFICACIÓN DE INSTALACIÓN
-- ============================================================================

-- Verificar tabla creada
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'soil_analyses'
ORDER BY ordinal_position;

-- Verificar políticas
SELECT policyname, cmd, qual
FROM pg_policies
WHERE tablename = 'soil_analyses';

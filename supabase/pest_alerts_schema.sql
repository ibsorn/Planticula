-- ============================================================================
-- SCHEMA: pest_alerts
-- ============================================================================
-- Sistema de alertas de plagas basado en ubicación geográfica
-- - Usuarios reportan plagas con foto, ubicación y detalles
-- - Otros usuarios ven alertas cercanas ordenadas por distancia
-- - Filtros por radio, fecha, tipo y severidad
-- ============================================================================

-- ============================================================================
-- 1. TABLA PRINCIPAL: pest_alerts
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pest_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Información de la plaga
    photo_url TEXT,                                    -- URL en Storage
    pest_type TEXT NOT NULL,                           -- Tipo de plaga (enum)
    custom_pest_name TEXT,                             -- Si es "otro", nombre específico
    severity TEXT NOT NULL DEFAULT 'medium',           -- low/medium/high/critical

    -- Ubicación geográfica (requerida para búsquedas espaciales)
    latitude DECIMAL(10, 8) NOT NULL,                  -- -90 a 90
    longitude DECIMAL(11, 8) NOT NULL,                 -- -180 a 180
    location_name TEXT,                                -- Nombre descriptivo opcional

    -- Metadata
    notes TEXT,                                        -- Observaciones del usuario

    -- Estado de la alerta
    status TEXT NOT NULL DEFAULT 'active',             -- active/under_review/resolved/false_positive/duplicate
    confirmed_by_count INTEGER NOT NULL DEFAULT 0,     -- Confirmaciones de otros usuarios
    is_resolved BOOLEAN NOT NULL DEFAULT false,        -- Plaga tratada/eliminada
    resolved_at TIMESTAMPTZ,

    -- Timestamps
    reported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ,

    -- Constraint: coordenadas válidas
    CONSTRAINT valid_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT valid_longitude CHECK (longitude BETWEEN -180 AND 180)
);

-- Índices principales
CREATE INDEX IF NOT EXISTS idx_pest_alerts_user_id ON public.pest_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_reported_at ON public.pest_alerts(reported_at DESC);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_pest_type ON public.pest_alerts(pest_type);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_severity ON public.pest_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_status ON public.pest_alerts(status);
CREATE INDEX IF NOT EXISTS idx_pest_alerts_is_resolved ON public.pest_alerts(is_resolved);

-- Índice compuesto para queries de ubicación
CREATE INDEX IF NOT EXISTS idx_pest_alerts_location
    ON public.pest_alerts(latitude, longitude)
    WHERE is_resolved = false AND status = 'active';

-- ============================================================================
-- 2. TABLA DE CONFIRMACIONES (usuarios que confirman ver la misma plaga)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pest_alert_confirmations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id UUID NOT NULL REFERENCES public.pest_alerts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    confirmed_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Un usuario solo puede confirmar una vez cada alerta
    CONSTRAINT unique_user_alert_confirmation UNIQUE (alert_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_pest_alert_confirmations_alert_id
    ON public.pest_alert_confirmations(alert_id);
CREATE INDEX IF NOT EXISTS idx_pest_alert_confirmations_user_id
    ON public.pest_alert_confirmations(user_id);

-- ============================================================================
-- 3. FUNCIÓN RPC: get_nearby_pest_alerts
-- ============================================================================
-- Calcula distancia usando fórmula Haversine y devuelve alertas ordenadas

CREATE OR REPLACE FUNCTION public.get_nearby_pest_alerts(
    p_latitude DECIMAL,
    p_longitude DECIMAL,
    p_radius_km DECIMAL DEFAULT 10.0,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_days_limit INTEGER DEFAULT NULL,
    p_pest_types TEXT[] DEFAULT NULL,
    p_severities TEXT[] DEFAULT NULL,
    p_include_resolved BOOLEAN DEFAULT false
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    photo_url TEXT,
    pest_type TEXT,
    custom_pest_name TEXT,
    severity TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    location_name TEXT,
    notes TEXT,
    status TEXT,
    confirmed_by_count INTEGER,
    is_resolved BOOLEAN,
    resolved_at TIMESTAMPTZ,
    reported_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    distance_km DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    earth_radius_km CONSTANT DECIMAL := 6371.0;
    lat1_rad DECIMAL;
    lng1_rad DECIMAL;
    cutoff_date TIMESTAMPTZ;
BEGIN
    -- Convertir lat/lng a radianes
    lat1_rad := RADIANS(p_latitude);
    lng1_rad := RADIANS(p_longitude);

    -- Calcular fecha de corte si hay límite de días
    IF p_days_limit IS NOT NULL THEN
        cutoff_date := now() - (p_days_limit || ' days')::INTERVAL;
    END IF;

    RETURN QUERY
    SELECT
        pa.id,
        pa.user_id,
        pa.photo_url,
        pa.pest_type,
        pa.custom_pest_name,
        pa.severity,
        pa.latitude,
        pa.longitude,
        pa.location_name,
        pa.notes,
        pa.status,
        pa.confirmed_by_count,
        pa.is_resolved,
        pa.resolved_at,
        pa.reported_at,
        pa.updated_at,
        -- Fórmula Haversine para distancia
        ROUND((
            earth_radius_km * 2 * ASIN(
                SQRT(
                    POWER(SIN(RADIANS(pa.latitude - p_latitude) / 2), 2) +
                    COS(lat1_rad) * COS(RADIANS(pa.latitude)) *
                    POWER(SIN(RADIANS(pa.longitude - p_longitude) / 2), 2)
                )
            )
        )::DECIMAL, 3) AS distance_km
    FROM public.pest_alerts pa
    WHERE
        -- Filtro de fecha
        (p_days_limit IS NULL OR pa.reported_at >= cutoff_date)
        AND
        -- Filtro de tipo de plaga
        (p_pest_types IS NULL OR pa.pest_type = ANY(p_pest_types))
        AND
        -- Filtro de severidad
        (p_severities IS NULL OR pa.severity = ANY(p_severities))
        AND
        -- Filtro de resueltas
        (p_include_resolved = true OR pa.is_resolved = false)
        AND
        pa.status = 'active'
        AND
        -- Filtro de radio (optimización: bounding box aproximada antes de Haversine)
        pa.latitude BETWEEN (p_latitude - (p_radius_km / 111.0))
                        AND (p_latitude + (p_radius_km / 111.0))
        AND
        pa.longitude BETWEEN (p_longitude - (p_radius_km / (111.0 * COS(RADIANS(p_latitude)))))
                         AND (p_longitude + (p_radius_km / (111.0 * COS(RADIANS(p_latitude)))))
    HAVING
        -- Filtrar por distancia exacta después del cálculo
        (earth_radius_km * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(pa.latitude - p_latitude) / 2), 2) +
                COS(lat1_rad) * COS(RADIANS(pa.latitude)) *
                POWER(SIN(RADIANS(pa.longitude - p_longitude) / 2), 2)
            )
        )) <= p_radius_km
    ORDER BY distance_km ASC, pa.reported_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- Comentario para documentación
COMMENT ON FUNCTION public.get_nearby_pest_alerts IS
'Returns pest alerts within specified radius, ordered by distance. Uses Haversine formula for accurate distance calculation.';

-- ============================================================================
-- 4. FUNCIÓN RPC: get_pest_alerts_statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_pest_alerts_statistics(
    p_latitude DECIMAL,
    p_longitude DECIMAL,
    p_radius_km DECIMAL DEFAULT 10.0,
    p_days_limit INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_alerts', COUNT(*),
        'by_type', jsonb_object_agg(pest_type, cnt),
        'by_severity', jsonb_object_agg(severity, cnt),
        'high_severity_count', SUM(CASE WHEN severity IN ('high', 'critical') THEN 1 ELSE 0 END),
        'recent_alerts', SUM(CASE WHEN reported_at >= now() - interval '7 days' THEN 1 ELSE 0 END)
    )
    INTO result
    FROM (
        SELECT
            pest_type,
            severity,
            COUNT(*) as cnt
        FROM public.get_nearby_pest_alerts(
            p_latitude, p_longitude, p_radius_km,
            1000, 0, p_days_limit, NULL, NULL, false
        )
        GROUP BY pest_type, severity
    ) stats;

    RETURN result;
END;
$$;

-- ============================================================================
-- 5. FUNCIÓN: Incrementar contador de confirmaciones
-- ============================================================================

CREATE OR REPLACE FUNCTION public.increment_alert_confirmations()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.pest_alerts
    SET confirmed_by_count = confirmed_by_count + 1
    WHERE id = NEW.alert_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para incrementar automáticamente al confirmar
DROP TRIGGER IF EXISTS tr_increment_confirmations ON public.pest_alert_confirmations;
CREATE TRIGGER tr_increment_confirmations
    AFTER INSERT ON public.pest_alert_confirmations
    FOR EACH ROW
    EXECUTE FUNCTION public.increment_alert_confirmations();

-- ============================================================================
-- 6. FUNCIÓN: Actualizar updated_at automáticamente
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_pest_alerts_updated_at ON public.pest_alerts;
CREATE TRIGGER tr_pest_alerts_updated_at
    BEFORE UPDATE ON public.pest_alerts
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 7. POLÍTICAS RLS (Row Level Security)
-- ============================================================================

ALTER TABLE public.pest_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pest_alert_confirmations ENABLE ROW LEVEL SECURITY;

-- Políticas para pest_alerts
CREATE POLICY "Allow users to view nearby pest alerts"
ON public.pest_alerts FOR SELECT
TO authenticated
USING (
    status = 'active' OR user_id = auth.uid()
);

CREATE POLICY "Allow users to create pest alerts"
ON public.pest_alerts FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow users to update their own alerts"
ON public.pest_alerts FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Allow users to delete their own alerts"
ON public.pest_alerts FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Políticas para pest_alert_confirmations
CREATE POLICY "Allow users to view confirmations"
ON public.pest_alert_confirmations FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow users to confirm alerts (not their own)"
ON public.pest_alert_confirmations FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.pest_alerts pa
        WHERE pa.id = alert_id AND pa.user_id != auth.uid()
    )
);

CREATE POLICY "Allow users to delete their own confirmations"
ON public.pest_alert_confirmations FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ============================================================================
-- 8. EJEMPLOS DE USO
-- ============================================================================

-- Buscar alertas dentro de 5km de Madrid centro
-- SELECT * FROM public.get_nearby_pest_alerts(40.4168, -3.7038, 5.0);

-- Buscar solo cochinillas en 10km, últimos 7 días
-- SELECT * FROM public.get_nearby_pest_alerts(
--     40.4168, -3.7038, 10.0, 50, 0, 7,
--     ARRAY['mealybugs', 'scale'],
--     NULL, false
-- );

-- Estadísticas de área
-- SELECT * FROM public.get_pest_alerts_statistics(40.4168, -3.7038, 10.0, 30);

-- ============================================================================
-- 9. PERMISOS ADICIONALES
-- ============================================================================

-- Permitir que funciones RPC sean llamadas por usuarios autenticados
GRANT EXECUTE ON FUNCTION public.get_nearby_pest_alerts TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pest_alerts_statistics TO authenticated;

-- Permitir acceso a la tabla (las políticas RLS controlan el acceso específico)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pest_alerts TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.pest_alert_confirmations TO authenticated;

-- Secuencias
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

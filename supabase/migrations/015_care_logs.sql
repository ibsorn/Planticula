-- ============================================================================
-- MIGRACIÓN 015 — Historial de cuidados (care_logs)
-- ============================================================================
-- Registra cada evento de cuidado de una planta (riego, trasplante, abono,
-- nota…) para construir un timeline real, estadísticas y rachas.
--
-- Hasta ahora solo se guardaba `plants.last_watered` (un único valor), por lo
-- que no había historial. Esta tabla es append-only desde la app.
-- ============================================================================

CREATE TABLE IF NOT EXISTS care_logs (
    id              UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    plant_id        UUID        REFERENCES plants(id) ON DELETE CASCADE NOT NULL,
    user_id         UUID        REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    -- Organización propietaria (multi-tenant); se hereda de la planta.
    organization_id UUID        REFERENCES organizations(id) ON DELETE CASCADE,

    type            TEXT        NOT NULL
                                CHECK (type IN ('watering', 'transplant', 'fertilize', 'prune', 'note')),

    -- Cuándo ocurrió el evento (puede ser en el pasado: riegos retroactivos).
    event_date      TIMESTAMPTZ NOT NULL DEFAULT now(),

    note            TEXT        CHECK (note IS NULL OR char_length(note) <= 1000),

    -- Datos extra por tipo (ej. trasplante: {"pot_size":"large"}).
    metadata        JSONB       NOT NULL DEFAULT '{}'::jsonb,

    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_care_logs_plant_date ON care_logs(plant_id, event_date DESC);
CREATE INDEX IF NOT EXISTS idx_care_logs_user_id    ON care_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_care_logs_type       ON care_logs(plant_id, type, event_date DESC);

ALTER TABLE care_logs ENABLE ROW LEVEL SECURITY;

-- Acceso por propietario o por pertenencia a la organización de la planta.
DROP POLICY IF EXISTS "Users can view own care logs" ON care_logs;
CREATE POLICY "Users can view own care logs" ON care_logs
    FOR SELECT USING (
        auth.uid() = user_id
        OR (organization_id IS NOT NULL AND public.is_org_member(organization_id))
    );

DROP POLICY IF EXISTS "Users can insert own care logs" ON care_logs;
CREATE POLICY "Users can insert own care logs" ON care_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own care logs" ON care_logs;
CREATE POLICY "Users can update own care logs" ON care_logs
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own care logs" ON care_logs;
CREATE POLICY "Users can delete own care logs" ON care_logs
    FOR DELETE USING (
        auth.uid() = user_id
        OR (organization_id IS NOT NULL AND public.has_org_role(organization_id, ARRAY['owner', 'admin']))
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON care_logs TO authenticated;
GRANT ALL ON care_logs TO service_role;

COMMENT ON TABLE  care_logs            IS 'Append-only care event history per plant (watering, transplant, fertilize, prune, note).';
COMMENT ON COLUMN care_logs.event_date IS 'When the event happened (may be backdated for past waterings).';
COMMENT ON COLUMN care_logs.metadata   IS 'Type-specific extra data, e.g. {"pot_size":"large"} for transplant.';

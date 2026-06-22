-- ============================================================================
-- MIGRACIÓN 012 — Jerarquía de Jardines y Grupos
-- ============================================================================
-- Añade dos nuevas tablas (gardens, garden_groups) y dos columnas
-- opcionales en plants (garden_id, group_id).
-- Es completamente NO DESTRUCTIVA: no borra datos existentes.
--
-- Estructura resultante:
--   Usuario
--     └── Jardín (gardens)           ← "Mi balcón", "Invernadero A"
--              └── Grupo (garden_groups) ← "Tomates", "Suculentas"
--                       └── Planta (plants)
--
-- Las columnas garden_id / group_id en plants son NULLABLE: todas
-- las plantas existentes permanecen sin asignar hasta que el usuario
-- las organice desde la app.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. TABLA gardens
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gardens (
    id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id     UUID        REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,

    -- Información básica
    name        TEXT        NOT NULL
                            CHECK (char_length(name) > 0 AND char_length(name) <= 100),
    description TEXT
                            CHECK (description IS NULL OR char_length(description) <= 500),

    -- Visual: icono y color (para diferenciar jardines en la UI)
    icon        TEXT        NOT NULL DEFAULT 'garden'
                            CHECK (icon IN (
                                'garden', 'balcony', 'terrace', 'greenhouse',
                                'indoor', 'potted', 'vegetable', 'flower',
                                'herb', 'forest', 'other'
                            )),
    color       TEXT        NOT NULL DEFAULT '#4CAF50'
                            CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),

    -- Tipo de jardín (para personalización de UI y futura lógica IoT)
    type        TEXT        NOT NULL DEFAULT 'personal'
                            CHECK (type IN (
                                'personal', 'balcony', 'terrace', 'greenhouse',
                                'indoor', 'outdoor', 'allotment', 'other'
                            )),

    -- El jardín por defecto se crea automáticamente para cada usuario
    is_default  BOOLEAN     NOT NULL DEFAULT false,

    -- Orden visual entre jardines del mismo usuario
    sort_order  INTEGER     NOT NULL DEFAULT 0,

    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_gardens_user_id    ON gardens(user_id);
CREATE INDEX IF NOT EXISTS idx_gardens_user_order ON gardens(user_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_gardens_is_default ON gardens(user_id, is_default) WHERE is_default = true;

-- Trigger updated_at
DROP TRIGGER IF EXISTS update_gardens_updated_at ON gardens;
CREATE TRIGGER update_gardens_updated_at
    BEFORE UPDATE ON gardens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE gardens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own gardens"   ON gardens;
CREATE POLICY "Users can view own gardens" ON gardens
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own gardens" ON gardens;
CREATE POLICY "Users can insert own gardens" ON gardens
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own gardens" ON gardens;
CREATE POLICY "Users can update own gardens" ON gardens
    FOR UPDATE
    USING     (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own gardens" ON gardens;
CREATE POLICY "Users can delete own gardens" ON gardens
    FOR DELETE USING (auth.uid() = user_id);

-- Permisos
GRANT SELECT, INSERT, UPDATE, DELETE ON gardens TO authenticated;
GRANT ALL ON gardens TO service_role;

-- Comentarios
COMMENT ON TABLE  gardens             IS 'Top-level container for a user''s plants. One user can have many gardens (balcony, greenhouse, indoor…).';
COMMENT ON COLUMN gardens.icon        IS 'Visual icon key: garden|balcony|terrace|greenhouse|indoor|potted|vegetable|flower|herb|forest|other';
COMMENT ON COLUMN gardens.color       IS 'Hex color (#RRGGBB) used to visually distinguish gardens in the UI';
COMMENT ON COLUMN gardens.type        IS 'Garden type for UI personalisation and future IoT rules';
COMMENT ON COLUMN gardens.is_default  IS 'Exactly one garden per user should be flagged as default (auto-created on first use)';
COMMENT ON COLUMN gardens.sort_order  IS 'Display order within the user''s garden list';


-- ────────────────────────────────────────────────────────────────────────────
-- 2. TABLA garden_groups
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS garden_groups (
    id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    garden_id   UUID        REFERENCES gardens(id)      ON DELETE CASCADE  NOT NULL,
    user_id     UUID        REFERENCES auth.users(id)   ON DELETE CASCADE  NOT NULL,

    -- Información básica
    name        TEXT        NOT NULL
                            CHECK (char_length(name) > 0 AND char_length(name) <= 100),
    description TEXT
                            CHECK (description IS NULL OR char_length(description) <= 500),

    -- Visual opcional (hereda del jardín padre si es NULL)
    icon        TEXT,
    color       TEXT        CHECK (color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$'),

    -- Orden visual dentro del jardín
    sort_order  INTEGER     NOT NULL DEFAULT 0,

    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_garden_groups_garden_id   ON garden_groups(garden_id);
CREATE INDEX IF NOT EXISTS idx_garden_groups_user_id     ON garden_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_garden_groups_garden_order ON garden_groups(garden_id, sort_order);

-- Trigger updated_at
DROP TRIGGER IF EXISTS update_garden_groups_updated_at ON garden_groups;
CREATE TRIGGER update_garden_groups_updated_at
    BEFORE UPDATE ON garden_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE garden_groups ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own garden groups"   ON garden_groups;
CREATE POLICY "Users can view own garden groups" ON garden_groups
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own garden groups" ON garden_groups;
CREATE POLICY "Users can insert own garden groups" ON garden_groups
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own garden groups" ON garden_groups;
CREATE POLICY "Users can update own garden groups" ON garden_groups
    FOR UPDATE
    USING     (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own garden groups" ON garden_groups;
CREATE POLICY "Users can delete own garden groups" ON garden_groups
    FOR DELETE USING (auth.uid() = user_id);

-- Permisos
GRANT SELECT, INSERT, UPDATE, DELETE ON garden_groups TO authenticated;
GRANT ALL ON garden_groups TO service_role;

-- Comentarios
COMMENT ON TABLE  garden_groups            IS 'Optional sub-groups within a garden (e.g. "Tomatoes", "Succulents", "Shade zone").';
COMMENT ON COLUMN garden_groups.garden_id  IS 'Parent garden. Deleting a garden cascades to its groups.';
COMMENT ON COLUMN garden_groups.icon       IS 'Optional icon override; falls back to parent garden icon in the UI.';
COMMENT ON COLUMN garden_groups.color      IS 'Optional hex color override; falls back to parent garden color.';
COMMENT ON COLUMN garden_groups.sort_order IS 'Display order within the garden';


-- ────────────────────────────────────────────────────────────────────────────
-- 3. ACTUALIZAR tabla plants — añadir garden_id y group_id
-- ────────────────────────────────────────────────────────────────────────────
-- Ambas columnas son NULLABLE para no romper plantas existentes.
-- ON DELETE SET NULL: si se borra un jardín/grupo, las plantas
-- quedan "huérfanas" (sin jardín) en vez de borrarse.
ALTER TABLE plants
    ADD COLUMN IF NOT EXISTS garden_id UUID REFERENCES gardens(id)       ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS group_id  UUID REFERENCES garden_groups(id) ON DELETE SET NULL;

-- Índices para filtrado eficiente por jardín y grupo
CREATE INDEX IF NOT EXISTS idx_plants_garden_id ON plants(garden_id) WHERE garden_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plants_group_id  ON plants(group_id)  WHERE group_id  IS NOT NULL;

-- Comentarios
COMMENT ON COLUMN plants.garden_id IS 'Optional: jardín al que pertenece esta planta. NULL = sin clasificar.';
COMMENT ON COLUMN plants.group_id  IS 'Optional: grupo dentro del jardín. NULL = sin grupo (directamente en el jardín).';


-- ────────────────────────────────────────────────────────────────────────────
-- 4. FUNCIÓN RPC: get_or_create_default_garden
-- ────────────────────────────────────────────────────────────────────────────
-- Devuelve el jardín por defecto del usuario autenticado.
-- Si no existe, lo crea automáticamente ("Mi Jardín").
-- El cliente Flutter la llama una vez en el arranque para garantizar
-- que siempre hay al menos un jardín disponible.
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_or_create_default_garden()
RETURNS TABLE (
    id          UUID,
    user_id     UUID,
    name        TEXT,
    description TEXT,
    icon        TEXT,
    color       TEXT,
    type        TEXT,
    is_default  BOOLEAN,
    sort_order  INTEGER,
    created_at  TIMESTAMPTZ,
    updated_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_garden  gardens%ROWTYPE;
BEGIN
    -- Try to find an existing default garden
    SELECT * INTO v_garden
    FROM gardens g
    WHERE g.user_id = v_user_id AND g.is_default = true
    LIMIT 1;

    -- If not found, create one
    IF NOT FOUND THEN
        INSERT INTO gardens (user_id, name, description, icon, color, type, is_default, sort_order)
        VALUES (
            v_user_id,
            'Mi Jardín',
            'Mi colección de plantas',
            'garden',
            '#4CAF50',
            'personal',
            true,
            0
        )
        RETURNING * INTO v_garden;
    END IF;

    -- Return as table row
    RETURN QUERY SELECT
        v_garden.id, v_garden.user_id, v_garden.name, v_garden.description,
        v_garden.icon, v_garden.color, v_garden.type, v_garden.is_default,
        v_garden.sort_order, v_garden.created_at, v_garden.updated_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_default_garden() TO authenticated;
COMMENT ON FUNCTION public.get_or_create_default_garden() IS
    'Returns the calling user''s default garden, auto-creating "Mi Jardín" on first call.';


-- ────────────────────────────────────────────────────────────────────────────
-- 5. FUNCIÓN RPC: assign_unclassified_plants_to_default_garden
-- ────────────────────────────────────────────────────────────────────────────
-- Mueve todas las plantas sin jardín del usuario al jardín por defecto.
-- Opcional: el cliente puede llamarla al migrar usuarios existentes.
-- ────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.assign_unclassified_plants_to_default_garden()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id   UUID := auth.uid();
    v_garden_id UUID;
    v_count     INTEGER;
BEGIN
    -- Ensure default garden exists
    SELECT id INTO v_garden_id
    FROM gardens
    WHERE user_id = v_user_id AND is_default = true
    LIMIT 1;

    IF v_garden_id IS NULL THEN
        RETURN 0;
    END IF;

    -- Assign orphaned plants
    UPDATE plants
    SET garden_id = v_garden_id
    WHERE user_id = v_user_id AND garden_id IS NULL;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.assign_unclassified_plants_to_default_garden() TO authenticated;
COMMENT ON FUNCTION public.assign_unclassified_plants_to_default_garden() IS
    'Assigns all unclassified plants (garden_id IS NULL) of the current user to their default garden. Returns number of plants updated.';

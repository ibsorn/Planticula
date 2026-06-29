-- ============================================================================
-- MIGRACIÓN 013 — Multi-tenant (organizations) + jerarquía de localización
--                 recursiva (locations) y migración de gardens → locations
-- ============================================================================
-- Esta migración convierte el modelo B2C (gardens > garden_groups) en el
-- modelo B2B objetivo:
--
--   Organization (cliente B2B)
--     └── Member (owner|admin|operator|viewer)
--     └── Location (tabla recursiva, parent_id)   kind ∈ {site, zone, bench}
--            site  → vivero físico
--            zone  → invernadero / nave / sector
--            bench → mesa / hilera
--                 └── Plant (location_id)
--
-- NO es destructiva con los datos: migra gardens/garden_groups a locations y
-- repunta las plantas. Las tablas gardens/garden_groups y las columnas
-- plants.garden_id / plants.group_id se eliminan en la migración 014, una vez
-- validada la migración de datos.
-- ============================================================================


-- ────────────────────────────────────────────────────────────────────────────
-- 1. TABLA organizations
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS organizations (
    id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    name        TEXT        NOT NULL
                            CHECK (char_length(name) > 0 AND char_length(name) <= 120),
    -- La organización "personal" se crea automáticamente para cada usuario
    -- (equivalente al antiguo jardín por defecto). Un usuario solo tiene una.
    is_personal BOOLEAN     NOT NULL DEFAULT false,
    created_by  UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_organizations_created_by ON organizations(created_by);

DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
    BEFORE UPDATE ON organizations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ────────────────────────────────────────────────────────────────────────────
-- 2. TABLA organization_members
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS organization_members (
    id              UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id UUID        REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,
    user_id         UUID        REFERENCES auth.users(id)    ON DELETE CASCADE NOT NULL,
    role            TEXT        NOT NULL DEFAULT 'owner'
                                CHECK (role IN ('owner', 'admin', 'operator', 'viewer')),
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE (organization_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_org_members_org_id  ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON organization_members(user_id);

DROP TRIGGER IF EXISTS update_org_members_updated_at ON organization_members;
CREATE TRIGGER update_org_members_updated_at
    BEFORE UPDATE ON organization_members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ────────────────────────────────────────────────────────────────────────────
-- 3. FUNCIONES HELPER de pertenencia (SECURITY DEFINER → evitan recursión RLS)
-- ────────────────────────────────────────────────────────────────────────────
-- Estas funciones consultan organization_members SALTÁNDOSE su RLS (SECURITY
-- DEFINER). Es la forma estándar de evitar la recursión infinita de políticas
-- que se referencian entre sí (organizations ↔ organization_members).

CREATE OR REPLACE FUNCTION public.is_org_member(p_org UUID)
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = p_org AND user_id = auth.uid()
    );
$$;

CREATE OR REPLACE FUNCTION public.has_org_role(p_org UUID, p_roles TEXT[])
RETURNS BOOLEAN
LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM organization_members
        WHERE organization_id = p_org
          AND user_id = auth.uid()
          AND role = ANY (p_roles)
    );
$$;

GRANT EXECUTE ON FUNCTION public.is_org_member(UUID)          TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_org_role(UUID, TEXT[])   TO authenticated;


-- ────────────────────────────────────────────────────────────────────────────
-- 4. RLS de organizations y organization_members
-- ────────────────────────────────────────────────────────────────────────────
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view their organizations" ON organizations;
CREATE POLICY "Members can view their organizations" ON organizations
    FOR SELECT USING (public.is_org_member(id));

DROP POLICY IF EXISTS "Users can create organizations" ON organizations;
CREATE POLICY "Users can create organizations" ON organizations
    FOR INSERT WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "Admins can update their organizations" ON organizations;
CREATE POLICY "Admins can update their organizations" ON organizations
    FOR UPDATE
    USING     (public.has_org_role(id, ARRAY['owner', 'admin']))
    WITH CHECK (public.has_org_role(id, ARRAY['owner', 'admin']));

DROP POLICY IF EXISTS "Owners can delete their organizations" ON organizations;
CREATE POLICY "Owners can delete their organizations" ON organizations
    FOR DELETE USING (public.has_org_role(id, ARRAY['owner']));

GRANT SELECT, INSERT, UPDATE, DELETE ON organizations TO authenticated;
GRANT ALL ON organizations TO service_role;


ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view co-members" ON organization_members;
CREATE POLICY "Members can view co-members" ON organization_members
    FOR SELECT USING (public.is_org_member(organization_id));

-- INSERT: o bien te añades a ti mismo (bootstrap al crear la org), o eres
-- owner/admin invitando a otro usuario.
DROP POLICY IF EXISTS "Admins can add members" ON organization_members;
CREATE POLICY "Admins can add members" ON organization_members
    FOR INSERT WITH CHECK (
        user_id = auth.uid()
        OR public.has_org_role(organization_id, ARRAY['owner', 'admin'])
    );

DROP POLICY IF EXISTS "Admins can update members" ON organization_members;
CREATE POLICY "Admins can update members" ON organization_members
    FOR UPDATE
    USING     (public.has_org_role(organization_id, ARRAY['owner', 'admin']))
    WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin']));

-- DELETE: un admin/owner puede expulsar, o cualquiera puede abandonar la org.
DROP POLICY IF EXISTS "Admins can remove members" ON organization_members;
CREATE POLICY "Admins can remove members" ON organization_members
    FOR DELETE USING (
        user_id = auth.uid()
        OR public.has_org_role(organization_id, ARRAY['owner', 'admin'])
    );

GRANT SELECT, INSERT, UPDATE, DELETE ON organization_members TO authenticated;
GRANT ALL ON organization_members TO service_role;


-- ────────────────────────────────────────────────────────────────────────────
-- 5. TABLA locations (recursiva — adjacency list)
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS locations (
    id              UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id UUID        REFERENCES organizations(id) ON DELETE CASCADE NOT NULL,

    -- Auto-referencia: NULL = nodo raíz (un 'site'); resto cuelgan de un padre.
    parent_id       UUID        REFERENCES locations(id) ON DELETE CASCADE,

    kind            TEXT        NOT NULL
                                CHECK (kind IN ('site', 'zone', 'bench')),

    name            TEXT        NOT NULL
                                CHECK (char_length(name) > 0 AND char_length(name) <= 120),
    description     TEXT        CHECK (description IS NULL OR char_length(description) <= 500),

    -- Visual (icon es texto libre para soportar futuros iconos sin migración).
    icon            TEXT        NOT NULL DEFAULT 'garden',
    color           TEXT        NOT NULL DEFAULT '#4CAF50'
                                CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),

    -- Datos extra por nivel: lat/lon, área m², timezone, tipo de invernadero…
    metadata        JSONB       NOT NULL DEFAULT '{}'::jsonb,

    is_default      BOOLEAN     NOT NULL DEFAULT false,
    sort_order      INTEGER     NOT NULL DEFAULT 0,

    -- Columnas de trazabilidad de la migración (se eliminan en 014).
    legacy_garden_id UUID,
    legacy_group_id  UUID,

    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now(),

    -- Invariante: un 'site' es raíz (sin padre); zone/bench cuelgan de un padre.
    CONSTRAINT locations_root_is_site CHECK (
        (kind = 'site'  AND parent_id IS NULL) OR
        (kind <> 'site' AND parent_id IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_locations_org_id    ON locations(organization_id);
CREATE INDEX IF NOT EXISTS idx_locations_parent_id ON locations(parent_id);
CREATE INDEX IF NOT EXISTS idx_locations_org_order ON locations(organization_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_locations_legacy_garden ON locations(legacy_garden_id) WHERE legacy_garden_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_locations_legacy_group  ON locations(legacy_group_id)  WHERE legacy_group_id  IS NOT NULL;

DROP TRIGGER IF EXISTS update_locations_updated_at ON locations;
CREATE TRIGGER update_locations_updated_at
    BEFORE UPDATE ON locations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view org locations" ON locations;
CREATE POLICY "Members can view org locations" ON locations
    FOR SELECT USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Operators can insert org locations" ON locations;
CREATE POLICY "Operators can insert org locations" ON locations
    FOR INSERT WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'operator']));

DROP POLICY IF EXISTS "Operators can update org locations" ON locations;
CREATE POLICY "Operators can update org locations" ON locations
    FOR UPDATE
    USING     (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'operator']))
    WITH CHECK (public.has_org_role(organization_id, ARRAY['owner', 'admin', 'operator']));

DROP POLICY IF EXISTS "Admins can delete org locations" ON locations;
CREATE POLICY "Admins can delete org locations" ON locations
    FOR DELETE USING (public.has_org_role(organization_id, ARRAY['owner', 'admin']));

GRANT SELECT, INSERT, UPDATE, DELETE ON locations TO authenticated;
GRANT ALL ON locations TO service_role;

COMMENT ON TABLE  locations            IS 'Recursive location tree (site>zone>bench). Replaces gardens/garden_groups.';
COMMENT ON COLUMN locations.parent_id  IS 'Parent location. NULL only for kind=site (root).';
COMMENT ON COLUMN locations.kind       IS 'site (vivero) | zone (invernadero/sector) | bench (mesa/hilera)';
COMMENT ON COLUMN locations.metadata   IS 'Free-form per-level data: lat/lon, area_m2, timezone, greenhouse type…';


-- ────────────────────────────────────────────────────────────────────────────
-- 6. EXTENDER plants — organization_id + location_id
-- ────────────────────────────────────────────────────────────────────────────
ALTER TABLE plants
    ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS location_id     UUID REFERENCES locations(id)     ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_plants_organization_id ON plants(organization_id) WHERE organization_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_plants_location_id     ON plants(location_id)     WHERE location_id     IS NOT NULL;

COMMENT ON COLUMN plants.organization_id IS 'Organization that owns this plant (multi-tenant).';
COMMENT ON COLUMN plants.location_id     IS 'Deepest location node assigned to this plant. NULL = unclassified.';


-- ────────────────────────────────────────────────────────────────────────────
-- 7. RPC: get_or_create_default_organization
-- ────────────────────────────────────────────────────────────────────────────
-- Devuelve la organización personal del usuario, creándola (con membresía
-- owner) en la primera llamada. La app la invoca al arrancar, igual que antes
-- hacía con get_or_create_default_garden.
DROP FUNCTION IF EXISTS public.get_or_create_default_organization() CASCADE;
CREATE OR REPLACE FUNCTION public.get_or_create_default_organization()
RETURNS TABLE (
    id          UUID,
    name        TEXT,
    is_personal BOOLEAN,
    created_by  UUID,
    created_at  TIMESTAMPTZ,
    updated_at  TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_org organizations%ROWTYPE;
BEGIN
    SELECT o.* INTO v_org
    FROM organizations o
    JOIN organization_members m ON m.organization_id = o.id
    WHERE m.user_id = v_uid AND o.is_personal = true
    LIMIT 1;

    IF NOT FOUND THEN
        INSERT INTO organizations (name, is_personal, created_by)
        VALUES ('Mi organización', true, v_uid)
        RETURNING * INTO v_org;

        INSERT INTO organization_members (organization_id, user_id, role)
        VALUES (v_org.id, v_uid, 'owner');
    END IF;

    RETURN QUERY SELECT
        v_org.id, v_org.name, v_org.is_personal,
        v_org.created_by, v_org.created_at, v_org.updated_at;
END; $$;

GRANT EXECUTE ON FUNCTION public.get_or_create_default_organization() TO authenticated;
COMMENT ON FUNCTION public.get_or_create_default_organization() IS
    'Returns the calling user''s personal organization, auto-creating it (and an owner membership) on first call.';


-- ────────────────────────────────────────────────────────────────────────────
-- 8. MIGRACIÓN DE DATOS: gardens/garden_groups → locations
-- ────────────────────────────────────────────────────────────────────────────
-- Se ejecuta una sola vez al aplicar esta migración (con privilegios de owner,
-- por lo que ignora RLS). Idempotente: re-ejecutarla no duplica datos.
DO $$
DECLARE
    u   RECORD;
    g   RECORD;
    grp RECORD;
    v_org  UUID;
    v_site UUID;
BEGIN
    -- Solo si las tablas legacy existen (defensivo).
    IF to_regclass('public.gardens') IS NOT NULL THEN
        FOR u IN SELECT DISTINCT user_id FROM gardens LOOP
            -- Organización personal (reutiliza la existente si la hay).
            SELECT o.id INTO v_org
            FROM organizations o
            JOIN organization_members m ON m.organization_id = o.id
            WHERE m.user_id = u.user_id AND o.is_personal = true
            LIMIT 1;

            IF v_org IS NULL THEN
                INSERT INTO organizations (name, is_personal, created_by)
                VALUES ('Mi organización', true, u.user_id)
                RETURNING id INTO v_org;
                INSERT INTO organization_members (organization_id, user_id, role)
                VALUES (v_org, u.user_id, 'owner');
            END IF;

            -- gardens → locations(site)
            FOR g IN SELECT * FROM gardens WHERE user_id = u.user_id LOOP
                SELECT id INTO v_site FROM locations WHERE legacy_garden_id = g.id LIMIT 1;
                IF v_site IS NULL THEN
                    INSERT INTO locations (organization_id, parent_id, kind, name, description,
                                           icon, color, is_default, sort_order, legacy_garden_id)
                    VALUES (v_org, NULL, 'site', g.name, g.description,
                            g.icon, g.color, g.is_default, g.sort_order, g.id)
                    RETURNING id INTO v_site;
                END IF;

                -- garden_groups → locations(zone)
                FOR grp IN SELECT * FROM garden_groups WHERE garden_id = g.id LOOP
                    IF NOT EXISTS (SELECT 1 FROM locations WHERE legacy_group_id = grp.id) THEN
                        INSERT INTO locations (organization_id, parent_id, kind, name, description,
                                               icon, color, sort_order, legacy_group_id)
                        VALUES (v_org, v_site, 'zone', grp.name, grp.description,
                                COALESCE(grp.icon, g.icon), COALESCE(grp.color, g.color),
                                grp.sort_order, grp.id);
                    END IF;
                END LOOP;
            END LOOP;

            -- Repuntar plantas de este usuario.
            UPDATE plants p SET
                organization_id = v_org,
                location_id = COALESCE(
                    (SELECT l.id FROM locations l WHERE l.legacy_group_id  = p.group_id),
                    (SELECT l.id FROM locations l WHERE l.legacy_garden_id = p.garden_id)
                )
            WHERE p.user_id = u.user_id;
        END LOOP;
    END IF;

    -- Usuarios con plantas pero sin jardines (o sin org aún): darles org personal.
    FOR u IN SELECT DISTINCT user_id FROM plants WHERE organization_id IS NULL LOOP
        SELECT o.id INTO v_org
        FROM organizations o
        JOIN organization_members m ON m.organization_id = o.id
        WHERE m.user_id = u.user_id AND o.is_personal = true
        LIMIT 1;

        IF v_org IS NULL THEN
            INSERT INTO organizations (name, is_personal, created_by)
            VALUES ('Mi organización', true, u.user_id)
            RETURNING id INTO v_org;
            INSERT INTO organization_members (organization_id, user_id, role)
            VALUES (v_org, u.user_id, 'owner');
        END IF;

        UPDATE plants SET organization_id = v_org
        WHERE user_id = u.user_id AND organization_id IS NULL;
    END LOOP;
END $$;


-- ────────────────────────────────────────────────────────────────────────────
-- 9. ACTUALIZAR RLS de plants — añadir acceso por organización
-- ────────────────────────────────────────────────────────────────────────────
-- Se mantiene el acceso por propietario (auth.uid() = user_id) para no romper
-- nada, y se AÑADE acceso a los miembros de la organización de la planta.
DROP POLICY IF EXISTS "Users can view own plants" ON plants;
CREATE POLICY "Users can view own plants" ON plants
    FOR SELECT USING (
        auth.uid() = user_id
        OR (organization_id IS NOT NULL AND public.is_org_member(organization_id))
    );

DROP POLICY IF EXISTS "Users can update own plants" ON plants;
CREATE POLICY "Users can update own plants" ON plants
    FOR UPDATE
    USING (
        auth.uid() = user_id
        OR (organization_id IS NOT NULL AND public.has_org_role(organization_id, ARRAY['owner', 'admin', 'operator']))
    )
    WITH CHECK (
        auth.uid() = user_id
        OR (organization_id IS NOT NULL AND public.has_org_role(organization_id, ARRAY['owner', 'admin', 'operator']))
    );

DROP POLICY IF EXISTS "Users can delete own plants" ON plants;
CREATE POLICY "Users can delete own plants" ON plants
    FOR DELETE USING (
        auth.uid() = user_id
        OR (organization_id IS NOT NULL AND public.has_org_role(organization_id, ARRAY['owner', 'admin']))
    );

-- INSERT se mantiene: el creador siempre es el propietario.
DROP POLICY IF EXISTS "Users can insert own plants" ON plants;
CREATE POLICY "Users can insert own plants" ON plants
    FOR INSERT WITH CHECK (auth.uid() = user_id);

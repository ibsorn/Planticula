-- ============================================================================
-- STORAGE: Bucket y políticas para fotos de pest_alerts
-- ============================================================================

-- ============================================================================
-- 1. CREAR BUCKET (ejecutar en SQL Editor de Supabase Dashboard)
-- ============================================================================

-- NOTA: El bucket debe crearse manualmente en el Dashboard o via Storage API
-- No se puede crear bucket directamente desde SQL

-- En el Dashboard:
-- 1. Storage → New bucket
-- 2. Name: "pest-photos"
-- 3. Public bucket: true (para que las URLs sean accesibles)
-- 4. Create

-- ============================================================================
-- 2. POLÍTICAS DE STORAGE (ejecutar en SQL Editor)
-- ============================================================================

-- Bucket: pest-photos
-- Descripción: Almacena fotos de plagas reportadas por usuarios

-- Política: Usuarios autenticados pueden subir fotos a su propia carpeta
CREATE POLICY "Allow authenticated uploads to pest-photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'pest-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Política: Cualquiera puede ver fotos públicas
CREATE POLICY "Allow public read access to pest-photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'pest-photos');

-- Política: Usuarios pueden borrar sus propias fotos
CREATE POLICY "Allow users to delete their own pest photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'pest-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- Política: Usuarios pueden actualizar sus propias fotos
CREATE POLICY "Allow users to update their own pest photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'pest-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'pest-photos' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================================================
-- 3. CONFIGURACIÓN RECOMENDADA EN DASHBOARD
-- ============================================================================

/*
Bucket Settings (pest-photos):
├── Public bucket: true
├── Allowed MIME types: image/jpeg, image/png, image/webp
├── File size limit: 5242880 (5MB)
└── CORS: configurado automáticamente por Supabase

Storage → pest-photos → Policies:
- Upload (authenticated, own folder): ^(user-id)/.*
- Read (public): ^.*
- Delete (authenticated, own folder): ^(user-id)/.*
- Update (authenticated, own folder): ^(user-id)/.*
*/

-- ============================================================================
-- 4. ESTRUCTURA DE CARPETAS
-- ============================================================================

-- Las fotos se almacenan en:
-- pest-photos/{user_id}/{timestamp}_pest.{ext}
--
-- Ejemplo:
-- pest-photos/550e8400-e29b-41d4-a716-446655440000/1705312800000_pest.jpg

-- ============================================================================
-- 5. LIMPIEZA AUTOMÁTICA (opcional - ejecutar periódicamente)
-- ============================================================================

-- Función para limpiar fotos huérfanas (alertas eliminadas)
-- Ejecutar como cron job o manualmente

CREATE OR REPLACE FUNCTION public.cleanup_orphan_pest_photos()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INTEGER := 0;
    photo RECORD;
BEGIN
    -- Buscar fotos cuya alerta ya no existe
    FOR photo IN
        SELECT s.name
        FROM storage.objects s
        LEFT JOIN public.pest_alerts p ON s.name = split_part(p.photo_url, '/', -1)
        WHERE s.bucket_id = 'pest-photos'
          AND p.id IS NULL
    LOOP
        -- Eliminar de storage
        DELETE FROM storage.objects
        WHERE bucket_id = 'pest-photos' AND name = photo.name;

        deleted_count := deleted_count + 1;
    END LOOP;

    RETURN deleted_count;
END;
$$;

-- ============================================================================
-- 6. COMANDOS SQL EJECUTABLES (Supabase Dashboard → SQL Editor)
-- ============================================================================

-- Ejecutar en orden:

-- Paso 1: Crear bucket manualmente en Dashboard
-- Storage → New bucket → Name: "pest-photos" → Public bucket: true

-- Paso 2: Ejecutar políticas (copiar y pegar desde arriba)

-- Paso 3: Verificar configuración
SELECT * FROM storage.buckets WHERE id = 'pest-photos';

-- Paso 4: Listar políticas del bucket
SELECT * FROM storage.policies WHERE bucket_id = 'pest-photos';

-- ============================================================================
-- 7. TROUBLESHOOTING
-- ============================================================================

-- Si hay problemas de permisos, verificar:
-- 1. Que el bucket existe y es público
SELECT id, public FROM storage.buckets WHERE id = 'pest-photos';

-- 2. Que las políticas están aplicadas
SELECT * FROM storage.policies WHERE bucket_id = 'pest-photos';

-- 3. Que RLS está habilitado en tablas
SELECT relname, relrowsecurity
FROM pg_class
WHERE relname IN ('pest_alerts', 'pest_alert_confirmations');

-- 4. Que el usuario tiene el rol correcto
SELECT auth.uid();
SELECT auth.role();

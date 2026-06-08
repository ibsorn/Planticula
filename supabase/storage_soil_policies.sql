-- ============================================================================
-- STORAGE BUCKET Y POLÍTICAS PARA SOIL-IMAGES
-- ============================================================================
-- Bucket para almacenar imágenes de análisis de sustrato
-- ============================================================================

-- ============================================================================
-- 1. CREAR EL BUCKET (hacerlo desde UI o API)
-- ============================================================================
-- En Supabase Dashboard → Storage → New bucket:
-- Name: soil-images
-- Public bucket: TRUE (las URLs deben ser accesibles para mostrar en app)
-- File size limit: 10485760 (10MB - fotos de alta calidad de sustrato)
-- Allowed MIME types: image/jpeg, image/png, image/heic, image/heif

-- ============================================================================
-- 2. POLÍTICAS DE ACCESO
-- ============================================================================

-- POLÍTICA: Permitir lectura pública de imágenes de sustrato
-- Las imágenes deben ser públicas para que la app pueda mostrarlas sin autenticación adicional
DROP POLICY IF EXISTS "Public read access to soil images" ON storage.objects;
CREATE POLICY "Public read access to soil images" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'soil-images');

-- POLÍTICA: Usuarios autenticados pueden subir imágenes de sustrato
-- Solo usuarios logueados, archivos válidos, máximo 10MB
DROP POLICY IF EXISTS "Authenticated users can upload soil images" ON storage.objects;
CREATE POLICY "Authenticated users can upload soil images" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'soil-images' AND
        auth.role() = 'authenticated' AND
        (
            storage.extension(name) = 'jpg' OR
            storage.extension(name) = 'jpeg' OR
            storage.extension(name) = 'png' OR
            storage.extension(name) = 'heic' OR
            storage.extension(name) = 'heif'
        ) AND
        storage.fossa(name) < 10485760  -- 10MB en bytes
    );

-- POLÍTICA: Usuarios pueden actualizar sus propias imágenes
-- Organización por user_id en la ruta: soil-images/{user_id}/{timestamp}_{filename}.jpg
DROP POLICY IF EXISTS "Users can update their own soil images" ON storage.objects;
CREATE POLICY "Users can update their own soil images" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'soil-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'soil-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- POLÍTICA: Usuarios pueden eliminar sus propias imágenes
DROP POLICY IF EXISTS "Users can delete their own soil images" ON storage.objects;
CREATE POLICY "Users can delete their own soil images" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'soil-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- 3. FUNCIÓN AUXILIAR PARA GENERAR RUTAS DE ALMACENAMIENTO
-- ============================================================================

-- Función para generar la ruta de almacenamiento para imágenes de sustrato
-- Formato: {user_id}/{plant_id?}/{timestamp}_{filename}
CREATE OR REPLACE FUNCTION storage_soil_image_path(
    p_user_id UUID,
    p_filename TEXT,
    p_plant_id UUID DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    v_timestamp BIGINT;
    v_extension TEXT;
    v_plant_folder TEXT;
BEGIN
    v_timestamp := EXTRACT(EPOCH FROM now()) * 1000; -- Timestamp en milisegundos
    v_extension := lower(storage.extension(p_filename));

    -- Normalizar extensión
    IF v_extension NOT IN ('jpg', 'jpeg', 'png', 'heic', 'heif') THEN
        v_extension := 'jpg';
    END IF;

    -- Carpeta opcional de planta
    IF p_plant_id IS NOT NULL THEN
        v_plant_folder := '/' || p_plant_id::text;
    ELSE
        v_plant_folder := '';
    END IF;

    RETURN p_user_id::text || v_plant_folder || '/' || v_timestamp || '_soil.' || v_extension;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. EJEMPLOS DE USO DESDE FLUTTER
-- ============================================================================

/*

// Subir imagen de sustrato
final fileName = 'soil_${DateTime.now().millisecondsSinceEpoch}.jpg';
final path = '$userId/$fileName';

await supabase.storage
    .from('soil-images')
    .uploadBinary(
        path,
        imageBytes,
        fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
        ),
    );

// Obtener URL pública
final imageUrl = supabase.storage
    .from('soil-images')
    .getPublicUrl(path);

// Guardar URL en la tabla
await supabase.from('soil_analyses').insert({
    'user_id': userId,
    'plant_id': plantId, // opcional
    'image_url': imageUrl,
    'status': 'pending',
});

// Eliminar imagen cuando se elimina el análisis
await supabase.storage
    .from('soil-images')
    .remove([path]);

*/

-- ============================================================================
-- 5. VERIFICACIÓN
-- ============================================================================

-- Verificar políticas creadas
SELECT policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects';

-- Verificar función creada
SELECT proname, proargnames
FROM pg_proc
WHERE proname = 'storage_soil_image_path';

-- ============================================================================
-- POLÍTICAS DE STORAGE PARA IMÁGENES DE PLANTAS
-- ============================================================================
-- Ejecutar después de crear el bucket "plant-images" en Storage
-- ============================================================================

-- ============================================================================
-- 1. CREAR EL BUCKET (hacerlo desde UI o API)
-- ============================================================================
-- En Supabase Dashboard → Storage → New bucket:
-- Name: plant-images
-- Public bucket: TRUE (para que las URLs sean accesibles sin token)
-- File size limit: 5242880 (5MB)
-- Allowed MIME types: image/png, image/jpeg, image/jpg

-- ============================================================================
-- 2. POLÍTICAS DE ACCESO
-- ============================================================================

-- POLÍTICA: Permitir lectura pública de imágenes
-- Cualquiera puede ver las imágenes (requerido para mostrar en app)
DROP POLICY IF EXISTS "Public read access to plant images" ON storage.objects;
CREATE POLICY "Public read access to plant images" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'plant-images');

-- POLÍTICA: Usuarios autenticados pueden subir imágenes
-- Solo usuarios logueados, archivos válidos, máximo 5MB
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
CREATE POLICY "Authenticated users can upload images" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'plant-images' AND
        auth.role() = 'authenticated' AND
        (
            storage.extension(name) = 'jpg' OR
            storage.extension(name) = 'jpeg' OR
            storage.extension(name) = 'png'
        ) AND
        storage.fossa(name) < 5242880  -- 5MB en bytes
    );

-- POLÍTICA: Usuarios pueden actualizar sus propias imágenes
-- Organización por user_id en la ruta: plant-images/{user_id}/{plant_id}.jpg
DROP POLICY IF EXISTS "Users can update their own images" ON storage.objects;
CREATE POLICY "Users can update their own images" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'plant-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'plant-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- POLÍTICA: Usuarios pueden eliminar sus propias imágenes
DROP POLICY IF EXISTS "Users can delete their own images" ON storage.objects;
CREATE POLICY "Users can delete their own images" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'plant-images' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- 3. FUNCIÓN AUXILIAR PARA SUBIR IMÁGENES
-- ============================================================================

-- Función para generar la ruta de almacenamiento
CREATE OR REPLACE FUNCTION storage_plant_image_path(
    p_user_id UUID,
    p_plant_id UUID,
    p_extension TEXT DEFAULT 'jpg'
) RETURNS TEXT AS $$
BEGIN
    RETURN p_user_id::text || '/' || p_plant_id::text || '.' || p_extension;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. EJEMPLO DE USO DESDE FLUTTER
-- ============================================================================

/*

// Subir imagen
final filePath = '$userId/$plantId.jpg';
await supabase.storage
    .from('plant-images')
    .uploadBinary(filePath, imageBytes);

// Obtener URL pública
final imageUrl = supabase.storage
    .from('plant-images')
    .getPublicUrl(filePath);

// Guardar URL en la tabla plants
await supabase.from('plants')
    .update({'image_url': imageUrl})
    .eq('id', plantId);

// Eliminar imagen
await supabase.storage
    .from('plant-images')
    .remove([filePath]);

*/

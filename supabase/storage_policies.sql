-- ===== PLANTICULA: STORAGE POLICIES =====
-- Ejecutar DESPUES de crear los buckets en Storage
-- Buckets requeridos: plant-images, soil-images, pest-photos, marketplace-photos

-- ============================================================================
-- BUCKET: plant-images
-- ============================================================================

DROP POLICY IF EXISTS "Public read plant images" ON storage.objects;
CREATE POLICY "Public read plant images" ON storage.objects
    FOR SELECT USING (bucket_id = 'plant-images');

DROP POLICY IF EXISTS "Auth users upload plant images" ON storage.objects;
CREATE POLICY "Auth users upload plant images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'plant-images'
        AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Users update own plant images" ON storage.objects;
CREATE POLICY "Users update own plant images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'plant-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Users delete own plant images" ON storage.objects;
CREATE POLICY "Users delete own plant images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'plant-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- BUCKET: soil-images
-- ============================================================================

DROP POLICY IF EXISTS "Public read soil images" ON storage.objects;
CREATE POLICY "Public read soil images" ON storage.objects
    FOR SELECT USING (bucket_id = 'soil-images');

DROP POLICY IF EXISTS "Auth users upload soil images" ON storage.objects;
CREATE POLICY "Auth users upload soil images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'soil-images'
        AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Users update own soil images" ON storage.objects;
CREATE POLICY "Users update own soil images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'soil-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Users delete own soil images" ON storage.objects;
CREATE POLICY "Users delete own soil images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'soil-images'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- BUCKET: pest-photos
-- ============================================================================

DROP POLICY IF EXISTS "Public read pest photos" ON storage.objects;
CREATE POLICY "Public read pest photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'pest-photos');

DROP POLICY IF EXISTS "Auth users upload pest photos" ON storage.objects;
CREATE POLICY "Auth users upload pest photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'pest-photos'
        AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Users update own pest photos" ON storage.objects;
CREATE POLICY "Users update own pest photos" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'pest-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Users delete own pest photos" ON storage.objects;
CREATE POLICY "Users delete own pest photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'pest-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ============================================================================
-- BUCKET: marketplace-photos
-- ============================================================================

DROP POLICY IF EXISTS "Public read marketplace photos" ON storage.objects;
CREATE POLICY "Public read marketplace photos" ON storage.objects
    FOR SELECT USING (bucket_id = 'marketplace-photos');

DROP POLICY IF EXISTS "Auth users upload marketplace photos" ON storage.objects;
CREATE POLICY "Auth users upload marketplace photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'marketplace-photos'
        AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Users update own marketplace photos" ON storage.objects;
CREATE POLICY "Users update own marketplace photos" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'marketplace-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Users delete own marketplace photos" ON storage.objects;
CREATE POLICY "Users delete own marketplace photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'marketplace-photos'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

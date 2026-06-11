-- Migration 005: Marketplace Tables and Functions
-- Creates tables, RLS policies, and RPC functions for the marketplace feature

-- ============================================================================
-- TABLE: marketplace_listings
-- ============================================================================

CREATE TABLE IF NOT EXISTS marketplace_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    seller_name TEXT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'plant' CHECK (category IN ('plant', 'cutting', 'tools', 'seeds', 'other')),
    photo_urls TEXT[] DEFAULT '{}',
    listing_type TEXT NOT NULL DEFAULT 'sale' CHECK (listing_type IN ('sale', 'trade', 'giveaway')),
    price DOUBLE PRECISION,
    trade_for TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location_name TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'reserved', 'sold', 'expired', 'removed')),
    view_count INTEGER DEFAULT 0,
    favorite_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days')
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_marketplace_seller ON marketplace_listings(seller_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_status ON marketplace_listings(status);
CREATE INDEX IF NOT EXISTS idx_marketplace_category ON marketplace_listings(category);
CREATE INDEX IF NOT EXISTS idx_marketplace_location ON marketplace_listings(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_marketplace_created ON marketplace_listings(created_at DESC);

-- ============================================================================
-- TABLE: marketplace_favorites
-- ============================================================================

CREATE TABLE IF NOT EXISTS marketplace_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    listing_id UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, listing_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON marketplace_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_listing ON marketplace_favorites(listing_id);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE marketplace_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_favorites ENABLE ROW LEVEL SECURITY;

-- Listings: anyone authenticated can read active listings
CREATE POLICY "Anyone can read active listings"
    ON marketplace_listings FOR SELECT
    USING (status = 'active' OR seller_id = auth.uid());

-- Listings: users can create their own
CREATE POLICY "Users can create own listings"
    ON marketplace_listings FOR INSERT
    WITH CHECK (seller_id = auth.uid());

-- Listings: users can update their own
CREATE POLICY "Users can update own listings"
    ON marketplace_listings FOR UPDATE
    USING (seller_id = auth.uid());

-- Listings: users can delete their own
CREATE POLICY "Users can delete own listings"
    ON marketplace_listings FOR DELETE
    USING (seller_id = auth.uid());

-- Favorites: users can read their own favorites
CREATE POLICY "Users can read own favorites"
    ON marketplace_favorites FOR SELECT
    USING (user_id = auth.uid());

-- Favorites: users can manage their own favorites
CREATE POLICY "Users can insert own favorites"
    ON marketplace_favorites FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own favorites"
    ON marketplace_favorites FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================================
-- FUNCTION: get_nearby_listings (geospatial search)
-- Uses Haversine formula for distance calculation
-- ============================================================================

CREATE OR REPLACE FUNCTION get_nearby_listings(
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 10.0,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_categories TEXT[] DEFAULT NULL,
    p_listing_types TEXT[] DEFAULT NULL,
    p_max_price DOUBLE PRECISION DEFAULT NULL,
    p_search TEXT DEFAULT NULL,
    p_include_sold BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    id UUID,
    seller_id UUID,
    seller_name TEXT,
    title TEXT,
    description TEXT,
    category TEXT,
    photo_urls TEXT[],
    listing_type TEXT,
    price DOUBLE PRECISION,
    trade_for TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location_name TEXT,
    status TEXT,
    view_count INTEGER,
    favorite_count INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    distance_km DOUBLE PRECISION
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ml.id,
        ml.seller_id,
        ml.seller_name,
        ml.title,
        ml.description,
        ml.category,
        ml.photo_urls,
        ml.listing_type,
        ml.price,
        ml.trade_for,
        ml.latitude,
        ml.longitude,
        ml.location_name,
        ml.status,
        ml.view_count,
        ml.favorite_count,
        ml.created_at,
        ml.updated_at,
        ml.expires_at,
        -- Haversine formula for distance in km
        (6371 * acos(
            cos(radians(p_latitude)) *
            cos(radians(ml.latitude)) *
            cos(radians(ml.longitude) - radians(p_longitude)) +
            sin(radians(p_latitude)) *
            sin(radians(ml.latitude))
        )) AS distance_km
    FROM marketplace_listings ml
    WHERE
        -- Status filter
        (CASE
            WHEN p_include_sold THEN ml.status IN ('active', 'reserved', 'sold')
            ELSE ml.status = 'active'
        END)
        -- Distance filter
        AND (6371 * acos(
            cos(radians(p_latitude)) *
            cos(radians(ml.latitude)) *
            cos(radians(ml.longitude) - radians(p_longitude)) +
            sin(radians(p_latitude)) *
            sin(radians(ml.latitude))
        )) <= p_radius_km
        -- Category filter
        AND (p_categories IS NULL OR ml.category = ANY(p_categories))
        -- Listing type filter
        AND (p_listing_types IS NULL OR ml.listing_type = ANY(p_listing_types))
        -- Price filter
        AND (p_max_price IS NULL OR ml.price IS NULL OR ml.price <= p_max_price)
        -- Search filter
        AND (p_search IS NULL OR p_search = '' OR
             ml.title ILIKE '%' || p_search || '%' OR
             ml.description ILIKE '%' || p_search || '%')
    ORDER BY distance_km ASC, ml.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- ============================================================================
-- FUNCTION: increment_listing_views
-- ============================================================================

CREATE OR REPLACE FUNCTION increment_listing_views(p_listing_id UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE marketplace_listings
    SET view_count = view_count + 1
    WHERE id = p_listing_id;
END;
$$;

-- ============================================================================
-- FUNCTION: toggle_listing_favorite
-- Returns true if favorited, false if unfavorited
-- ============================================================================

CREATE OR REPLACE FUNCTION toggle_listing_favorite(p_user_id UUID, p_listing_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    existing_id UUID;
    is_now_favorited BOOLEAN;
BEGIN
    -- Check if already favorited
    SELECT mf.id INTO existing_id
    FROM marketplace_favorites mf
    WHERE mf.user_id = p_user_id AND mf.listing_id = p_listing_id;

    IF existing_id IS NOT NULL THEN
        -- Remove favorite
        DELETE FROM marketplace_favorites WHERE id = existing_id;
        -- Decrement count
        UPDATE marketplace_listings SET favorite_count = GREATEST(favorite_count - 1, 0)
        WHERE id = p_listing_id;
        is_now_favorited := FALSE;
    ELSE
        -- Add favorite
        INSERT INTO marketplace_favorites (user_id, listing_id) VALUES (p_user_id, p_listing_id);
        -- Increment count
        UPDATE marketplace_listings SET favorite_count = favorite_count + 1
        WHERE id = p_listing_id;
        is_now_favorited := TRUE;
    END IF;

    RETURN is_now_favorited;
END;
$$;

-- ============================================================================
-- FUNCTION: get_marketplace_statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_marketplace_statistics(
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 10.0
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_active', COUNT(*) FILTER (WHERE status = 'active'),
        'total_sold', COUNT(*) FILTER (WHERE status = 'sold'),
        'by_category', json_build_object(
            'plant', COUNT(*) FILTER (WHERE category = 'plant' AND status = 'active'),
            'cutting', COUNT(*) FILTER (WHERE category = 'cutting' AND status = 'active'),
            'tools', COUNT(*) FILTER (WHERE category = 'tools' AND status = 'active'),
            'seeds', COUNT(*) FILTER (WHERE category = 'seeds' AND status = 'active'),
            'other', COUNT(*) FILTER (WHERE category = 'other' AND status = 'active')
        ),
        'by_type', json_build_object(
            'sale', COUNT(*) FILTER (WHERE listing_type = 'sale' AND status = 'active'),
            'trade', COUNT(*) FILTER (WHERE listing_type = 'trade' AND status = 'active'),
            'giveaway', COUNT(*) FILTER (WHERE listing_type = 'giveaway' AND status = 'active')
        )
    ) INTO result
    FROM marketplace_listings
    WHERE (6371 * acos(
        cos(radians(p_latitude)) *
        cos(radians(latitude)) *
        cos(radians(longitude) - radians(p_longitude)) +
        sin(radians(p_latitude)) *
        sin(radians(latitude))
    )) <= p_radius_km;

    RETURN result;
END;
$$;

-- ============================================================================
-- Trigger: auto-update updated_at
-- ============================================================================

CREATE TRIGGER update_marketplace_listings_updated_at
    BEFORE UPDATE ON marketplace_listings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Storage bucket for marketplace photos
-- ============================================================================
-- NOTE: Run this in the Supabase dashboard SQL editor:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('marketplace-photos', 'marketplace-photos', true)
-- ON CONFLICT (id) DO NOTHING;

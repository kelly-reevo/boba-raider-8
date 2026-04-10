-- Migration: Create stores table
-- Description: Stores table for boba shop locations

CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    lat DECIMAL(10, 8),
    lng DECIMAL(11, 8),
    phone VARCHAR(20),
    hours VARCHAR(100),
    description TEXT,
    image_url TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for name lookups
CREATE INDEX IF NOT EXISTS idx_stores_name ON stores(name);

-- Index for geospatial queries (if needed later)
CREATE INDEX IF NOT EXISTS idx_stores_location ON stores(lat, lng);

-- Index for created_by foreign key
CREATE INDEX IF NOT EXISTS idx_stores_created_by ON stores(created_by);

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_stores_updated_at ON stores;
CREATE TRIGGER update_stores_updated_at
    BEFORE UPDATE ON stores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

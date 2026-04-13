-- Migration: Create boba_stores table
-- Description: Creates the boba_stores table with all required fields and constraints

CREATE TABLE IF NOT EXISTS boba_stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    address TEXT,
    city VARCHAR(100),
    phone VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_boba_stores_name ON boba_stores(name);
CREATE INDEX IF NOT EXISTS idx_boba_stores_city ON boba_stores(city);

-- Add comment for documentation
COMMENT ON TABLE boba_stores IS 'Stores information about boba tea locations';
COMMENT ON COLUMN boba_stores.id IS 'Unique identifier for the store';
COMMENT ON COLUMN boba_stores.name IS 'Store name (required, must be unique)';
COMMENT ON COLUMN boba_stores.address IS 'Street address (optional)';
COMMENT ON COLUMN boba_stores.city IS 'City name (optional)';
COMMENT ON COLUMN boba_stores.phone IS 'Contact phone number (optional)';
COMMENT ON COLUMN boba_stores.created_at IS 'Timestamp when record was created';
COMMENT ON COLUMN boba_stores.updated_at IS 'Timestamp when record was last updated';

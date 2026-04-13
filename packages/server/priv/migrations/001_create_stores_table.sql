-- Migration: Create boba_stores table
-- Created: 2026-04-12

CREATE TABLE IF NOT EXISTS boba_stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_boba_stores_name ON boba_stores(name);
CREATE INDEX IF NOT EXISTS idx_boba_stores_city ON boba_stores(city);

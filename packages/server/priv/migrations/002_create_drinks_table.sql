-- Migration: Create drinks table
-- Depends on: stores table (unit-25)

-- Create tea_type enum
CREATE TYPE tea_type AS ENUM (
    'black',
    'green',
    'oolong',
    'white',
    'herbal',
    'milk',
    'other'
);

-- Create drinks table
CREATE TABLE drinks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    tea_type tea_type NOT NULL,
    price DECIMAL(6, 2),
    description TEXT,
    image_url TEXT,
    is_signature BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE(store_id, name)
);

-- Index for store lookups
CREATE INDEX idx_drinks_store_id ON drinks(store_id);

-- Index for signature drinks
CREATE INDEX idx_drinks_is_signature ON drinks(is_signature) WHERE is_signature = true;

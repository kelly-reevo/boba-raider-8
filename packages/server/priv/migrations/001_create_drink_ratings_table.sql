-- Migration: Create drink_ratings table
-- Description: Stores boba drink ratings with specific axes for sweetness, boba texture, and tea strength
-- Dependencies: boba_drinks table must exist

-- Ensure boba_drinks table exists (dependency)
CREATE TABLE IF NOT EXISTS boba_drinks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL
);

-- Create drink_ratings table with boba-specific rating columns
CREATE TABLE IF NOT EXISTS drink_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    drink_id UUID NOT NULL REFERENCES boba_drinks(id) ON DELETE CASCADE,
    reviewer_name VARCHAR(100),
    overall_rating SMALLINT NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),
    sweetness SMALLINT NOT NULL CHECK (sweetness BETWEEN 1 AND 10),
    boba_texture SMALLINT NOT NULL CHECK (boba_texture BETWEEN 1 AND 10),
    tea_strength SMALLINT NOT NULL CHECK (tea_strength BETWEEN 1 AND 10),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on drink_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_drink_ratings_drink_id ON drink_ratings(drink_id);

-- Create index on created_at for sorting reviews by date
CREATE INDEX IF NOT EXISTS idx_drink_ratings_created_at ON drink_ratings(created_at DESC);

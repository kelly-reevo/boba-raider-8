-- Unit 21: Drink Ratings Table Migration
-- Dependencies: unit-20 (drinks, users tables)
-- Boundary: drink_ratings table with constraints and indexes

-- UP MIGRATION

-- Ensure dependency tables exist (unit-20 baseline)
-- These are minimal stub tables if unit-20 hasn't been applied yet
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS drinks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Main table: drink_ratings
-- Stores user ratings for drinks with multi-dimensional scoring
CREATE TABLE drink_ratings (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign key relationships with cascade delete for data integrity
    drink_id UUID NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),

    -- Multi-dimensional rating attributes (1-5 scale, nullable for partial reviews)
    sweetness SMALLINT CHECK (sweetness >= 1 AND sweetness <= 5),
    boba_texture SMALLINT CHECK (boba_texture >= 1 AND boba_texture <= 5),
    tea_strength SMALLINT CHECK (tea_strength >= 1 AND tea_strength <= 5),

    -- Overall rating is required
    overall_rating SMALLINT NOT NULL CHECK (overall_rating >= 1 AND overall_rating <= 5),

    -- Optional review text
    review TEXT,

    -- Audit timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Unique constraint: one rating per user per drink
    CONSTRAINT unique_user_drink_rating UNIQUE (drink_id, user_id)
);

-- Indexes for performance optimization
-- Lookup by drink (for drink detail page showing all ratings)
CREATE INDEX idx_drink_ratings_drink_id ON drink_ratings(drink_id);

-- Lookup by user (for user's rating history)
CREATE INDEX idx_drink_ratings_user_id ON drink_ratings(user_id);

-- Composite index for the unique constraint lookup pattern
CREATE INDEX idx_drink_ratings_drink_user ON drink_ratings(drink_id, user_id);

-- Index for recent ratings queries
CREATE INDEX idx_drink_ratings_created_at ON drink_ratings(created_at DESC);

-- Index for rating aggregation queries (e.g., average ratings by drink)
CREATE INDEX idx_drink_ratings_drink_overall ON drink_ratings(drink_id, overall_rating);

-- Trigger function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_drink_ratings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at on row modification
CREATE TRIGGER trigger_drink_ratings_updated_at
    BEFORE UPDATE ON drink_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_drink_ratings_updated_at();

-- DOWN MIGRATION (for reversibility)
-- Comment out the following lines when running UP migration
-- Uncomment when running DOWN migration

-- DROP TRIGGER IF EXISTS trigger_drink_ratings_updated_at ON drink_ratings;
-- DROP FUNCTION IF EXISTS update_drink_ratings_updated_at();
-- DROP TABLE IF EXISTS drink_ratings;

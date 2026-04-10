-- Migration: Create drink_ratings table
-- Description: Stores user ratings and reviews for drinks
-- Depends on: users (001), drinks (002)

CREATE TABLE IF NOT EXISTS drink_ratings (
    id TEXT PRIMARY KEY CHECK (length(id) = 36),
    drink_id TEXT NOT NULL REFERENCES drinks(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    overall_score INTEGER NOT NULL CHECK (overall_score BETWEEN 1 AND 5),
    sweetness INTEGER NOT NULL CHECK (sweetness BETWEEN 1 AND 5),
    boba_texture INTEGER NOT NULL CHECK (boba_texture BETWEEN 1 AND 5),
    tea_strength INTEGER NOT NULL CHECK (tea_strength BETWEEN 1 AND 5),
    review_text TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(drink_id, user_id)
);

-- Index for fetching ratings by drink
CREATE INDEX IF NOT EXISTS idx_drink_ratings_drink_id ON drink_ratings(drink_id);

-- Index for fetching ratings by user
CREATE INDEX IF NOT EXISTS idx_drink_ratings_user_id ON drink_ratings(user_id);

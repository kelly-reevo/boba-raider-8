-- Create store_ratings table for store reviews
-- Each user can rate a store once (UNIQUE constraint on store_id + user_id)

CREATE TABLE IF NOT EXISTS store_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    overall_score SMALLINT NOT NULL CHECK (overall_score BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (store_id, user_id)
);

-- Index for querying all ratings for a specific store
CREATE INDEX idx_store_ratings_store_id ON store_ratings (store_id);

-- Index for querying all ratings by a specific user
CREATE INDEX idx_store_ratings_user_id ON store_ratings (user_id);

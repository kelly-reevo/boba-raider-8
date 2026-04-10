-- Revert store_ratings table

DROP INDEX IF EXISTS idx_store_ratings_user_id;
DROP INDEX IF EXISTS idx_store_ratings_store_id;
DROP TABLE IF EXISTS store_ratings;

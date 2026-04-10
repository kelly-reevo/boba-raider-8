-- Migration: Create drinks table
-- Description: Base drink catalog

CREATE TABLE IF NOT EXISTS drinks (
    id TEXT PRIMARY KEY CHECK (length(id) = 36),
    name TEXT NOT NULL,
    description TEXT,
    shop_id TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

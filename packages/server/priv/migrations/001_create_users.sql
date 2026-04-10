-- Migration: Create users table
-- Description: Base user accounts for the application

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY CHECK (length(id) = 36),
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

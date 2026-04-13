-- Down Migration: Revert create boba_stores table
-- Description: Drops the boba_stores table

DROP TABLE IF EXISTS boba_stores CASCADE;

import gleam/io
import sqlight

const create_users_table = "
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
"

const create_stores_table = "
CREATE TABLE IF NOT EXISTS stores (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
"

const create_drinks_table = "
CREATE TABLE IF NOT EXISTS drinks (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL REFERENCES stores(id),
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price_cents INTEGER,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
"

const create_ratings_table = "
CREATE TABLE IF NOT EXISTS ratings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  drink_id TEXT NOT NULL REFERENCES drinks(id),
  score INTEGER NOT NULL CHECK (score >= 1 AND score <= 5),
  comment TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  UNIQUE(user_id, drink_id)
);
"

const create_indexes = "
CREATE INDEX IF NOT EXISTS idx_drinks_store_id ON drinks(store_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_drink_id ON ratings(drink_id);
CREATE INDEX IF NOT EXISTS idx_stores_name ON stores(name);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
"

const enable_wal = "PRAGMA journal_mode=WAL;"

const enable_foreign_keys = "PRAGMA foreign_keys=ON;"

/// Initialize the database, creating all tables and indexes.
/// Returns the open connection for use by the application.
pub fn init(path: String) -> Result(sqlight.Connection, String) {
  case sqlight.open(path) {
    Ok(conn) -> {
      case run_migrations(conn) {
        Ok(Nil) -> {
          io.println("Database initialized: " <> path)
          Ok(conn)
        }
        Error(sqlight.SqlightError(message: msg, ..)) -> {
          let _ = sqlight.close(conn)
          Error("Migration failed: " <> msg)
        }
      }
    }
    Error(_) -> Error("Failed to open database: " <> path)
  }
}

fn run_migrations(
  conn: sqlight.Connection,
) -> Result(Nil, sqlight.Error) {
  use _ <- result_try(sqlight.exec(enable_wal, on: conn))
  use _ <- result_try(sqlight.exec(enable_foreign_keys, on: conn))
  use _ <- result_try(sqlight.exec(create_users_table, on: conn))
  use _ <- result_try(sqlight.exec(create_stores_table, on: conn))
  use _ <- result_try(sqlight.exec(create_drinks_table, on: conn))
  use _ <- result_try(sqlight.exec(create_ratings_table, on: conn))
  use _ <- result_try(sqlight.exec(create_indexes, on: conn))
  Ok(Nil)
}

fn result_try(
  result: Result(a, e),
  next: fn(a) -> Result(b, e),
) -> Result(b, e) {
  case result {
    Ok(val) -> next(val)
    Error(err) -> Error(err)
  }
}

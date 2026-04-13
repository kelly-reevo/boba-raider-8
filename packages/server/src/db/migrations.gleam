import sqlight

/// SQL to create the boba_stores table (dependency for boba_drinks)
pub const create_boba_stores_table = "
CREATE TABLE boba_stores (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
"

/// SQL to create the boba_drinks table with foreign key to boba_stores
pub const create_boba_drinks_table = "
CREATE TABLE boba_drinks (
  id TEXT PRIMARY KEY,
  store_id TEXT NOT NULL REFERENCES boba_stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  base_tea_type TEXT,
  price REAL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
"

/// Execute the boba_stores table migration
pub fn run_create_stores_migration(db: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  sqlight.exec(create_boba_stores_table, on: db)
}

/// Execute the boba_drinks table migration
pub fn run_create_drinks_migration(db: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  sqlight.exec(create_boba_drinks_table, on: db)
}

/// Run all migrations in order: stores first, then drinks
pub fn run_all_migrations(db: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  case run_create_stores_migration(db) {
    Ok(_) -> run_create_drinks_migration(db)
    Error(err) -> Error(err)
  }
}

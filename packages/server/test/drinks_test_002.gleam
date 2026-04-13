import gleam/dynamic/decode
import gleeunit
import gleeunit/should
import sqlight

pub fn main() {
  gleeunit.main()
}

pub fn foreign_key_constraint_fails_with_invalid_store_id_test() {
  let assert Ok(db) = sqlight.open(":memory:")

  // Enable foreign key constraints (SQLite requires this)
  let pragma_sql = "PRAGMA foreign_keys = ON"
  let assert Ok(_) = sqlight.exec(pragma_sql, on: db)

  // Setup: Create stores table
  let create_stores_sql = "
    CREATE TABLE boba_stores (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  "
  let assert Ok(_) = sqlight.exec(create_stores_sql, on: db)

  // Setup: Create drinks table with foreign key constraint
  let create_drinks_sql = "
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
  let assert Ok(_) = sqlight.exec(create_drinks_sql, on: db)

  // Insert drink with invalid store_id should fail with foreign key constraint error
  let insert_drink_sql = "
    INSERT INTO boba_drinks (id, store_id, name, description, base_tea_type, price)
    VALUES ('drink-invalid', 'nonexistent-store', 'Oolong Tea', 'Should fail', 'oolong', 6.00)
  "
  let result = sqlight.exec(insert_drink_sql, on: db)

  // Should return an error due to foreign key constraint violation
  should.be_error(result)

  // Verify no drinks were inserted
  let count_sql = "SELECT COUNT(*) FROM boba_drinks"
  let decoder = decode.at([0], decode.int)
  let assert Ok([count]) = sqlight.query(count_sql, on: db, with: [], expecting: decoder)

  count |> should.equal(0)
}

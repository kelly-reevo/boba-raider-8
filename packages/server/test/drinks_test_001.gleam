import gleam/dynamic/decode
import gleeunit
import gleeunit/should
import sqlight

pub fn main() {
  gleeunit.main()
}

pub fn foreign_key_constraint_passes_with_valid_store_id_test() {
  let assert Ok(db) = sqlight.open(":memory:")

  // Setup: Create stores table
  let create_stores_sql = "
    CREATE TABLE boba_stores (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  "
  let assert Ok(_) = sqlight.exec(create_stores_sql, on: db)

  // Setup: Create drinks table
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

  // Insert a valid store
  let insert_store_sql = "INSERT INTO boba_stores (id, name) VALUES ('store-valid', 'Valid Store')"
  let assert Ok(_) = sqlight.exec(insert_store_sql, on: db)

  // Insert drink with valid store_id should succeed
  let insert_drink_sql = "
    INSERT INTO boba_drinks (id, store_id, name, description, base_tea_type, price)
    VALUES ('drink-valid', 'store-valid', 'Green Milk Tea', 'Fresh green tea', 'green', 4.75)
  "
  let result = sqlight.exec(insert_drink_sql, on: db)

  should.be_ok(result)

  // Verify the drink was inserted
  let count_sql = "SELECT COUNT(*) FROM boba_drinks"
  let decoder = decode.at([0], decode.int)
  let assert Ok([count]) = sqlight.query(count_sql, on: db, with: [], expecting: decoder)

  count |> should.equal(1)
}

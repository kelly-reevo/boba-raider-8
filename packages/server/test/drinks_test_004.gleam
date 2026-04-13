import gleeunit
import gleeunit/should
import sqlight

pub fn main() {
  gleeunit.main()
}

pub fn name_field_rejects_null_test() {
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

  // Insert a store
  let insert_store_sql = "INSERT INTO boba_stores (id, name) VALUES ('store-123', 'Test Store')"
  let assert Ok(_) = sqlight.exec(insert_store_sql, on: db)

  // Insert drink with NULL name should fail
  let insert_drink_sql = "
    INSERT INTO boba_drinks (id, store_id, name, base_tea_type, price)
    VALUES ('drink-null-name', 'store-123', NULL, 'black', 5.00)
  "
  let result = sqlight.exec(insert_drink_sql, on: db)

  // Should return an error due to NOT NULL constraint
  should.be_error(result)
}

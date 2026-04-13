import gleam/dynamic/decode
import gleeunit
import gleeunit/should
import sqlight

pub fn main() {
  gleeunit.main()
}

pub fn cascade_delete_removes_drinks_when_store_deleted_test() {
  let assert Ok(db) = sqlight.open(":memory:")

  // Enable foreign key constraints
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

  // Setup: Create drinks table with ON DELETE CASCADE
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
  let insert_store_sql = "INSERT INTO boba_stores (id, name) VALUES ('store-123', 'Boba Shop')"
  let assert Ok(_) = sqlight.exec(insert_store_sql, on: db)

  // Insert multiple drinks for this store
  let insert_drink1 = "
    INSERT INTO boba_drinks (id, store_id, name, base_tea_type, price)
    VALUES ('drink-1', 'store-123', 'Black Milk Tea', 'black', 5.00)
  "
  let assert Ok(_) = sqlight.exec(insert_drink1, on: db)

  let insert_drink2 = "
    INSERT INTO boba_drinks (id, store_id, name, base_tea_type, price)
    VALUES ('drink-2', 'store-123', 'White Peach Oolong', 'white', 6.50)
  "
  let assert Ok(_) = sqlight.exec(insert_drink2, on: db)

  // Verify drinks exist
  let count_sql = "SELECT COUNT(*) FROM boba_drinks"
  let decoder = decode.at([0], decode.int)
  let assert Ok([count_before]) = sqlight.query(count_sql, on: db, with: [], expecting: decoder)
  count_before |> should.equal(2)

  // Delete the store
  let delete_store_sql = "DELETE FROM boba_stores WHERE id = 'store-123'"
  let assert Ok(_) = sqlight.exec(delete_store_sql, on: db)

  // Verify cascade delete removed all associated drinks
  let assert Ok([count_after]) = sqlight.query(count_sql, on: db, with: [], expecting: decoder)
  count_after |> should.equal(0)
}

import gleam/dynamic/decode
import gleam/option
import gleeunit
import gleeunit/should
import sqlight

pub fn main() {
  gleeunit.main()
}

pub fn boba_drinks_table_exists_with_all_columns_test() {
  let assert Ok(db) = sqlight.open(":memory:")

  // First create the stores table (dependency for foreign key)
  let create_stores_sql = "
    CREATE TABLE boba_stores (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  "
  let assert Ok(_) = sqlight.exec(create_stores_sql, on: db)

  // Execute the migration under test
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

  // Verify table exists by querying schema
  let table_info_sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='boba_drinks'"
  let decoder = decode.at([0], decode.string)
  let result = sqlight.query(table_info_sql, on: db, with: [], expecting: decoder)

  result
  |> should.be_ok
  |> should.equal(["boba_drinks"])

  // Verify all columns exist by inserting a valid record
  let insert_store_sql = "INSERT INTO boba_stores (id, name) VALUES ('store-123', 'Test Store')"
  let assert Ok(_) = sqlight.exec(insert_store_sql, on: db)

  let insert_drink_sql = "
    INSERT INTO boba_drinks (id, store_id, name, description, base_tea_type, price)
    VALUES ('drink-456', 'store-123', 'Classic Milk Tea', 'Delicious classic', 'black', 5.50)
  "
  let assert Ok(_) = sqlight.exec(insert_drink_sql, on: db)

  // Verify record was inserted with all fields
  let select_sql = "SELECT id, store_id, name, description, base_tea_type, price FROM boba_drinks WHERE id = 'drink-456'"
  let decoder = {
    use id <- decode.field(0, decode.string)
    use store_id <- decode.field(1, decode.string)
    use name <- decode.field(2, decode.string)
    use description <- decode.field(3, decode.optional(decode.string))
    use base_tea_type <- decode.field(4, decode.optional(decode.string))
    use price <- decode.field(5, decode.optional(decode.float))
    decode.success(#(id, store_id, name, description, base_tea_type, price))
  }
  let assert Ok([row]) = sqlight.query(select_sql, on: db, with: [], expecting: decoder)

  row.0 |> should.equal("drink-456")
  row.1 |> should.equal("store-123")
  row.2 |> should.equal("Classic Milk Tea")
  row.3 |> should.equal(option.Some("Delicious classic"))
  row.4 |> should.equal(option.Some("black"))
  row.5 |> should.equal(option.Some(5.50))
}

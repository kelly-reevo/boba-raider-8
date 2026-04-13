import gleam/dynamic/decode
import gleam/option
import gleeunit
import gleeunit/should
import sqlight

pub fn main() {
  gleeunit.main()
}

pub fn optional_fields_accept_null_test() {
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

  // Insert drink with only required fields (name and store_id)
  let insert_drink_sql = "
    INSERT INTO boba_drinks (id, store_id, name)
    VALUES ('drink-minimal', 'store-123', 'Simple Tea')
  "
  let result = sqlight.exec(insert_drink_sql, on: db)

  // Should succeed
  should.be_ok(result)

  // Verify the drink was inserted with NULL optional fields
  let select_sql = "SELECT id, store_id, name, description, base_tea_type, price FROM boba_drinks WHERE id = 'drink-minimal'"
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

  row.0 |> should.equal("drink-minimal")
  row.1 |> should.equal("store-123")
  row.2 |> should.equal("Simple Tea")
  row.3 |> should.equal(option.None)
  row.4 |> should.equal(option.None)
  row.5 |> should.equal(option.None)
}

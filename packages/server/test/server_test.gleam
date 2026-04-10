import config
import data/drink_store
import gleeunit
import gleeunit/should
import gleam/dict
import gleam/option.{None, Some}
import shared.{type CreateDrinkInput, type Drink, Black, CreateDrinkInput, Green, Oolong}
import web/handlers/drink_handler
import web/server

pub fn main() {
  gleeunit.main()
}

pub fn config_load_test() {
  let cfg = config.load()
  cfg.port
  |> should.equal(3000)
}

// Drink store tests

pub fn drink_store_create_test() {
  let store = drink_store.start()

  let input =
    CreateDrinkInput(
      name: "Oolong Milk Tea",
      tea_type: Oolong,
      price: Some(5.50),
      description: Some("Classic oolong with milk"),
      image_url: None,
      is_signature: True,
    )

  let result = drink_store.create_drink(store, "store_123", input)

  case result {
    Ok(drink) -> {
      drink.name |> should.equal("Oolong Milk Tea")
      drink.store_id |> should.equal("store_123")
      drink.price |> should.equal(Some(5.50))
      drink.is_signature |> should.equal(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn drink_store_duplicate_name_test() {
  let store = drink_store.start()

  let input =
    CreateDrinkInput(
      name: "Black Tea",
      tea_type: Black,
      price: None,
      description: None,
      image_url: None,
      is_signature: False,
    )

  // First creation should succeed
  let _ = drink_store.create_drink(store, "store_123", input)

  // Second creation with same name should fail with Conflict
  let result = drink_store.create_drink(store, "store_123", input)

  case result {
    Error(shared.Conflict(_)) -> True |> should.be_true
    _ -> should.fail()
  }
}

pub fn drink_store_different_store_same_name_test() {
  let store = drink_store.start()

  let input =
    CreateDrinkInput(
      name: "Green Tea",
      tea_type: Green,
      price: None,
      description: None,
      image_url: None,
      is_signature: False,
    )

  // First creation in store_1 should succeed
  let _ = drink_store.create_drink(store, "store_1", input)

  // Same name in store_2 should also succeed
  let result = drink_store.create_drink(store, "store_2", input)

  case result {
    Ok(drink) -> drink.store_id |> should.equal("store_2")
    Error(_) -> should.fail()
  }
}

// Drink handler tests

pub fn drink_handler_create_success_test() {
  let store = drink_store.start()

  let request =
    server.Request(
      method: "POST",
      path: "/api/stores/store_test/drinks",
      headers: dict.new(),
      body: "{\"name\":\"Matcha Latte\",\"tea_type\":\"green\",\"price\":6.00,\"is_signature\":true}",
    )

  let response = drink_handler.create(request, store)

  response.status |> should.equal(201)
}

pub fn drink_handler_invalid_json_test() {
  let store = drink_store.start()

  let request =
    server.Request(
      method: "POST",
      path: "/api/stores/store_test/drinks",
      headers: dict.new(),
      body: "invalid json",
    )

  let response = drink_handler.create(request, store)

  response.status |> should.equal(422)
}

pub fn drink_handler_invalid_path_test() {
  let store = drink_store.start()

  let request =
    server.Request(
      method: "POST",
      path: "/api/invalid/path",
      headers: dict.new(),
      body: "{}",
    )

  let response = drink_handler.create(request, store)

  response.status |> should.equal(404)
}

pub fn drink_handler_conflict_test() {
  let store = drink_store.start()

  let body = "{\"name\":\"Earl Grey\",\"tea_type\":\"black\"}"

  let request1 =
    server.Request(
      method: "POST",
      path: "/api/stores/store_conflict/drinks",
      headers: dict.new(),
      body: body,
    )

  let _ = drink_handler.create(request1, store)

  let request2 =
    server.Request(
      method: "POST",
      path: "/api/stores/store_conflict/drinks",
      headers: dict.new(),
      body: body,
    )

  let response = drink_handler.create(request2, store)

  response.status |> should.equal(409)
}

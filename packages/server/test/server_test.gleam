import config
import data/drink_store
import gleeunit
import gleeunit/should
import config
import db/drink_store.{DrinkRecord, Rating, StoreRecord}
import gleam/option.{None, Some}

pub fn main() {
  gleeunit.main()
}

pub fn config_load_test() {
  let cfg = config.load()
  cfg.port
  |> should.equal(3000)
}

pub fn get_drink_by_id_found_test() {
  // Set up test data
  let store = drink_store.new_store()

  let drink = DrinkRecord(
    id: "drink-123",
    store_id: "store-456",
    name: "Classic Milk Tea",
    tea_type: "Black",
    price: Some(5.50),
    description: Some("Traditional milk tea"),
    image_url: None,
    is_signature: True,
    created_at: "2024-01-15T10:00:00Z",
  )

  let store_record = StoreRecord(
    id: "store-456",
    name: "Boba Paradise",
    address: "123 Tea Lane",
  )

  let rating1 = Rating(
    id: "rating-1",
    drink_id: "drink-123",
    overall: Some(4.5),
    sweetness: Some(3.0),
    texture: Some(4.0),
    tea_strength: Some(5.0),
  )

  let rating2 = Rating(
    id: "rating-2",
    drink_id: "drink-123",
    overall: Some(3.5),
    sweetness: Some(2.0),
    texture: Some(3.5),
    tea_strength: Some(4.0),
  )

  // Populate store
  let store = drink_store.insert_store(store, store_record)
  let store = drink_store.insert_drink(store, drink)
  let store = drink_store.insert_rating(store, rating1)
  let store = drink_store.insert_rating(store, rating2)

  // Retrieve drink
  let result = drink_store.get_drink_by_id(store, "drink-123")

  // Verify
  case result {
    Some(drink_details) -> {
      drink_details.id |> should.equal("drink-123")
      drink_details.name |> should.equal("Classic Milk Tea")
      drink_details.store.name |> should.equal("Boba Paradise")

      // Check averages: overall = (4.5 + 3.5) / 2 = 4.0
      case drink_details.average_rating.overall {
        Some(avg) -> avg |> should.equal(4.0)
        None -> should.fail()
      }

      // Check averages: sweetness = (3.0 + 2.0) / 2 = 2.5
      case drink_details.average_rating.sweetness {
        Some(avg) -> avg |> should.equal(2.5)
        None -> should.fail()
      }
    }
    None -> should.fail()
  }
}

pub fn get_drink_by_id_not_found_test() {
  let store = drink_store.new_store()

  let result = drink_store.get_drink_by_id(store, "nonexistent")

  result |> should.equal(None)
}

pub fn get_drink_by_id_missing_store_test() {
  // Drink exists but store doesn't - should return None
  let store = drink_store.new_store()

  let drink = DrinkRecord(
    id: "drink-123",
    store_id: "store-missing",
    name: "Classic Milk Tea",
    tea_type: "Black",
    price: None,
    description: None,
    image_url: None,
    is_signature: False,
    created_at: "2024-01-15T10:00:00Z",
  )

  let store = drink_store.insert_drink(store, drink)

  let result = drink_store.get_drink_by_id(store, "drink-123")

  result |> should.equal(None)
}

pub fn get_drink_no_ratings_test() {
  // Drink exists with no ratings - averages should be null
  let store = drink_store.new_store()

  let drink = DrinkRecord(
    id: "drink-789",
    store_id: "store-456",
    name: "Green Tea",
    tea_type: "Green",
    price: Some(4.00),
    description: None,
    image_url: None,
    is_signature: False,
    created_at: "2024-01-15T10:00:00Z",
  )

  let store_record = StoreRecord(
    id: "store-456",
    name: "Boba Paradise",
    address: "123 Tea Lane",
  )

  let store = drink_store.insert_store(store, store_record)
  let store = drink_store.insert_drink(store, drink)

  let result = drink_store.get_drink_by_id(store, "drink-789")

  case result {
    Some(drink_details) -> {
      drink_details.average_rating.overall |> should.equal(None)
      drink_details.average_rating.sweetness |> should.equal(None)
      drink_details.average_rating.texture |> should.equal(None)
      drink_details.average_rating.tea_strength |> should.equal(None)
    }
    None -> should.fail()
  }
}

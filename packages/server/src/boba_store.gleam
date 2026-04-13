/// Boba Store - Public API for store and drink operations
/// Provides a unified interface to store and drink services

import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, Some, None}
import gleam/otp/actor
import gleam/string
import gleam/list
import store/store_service as service
import boba_validation.{type StoreInput, type DrinkInput}

// ============================================================================
// Public Types
// ============================================================================

/// Opaque reference to the unified store (handles both stores and drinks)
pub opaque type Store {
  Store(
    store_subject: Subject(service.StoreServiceMsg),
    drink_subject: Subject(DrinkMsg),
  )
}

/// Store record returned from create_store
pub type StoreRecord {
  StoreRecord(
    id: Int,
    uuid: String,
    name: String,
    address: Option(String),
    city: Option(String),
    phone: Option(String),
    created_at: String,
  )
}

/// Drink record
pub type DrinkRecord {
  DrinkRecord(
    id: Int,
    name: String,
    store_id: Int,
  )
}

// Internal drink actor types
pub type DrinkState {
  DrinkState(
    drinks: List(DrinkRecord),
    next_id: Int,
  )
}

pub type DrinkMsg {
  CreateDrink(DrinkInput, Subject(Result(DrinkRecord, String)))
  GetDrinksByStore(Int, Subject(List(DrinkRecord)))
  CountDrinksByStore(Int, Subject(Int))
}

// ============================================================================
// Store Management
// ============================================================================

/// Create a new unified store instance (handles both stores and drinks)
pub fn new() -> Result(Store, String) {
  // Start the store service
  case service.start() {
    Ok(store_subject) -> {
      // Start the drink actor
      let initial_state = DrinkState(drinks: [], next_id: 1)
      case
        actor.new(initial_state)
        |> actor.on_message(handle_drink_message)
        |> actor.start()
      {
        Ok(started) -> Ok(Store(store_subject: store_subject, drink_subject: started.data))
        Error(_) -> Error("Failed to start drink actor")
      }
    }
    Error(msg) -> Error(msg)
  }
}

/// Create a new store with the given input
pub fn create_store(store: Store, input: StoreInput) -> Result(StoreRecord, String) {
  // Convert StoreInput to service CreateStoreInput
  let service_input = service.CreateStoreInput(
    name: input.name,
    address: input.address,
    city: input.city,
    phone: input.phone,
  )

  case service.create_store(store.store_subject, service_input) {
    Ok(store_with_count) -> {
      // Extract numeric ID from UUID format "store-XXXXXXXX"
      let numeric_id = case string.split(store_with_count.id, "-") {
        [_, id_part] -> {
          case parse_int(id_part) {
            Ok(n) -> n
            Error(_) -> 0
          }
        }
        _ -> 0
      }

      Ok(StoreRecord(
        id: numeric_id,
        uuid: store_with_count.id,
        name: store_with_count.name,
        address: store_with_count.address,
        city: store_with_count.city,
        phone: store_with_count.phone,
        created_at: store_with_count.created_at,
      ))
    }
    Error(msg) -> Error(msg)
  }
}

/// Get a store by its string ID (UUID format)
pub fn get_store_by_uuid(store: Store, uuid: String) -> Result(service.StoreWithDrinkCount, String) {
  service.get_store_with_drink_count(store.store_subject, uuid)
}

/// Get a store by numeric ID
/// Converts the numeric ID to UUID format and looks it up
pub fn get_store_by_id(store: Store, id: Int) -> Result(service.StoreWithDrinkCount, String) {
  // Convert numeric ID to UUID format "store-XXXXXXXX"
  let uuid = "store-" <> pad_int_to_8_digits(id)
  get_store_by_uuid(store, uuid)
}

/// Convert an integer to a string
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> int_to_string_recursive(n, "")
  }
}

fn int_to_string_recursive(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let digit = case n % 10 {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        _ -> "9"
      }
      int_to_string_recursive(n / 10, digit <> acc)
    }
  }
}

/// Pad an integer to 8 digits with leading zeros
fn pad_int_to_8_digits(n: Int) -> String {
  let s = int_to_string(n)
  let len = string.length(s)
  case len {
    0 -> "00000000"
    1 -> "0000000" <> s
    2 -> "000000" <> s
    3 -> "00000" <> s
    4 -> "0000" <> s
    5 -> "000" <> s
    6 -> "00" <> s
    7 -> "0" <> s
    _ -> s
  }
}

/// Parse a string to an integer
fn parse_int(s: String) -> Result(Int, String) {
  parse_int_recursive(string.trim(s), 0)
}

fn parse_int_recursive(s: String, acc: Int) -> Result(Int, String) {
  case string.pop_grapheme(s) {
    Ok(#(c, rest)) -> {
      case c {
        "0" -> parse_int_recursive(rest, acc * 10 + 0)
        "1" -> parse_int_recursive(rest, acc * 10 + 1)
        "2" -> parse_int_recursive(rest, acc * 10 + 2)
        "3" -> parse_int_recursive(rest, acc * 10 + 3)
        "4" -> parse_int_recursive(rest, acc * 10 + 4)
        "5" -> parse_int_recursive(rest, acc * 10 + 5)
        "6" -> parse_int_recursive(rest, acc * 10 + 6)
        "7" -> parse_int_recursive(rest, acc * 10 + 7)
        "8" -> parse_int_recursive(rest, acc * 10 + 8)
        "9" -> parse_int_recursive(rest, acc * 10 + 9)
        _ -> Error("Invalid digit")
      }
    }
    Error(_) -> Ok(acc)
  }
}

// ============================================================================
// Drink Management (uses the same Store reference)
// ============================================================================

/// Handle drink actor messages
fn handle_drink_message(state: DrinkState, msg: DrinkMsg) -> actor.Next(DrinkState, DrinkMsg) {
  case msg {
    CreateDrink(input, reply_to) -> {
      let record = DrinkRecord(
        id: state.next_id,
        name: input.name,
        store_id: input.store_id,
      )
      let new_state = DrinkState(
        drinks: [record, ..state.drinks],
        next_id: state.next_id + 1,
      )
      actor.send(reply_to, Ok(record))
      actor.continue(new_state)
    }

    GetDrinksByStore(store_id, reply_to) -> {
      let drinks = list.filter(state.drinks, fn(d) { d.store_id == store_id })
      actor.send(reply_to, drinks)
      actor.continue(state)
    }

    CountDrinksByStore(store_id, reply_to) -> {
      let count = list.length(list.filter(state.drinks, fn(d) { d.store_id == store_id }))
      actor.send(reply_to, count)
      actor.continue(state)
    }
  }
}

/// Create a new drink
pub fn create_drink(store: Store, input: DrinkInput) -> Result(DrinkRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(store.drink_subject, CreateDrink(input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for drink store")
  }
}

/// Get drinks by store ID
pub fn get_drinks_by_store(store: Store, store_id: Int) -> List(DrinkRecord) {
  let reply_subject = process.new_subject()
  actor.send(store.drink_subject, GetDrinksByStore(store_id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(drinks) -> drinks
    Error(_) -> []
  }
}

/// Count drinks by store ID
pub fn count_drinks_by_store(store: Store, store_id: Int) -> Int {
  let reply_subject = process.new_subject()
  actor.send(store.drink_subject, CountDrinksByStore(store_id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(count) -> count
    Error(_) -> 0
  }
}

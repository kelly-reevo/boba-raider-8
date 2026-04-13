import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/string

// Input types for creating and updating drinks
pub type CreateDrinkInput {
  CreateDrinkInput(
    store_id: String,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
  )
}

pub type UpdateDrinkInput {
  UpdateDrinkInput(
    name: Option(String),
    description: Option(Option(String)),
    base_tea_type: Option(Option(String)),
    price: Option(Option(Float)),
  )
}

// Drink record matching boundary contract output
pub type DrinkRecord {
  DrinkRecord(
    id: String,
    store_id: String,
    name: String,
    description: Option(String),
    base_tea_type: Option(String),
    price: Option(Float),
    created_at: Int,
    updated_at: Int,
  )
}

// Actor message types
pub type DrinkStoreMsg {
  CreateDrink(CreateDrinkInput, Subject(Result(DrinkRecord, String)))
  GetDrinkById(String, Subject(Result(DrinkRecord, String)))
  ListDrinksByStore(String, Subject(List(DrinkRecord)))
  UpdateDrink(String, UpdateDrinkInput, Subject(Result(DrinkRecord, String)))
  DeleteDrink(String, Subject(Result(Bool, String)))
}

pub type DrinkStore =
  Subject(DrinkStoreMsg)

// Store state is a dict of id -> DrinkRecord
type StoreState =
  Dict(String, DrinkRecord)

// FFI for generating UUID
@external(erlang, "erlang", "unique_integer")
fn unique_integer() -> Int

@external(erlang, "erlang", "phash2")
fn phash2(term: any, range: Int) -> Int

fn generate_uuid() -> String {
  let timestamp = system_time_milliseconds()
  let unique = unique_integer()
  let hash = phash2(unique, 16_777_215)
  format_uuid(timestamp, hash)
}

fn format_uuid(timestamp: Int, hash: Int) -> String {
  let hex1 = int_to_hex_string(timestamp % 4_294_967_296)
  let hex2 = int_to_hex_string(hash % 65_536)
  let hex3 = int_to_hex_string({ hash / 65_536 } % 65_536)
  let hex4 = int_to_hex_string(unique_integer() % 65_536)
  let hex5 = int_to_hex_string(system_time_milliseconds() % 4_294_967_296)

  pad_left(hex1, 8)
  <> "-"
  <> pad_left(hex2, 4)
  <> "-"
  <> pad_left(hex3, 4)
  <> "-"
  <> pad_left(hex4, 4)
  <> "-"
  <> pad_left(hex5, 12)
}

fn pad_left(s: String, len: Int) -> String {
  case string.length(s) {
    n if n >= len -> s
    n -> string.repeat("0", len - n) <> s
  }
}

fn int_to_hex_string(n: Int) -> String {
  case n {
    0 -> "0"
    _ -> do_int_to_hex_string(n, "")
  }
}

fn do_int_to_hex_string(n: Int, acc: String) -> String {
  case n {
    0 -> acc
    _ -> {
      let digit = n % 16
      let char = case digit {
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        9 -> "9"
        10 -> "a"
        11 -> "b"
        12 -> "c"
        13 -> "d"
        14 -> "e"
        _ -> "f"
      }
      do_int_to_hex_string(n / 16, char <> acc)
    }
  }
}

// FFI for system time in milliseconds
@external(erlang, "erlang", "system_time")
fn erlang_system_time(unit: Int) -> Int

fn system_time_milliseconds() -> Int {
  // 1000 is the millisecond unit identifier for Erlang
  erlang_system_time(1000)
}

// Validation functions
fn validate_create_input(input: CreateDrinkInput) -> Result(Nil, String) {
  case string.length(string.trim(input.store_id)) > 0 {
    False -> Error("store_id is required")
    True -> {
      case string.length(string.trim(input.name)) > 0 {
        False -> Error("name is required")
        True -> {
          case input.price {
            Some(p) if p <. 0.0 -> Error("price cannot be negative")
            _ -> Ok(Nil)
          }
        }
      }
    }
  }
}

fn validate_uuid(id: String) -> Bool {
  // Basic UUID validation - should be non-empty and contain dashes
  string.length(id) > 0 && string.contains(id, "-")
}

// Actor implementation
fn handle_message(
  state: StoreState,
  msg: DrinkStoreMsg,
) -> actor.Next(StoreState, DrinkStoreMsg) {
  case msg {
    CreateDrink(input, reply_to) -> {
      case validate_create_input(input) {
        Error(err) -> {
          actor.send(reply_to, Error(err))
          actor.continue(state)
        }
        Ok(_) -> {
          let now = system_time_milliseconds()
          let id = generate_uuid()
          let record =
            DrinkRecord(
              id: id,
              store_id: input.store_id,
              name: input.name,
              description: input.description,
              base_tea_type: input.base_tea_type,
              price: input.price,
              created_at: now,
              updated_at: now,
            )
          let new_state = dict.insert(state, id, record)
          actor.send(reply_to, Ok(record))
          actor.continue(new_state)
        }
      }
    }

    GetDrinkById(id, reply_to) -> {
      case validate_uuid(id) {
        False -> {
          actor.send(reply_to, Error("Invalid UUID format"))
          actor.continue(state)
        }
        True -> {
          case dict.get(state, id) {
            Ok(record) -> {
              actor.send(reply_to, Ok(record))
              actor.continue(state)
            }
            Error(_) -> {
              actor.send(reply_to, Error("Drink not found"))
              actor.continue(state)
            }
          }
        }
      }
    }

    ListDrinksByStore(store_id, reply_to) -> {
      let drinks =
        state
        |> dict.values()
        |> list.filter(fn(drink) { drink.store_id == store_id })
      actor.send(reply_to, drinks)
      actor.continue(state)
    }

    UpdateDrink(id, input, reply_to) -> {
      case dict.get(state, id) {
        Ok(existing) -> {
          let now = system_time_milliseconds()
          // Handle nested Option types for partial updates and null clearing:
          // - None means "don't update this field" (keep existing)
          // - Some(None) means "clear this field" (set to None)
          // - Some(Some(v)) means "update to this value"
          let updated =
            DrinkRecord(
              id: existing.id,
              store_id: existing.store_id,
              name: case input.name {
                Some(n) -> n
                None -> existing.name
              },
              description: case input.description {
                Some(d) -> d
                None -> existing.description
              },
              base_tea_type: case input.base_tea_type {
                Some(b) -> b
                None -> existing.base_tea_type
              },
              price: case input.price {
                Some(p) -> p
                None -> existing.price
              },
              created_at: existing.created_at,
              updated_at: now,
            )
          let new_state = dict.insert(state, id, updated)
          actor.send(reply_to, Ok(updated))
          actor.continue(new_state)
        }
        Error(_) -> {
          actor.send(reply_to, Error("Drink not found"))
          actor.continue(state)
        }
      }
    }

    DeleteDrink(id, reply_to) -> {
      case dict.get(state, id) {
        Ok(_) -> {
          let new_state = dict.delete(state, id)
          actor.send(reply_to, Ok(True))
          actor.continue(new_state)
        }
        Error(_) -> {
          actor.send(reply_to, Error("Drink not found"))
          actor.continue(state)
        }
      }
    }
  }
}

// Public API

pub fn start() -> Result(DrinkStore, String) {
  let initial_state = dict.new()

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start drink store actor")
  }
}

pub fn create_drink(
  store: DrinkStore,
  input: CreateDrinkInput,
) -> Result(DrinkRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(store, CreateDrink(input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for drink store")
  }
}

pub fn get_drink_by_id(
  store: DrinkStore,
  id: String,
) -> Result(DrinkRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(store, GetDrinkById(id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for drink store")
  }
}

pub fn list_drinks_by_store(
  store: DrinkStore,
  store_id: String,
) -> List(DrinkRecord) {
  let reply_subject = process.new_subject()
  actor.send(store, ListDrinksByStore(store_id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(drinks) -> drinks
    Error(_) -> []
  }
}

pub fn update_drink(
  store: DrinkStore,
  id: String,
  input: UpdateDrinkInput,
) -> Result(DrinkRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(store, UpdateDrink(id, input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for drink store")
  }
}

pub fn delete_drink(store: DrinkStore, id: String) -> Result(Bool, String) {
  let reply_subject = process.new_subject()
  actor.send(store, DeleteDrink(id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for drink store")
  }
}

/// Store data service - manages store persistence
/// In-memory storage using OTP actor

import gleam/dict.{type Dict}
import gleam/int
import gleam/option
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/result
import shared.{
  type Store,
  type Coordinates,
  type CreateStoreRequest,
  Store as StoreConstructor,
}

/// Store state - in-memory storage using a dictionary
pub type StoreState {
  StoreState(
    stores: Dict(String, Store),
    by_address: Dict(String, String),
    next_id: Int,
  )
}

/// Store actor message types
pub type StoreMsg {
  CreateStore(
    request: CreateStoreRequest,
    coords: Coordinates,
    created_by: String,
    reply_to: Subject(Result(Store, String)),
  )
  GetStore(id: String, reply_to: Subject(Result(Store, Nil)))
  GetAllStores(reply_to: Subject(List(Store)))
}

/// Initialize empty store state
fn initial_state() -> StoreState {
  StoreState(
    stores: dict.new(),
    by_address: dict.new(),
    next_id: 1,
  )
}

/// Generate unique store ID
fn generate_id(counter: Int) -> String {
  "store_" <> int.to_string(counter)
}

/// Generate timestamp (ISO8601 format)
fn now_iso8601() -> String {
  "2024-01-01T00:00:00Z"
}

/// Store actor loop - handles messages and returns Next
fn handle_message(state: StoreState, msg: StoreMsg) -> actor.Next(StoreState, StoreMsg) {
  case msg {
    CreateStore(request, coords, created_by, reply_to) -> {
      // Check for duplicate address
      case dict.has_key(state.by_address, request.address) {
        True -> {
          process.send(reply_to, Error("Store with this address already exists"))
          actor.continue(state)
        }
        False -> {
          let id = generate_id(state.next_id)
          let store = StoreConstructor(
            id: id,
            name: request.name,
            address: request.address,
            lat: coords.lat,
            lng: coords.lng,
            phone: option.unwrap(request.phone, ""),
            hours: option.unwrap(request.hours, ""),
            description: option.unwrap(request.description, ""),
            image_url: option.unwrap(request.image_url, ""),
            created_by: created_by,
            created_at: now_iso8601(),
            average_rating: 0.0,
          )

          let new_state = StoreState(
            stores: dict.insert(state.stores, id, store),
            by_address: dict.insert(state.by_address, request.address, id),
            next_id: state.next_id + 1,
          )

          process.send(reply_to, Ok(store))
          actor.continue(new_state)
        }
      }
    }

    GetStore(id, reply_to) -> {
      process.send(reply_to, dict.get(state.stores, id))
      actor.continue(state)
    }

    GetAllStores(reply_to) -> {
      process.send(reply_to, dict.values(state.stores))
      actor.continue(state)
    }
  }
}

/// Start the store service actor
pub fn start() -> Result(Subject(StoreMsg), String) {
  case
    actor.new(initial_state())
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start store service")
  }
}

/// Create a new store via the actor
pub fn create_store(
  actor_ref: Subject(StoreMsg),
  request: CreateStoreRequest,
  coords: Coordinates,
  created_by: String,
) -> Result(Store, String) {
  let reply_to = process.new_subject()
  process.send(actor_ref, CreateStore(request, coords, created_by, reply_to))
  process.receive(reply_to, 5000)
  |> result.map_error(fn(_) { "Timeout waiting for store creation" })
  |> result.flatten
}

/// Get store by ID
pub fn get_store(
  actor_ref: Subject(StoreMsg),
  id: String,
) -> Result(Store, Nil) {
  let reply_to = process.new_subject()
  process.send(actor_ref, GetStore(id, reply_to))
  case process.receive(reply_to, 5000) {
    Ok(store) -> store
    Error(_) -> Error(Nil)
  }
}

/// Get all stores
pub fn get_all_stores(
  actor_ref: Subject(StoreMsg),
) -> List(Store) {
  let reply_to = process.new_subject()
  process.send(actor_ref, GetAllStores(reply_to))
  case process.receive(reply_to, 5000) {
    Ok(stores) -> stores
    Error(_) -> []
  }
}

/// Store module (unit-4)
/// Simple in-memory store storage using actor state

import gleam/dict.{type Dict}
import gleam/erlang/process
import gleam/otp/actor
import gleam/result
import shared.{type AppError, type Store, NotFound, InternalError}

/// Store actor message types
pub type StoreMsg {
  GetStore(id: String, reply: process.Subject(Result(Store, AppError)))
  StoreExists(id: String, reply: process.Subject(Bool))
  CreateStore(name: String, reply: process.Subject(Result(Store, AppError)))
  Shutdown
}

pub type StoreActor =
  process.Subject(StoreMsg)

/// In-memory state for stores
pub type StoreState {
  StoreState(stores: Dict(String, Store), next_id: Int)
}

/// Initialize store actor with some seed data
fn initial_state() -> StoreState {
  // Seed with a default store for testing
  let default_store = shared.Store(
    id: "store_1",
    name: "Test Store",
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  )

  StoreState(
    stores: dict.from_list([#("store_1", default_store)]),
    next_id: 2,
  )
}

/// Start the store actor
pub fn start() -> Result(StoreActor, String) {
  let handler = fn(state: StoreState, msg: StoreMsg) {
    case msg {
      GetStore(id, reply) -> {
        let result = case dict.get(state.stores, id) {
          Ok(store) -> Ok(store)
          Error(_) -> Error(NotFound("store"))
        }
        process.send(reply, result)
        actor.continue(state)
      }

      StoreExists(id, reply) -> {
        let exists = dict.has_key(state.stores, id)
        process.send(reply, exists)
        actor.continue(state)
      }

      CreateStore(name, reply) -> {
        let id = "store_" <> int_to_string(state.next_id)
        let now = "2024-01-01T00:00:00Z"
        let store = shared.Store(
          id: id,
          name: name,
          created_at: now,
          updated_at: now,
        )
        let new_stores = dict.insert(state.stores, id, store)
        let new_state = StoreState(stores: new_stores, next_id: state.next_id + 1)
        process.send(reply, Ok(store))
        actor.continue(new_state)
      }

      Shutdown -> actor.stop()
    }
  }

  actor.new(initial_state())
  |> actor.on_message(handler)
  |> actor.start()
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) { "Failed to start store actor" })
}

fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    n if n < 0 -> "-" <> int_to_string(-n)
    _ -> do_int_to_string(n, "")
  }
}

fn do_int_to_string(n: Int, acc: String) -> String {
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
      do_int_to_string(n / 10, digit <> acc)
    }
  }
}

/// Public API functions

pub fn get_store(actor: StoreActor, id: String) -> Result(Store, AppError) {
  let reply_subject = process.new_subject()
  process.send(actor, GetStore(id, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.unwrap(Error(InternalError("Timeout")))
}

pub fn store_exists(actor: StoreActor, id: String) -> Bool {
  let reply_subject = process.new_subject()
  process.send(actor, StoreExists(id, reply_subject))
  process.receive(reply_subject, 5000)
  |> result.unwrap(False)
}

pub fn stop(actor: StoreActor) -> Nil {
  process.send(actor, Shutdown)
}

/// Store data access layer - in-memory storage for stores

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/result
import shared.{
  type Store, type StoreUpdate, type AppError, NotFound, Some, None, Store as StoreRecord,
}

/// Actor message types for store operations
pub type StoreMsg {
  GetStore(id: String, reply_to: Subject(Result(Store, AppError)))
  UpdateStore(id: String, update: StoreUpdate, reply_to: Subject(Result(Store, AppError)))
  CheckOwnership(id: String, user_id: String, reply_to: Subject(Bool))
}

/// Store actor state
type StoreState {
  StoreState(stores: Dict(String, Store))
}

/// Start the store data actor
pub fn start() -> Result(Subject(StoreMsg), String) {
  let initial_state = StoreState(stores: dict.new())

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start()
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) { "Failed to start store actor" })
}

/// Handle incoming store messages
fn handle_message(state: StoreState, msg: StoreMsg) {
  case msg {
    GetStore(id, reply_to) -> {
      let result = case dict.get(state.stores, id) {
        Ok(store) -> Ok(store)
        Error(_) -> Error(NotFound("Store not found"))
      }
      process.send(reply_to, result)
      actor.continue(state)
    }

    UpdateStore(id, update, reply_to) -> {
      case dict.get(state.stores, id) {
        Ok(existing) -> {
          let updated = apply_update(existing, update)
          let new_stores = dict.insert(state.stores, id, updated)
          process.send(reply_to, Ok(updated))
          actor.continue(StoreState(stores: new_stores))
        }
        Error(_) -> {
          process.send(reply_to, Error(NotFound("Store not found")))
          actor.continue(state)
        }
      }
    }

    CheckOwnership(id, user_id, reply_to) -> {
      let is_owner = case dict.get(state.stores, id) {
        Ok(store) -> store.creator_id == user_id
        Error(_) -> False
      }
      process.send(reply_to, is_owner)
      actor.continue(state)
    }
  }
}

/// Apply partial update to a store
fn apply_update(store: Store, update: StoreUpdate) -> Store {
  StoreRecord(
    id: store.id,
    name: option_or_keep(update.name, store.name),
    address: option_or_keep(update.address, store.address),
    phone: option_or_keep(update.phone, store.phone),
    hours: option_or_keep(update.hours, store.hours),
    description: option_or_keep(update.description, store.description),
    image_url: option_or_keep(update.image_url, store.image_url),
    creator_id: store.creator_id,
    created_at: store.created_at,
    updated_at: "2024-01-01T00:00:00Z", // In real impl, use current timestamp
  )
}

fn option_or_keep(opt: shared.Option(a), default: a) -> a {
  case opt {
    Some(value) -> value
    None -> default
  }
}

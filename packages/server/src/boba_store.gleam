import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import shared/boba_validation.{type StoreInput}

// Store record for in-memory storage
pub type StoreRecord {
  StoreRecord(
    id: Int,
    name: String,
    address: Dict(String, String),
    phone: Dict(String, String),
    created_at: String,
  )
}

// Actor message types
pub type StoreMsg {
  CreateStore(StoreInput, Subject(Result(StoreRecord, String)))
  GetStoreById(Int, Subject(Result(StoreRecord, String)))
  GetAllStores(Subject(List(StoreRecord)))
  CheckStoreExists(Int, Subject(Bool))
}

pub type StoreState {
  StoreState(
    stores: Dict(Int, StoreRecord),
    next_id: Int,
  )
}

pub type BobaStore =
  Subject(StoreMsg)

// Actor message handler
fn handle_message(state: StoreState, msg: StoreMsg) -> actor.Next(StoreState, StoreMsg) {
  case msg {
    CreateStore(input, reply_to) -> {
      let id = state.next_id
      let now = "2024-01-01T00:00:00Z"
      let record = StoreRecord(
        id: id,
        name: input.name,
        address: input.address,
        phone: input.phone,
        created_at: now,
      )
      let new_stores = dict.insert(state.stores, id, record)
      let new_state = StoreState(
        stores: new_stores,
        next_id: id + 1,
      )
      actor.send(reply_to, Ok(record))
      actor.continue(new_state)
    }

    GetStoreById(id, reply_to) -> {
      case dict.get(state.stores, id) {
        Ok(record) -> {
          actor.send(reply_to, Ok(record))
          actor.continue(state)
        }
        Error(_) -> {
          actor.send(reply_to, Error("Store not found"))
          actor.continue(state)
        }
      }
    }

    GetAllStores(reply_to) -> {
      let stores = dict.values(state.stores)
      actor.send(reply_to, stores)
      actor.continue(state)
    }

    CheckStoreExists(id, reply_to) -> {
      let exists = dict.has_key(state.stores, id)
      actor.send(reply_to, exists)
      actor.continue(state)
    }
  }
}

// Public API

pub fn new() -> Result(BobaStore, String) {
  let initial_state = StoreState(
    stores: dict.new(),
    next_id: 1,
  )

  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start store actor")
  }
}

pub fn create_store(
  store: BobaStore,
  input: StoreInput,
) -> Result(StoreRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(store, CreateStore(input, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for store")
  }
}

pub fn get_store_by_id(
  store: BobaStore,
  id: Int,
) -> Result(StoreRecord, String) {
  let reply_subject = process.new_subject()
  actor.send(store, GetStoreById(id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(result) -> result
    Error(_) -> Error("Timeout waiting for store")
  }
}

pub fn check_store_exists(
  store: BobaStore,
  id: Int,
) -> Bool {
  let reply_subject = process.new_subject()
  actor.send(store, CheckStoreExists(id, reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(exists) -> exists
    Error(_) -> False
  }
}

pub fn get_all_stores(
  store: BobaStore,
) -> List(StoreRecord) {
  let reply_subject = process.new_subject()
  actor.send(store, GetAllStores(reply_subject))

  case process.receive(reply_subject, within: 5000) {
    Ok(stores) -> stores
    Error(_) -> []
  }
}

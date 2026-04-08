import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import store.{type Store, Store}

pub type StoreRepo =
  Subject(StoreRepoMsg)

pub type StoreRepoMsg {
  Create(
    name: String,
    address: String,
    phone: String,
    owner_id: String,
    reply: Subject(Store),
  )
  GetById(id: String, reply: Subject(Result(Store, Nil)))
  ListByOwner(owner_id: String, reply: Subject(List(Store)))
  ListAll(reply: Subject(List(Store)))
  Update(
    id: String,
    name: String,
    address: String,
    phone: String,
    requesting_owner: String,
    reply: Subject(Result(Store, String)),
  )
  Delete(
    id: String,
    requesting_owner: String,
    reply: Subject(Result(Nil, String)),
  )
}

type State {
  State(stores: Dict(String, Store))
}

@external(erlang, "id_ffi", "unique_id")
fn unique_id() -> String

pub fn start() -> Result(StoreRepo, String) {
  let initial_state = State(stores: dict.new())
  case
    actor.new(initial_state)
    |> actor.on_message(handle_message)
    |> actor.start()
  {
    Ok(started) -> Ok(started.data)
    Error(_) -> Error("Failed to start store repo actor")
  }
}

fn handle_message(state: State, msg: StoreRepoMsg) {
  case msg {
    Create(name:, address:, phone:, owner_id:, reply:) -> {
      let id = unique_id()
      let new_store = Store(id:, name:, address:, phone:, owner_id:)
      let new_stores = dict.insert(state.stores, id, new_store)
      process.send(reply, new_store)
      actor.continue(State(stores: new_stores))
    }

    GetById(id:, reply:) -> {
      process.send(reply, dict.get(state.stores, id))
      actor.continue(state)
    }

    ListByOwner(owner_id:, reply:) -> {
      let filtered =
        dict.values(state.stores)
        |> list.filter(fn(s) { s.owner_id == owner_id })
      process.send(reply, filtered)
      actor.continue(state)
    }

    ListAll(reply:) -> {
      process.send(reply, dict.values(state.stores))
      actor.continue(state)
    }

    Update(id:, name:, address:, phone:, requesting_owner:, reply:) -> {
      case dict.get(state.stores, id) {
        Ok(existing) if existing.owner_id == requesting_owner -> {
          let updated =
            Store(
              id: existing.id,
              name:,
              address:,
              phone:,
              owner_id: existing.owner_id,
            )
          let new_stores = dict.insert(state.stores, id, updated)
          process.send(reply, Ok(updated))
          actor.continue(State(stores: new_stores))
        }
        Ok(_) -> {
          process.send(reply, Error("Forbidden"))
          actor.continue(state)
        }
        Error(_) -> {
          process.send(reply, Error("Not found"))
          actor.continue(state)
        }
      }
    }

    Delete(id:, requesting_owner:, reply:) -> {
      case dict.get(state.stores, id) {
        Ok(existing) if existing.owner_id == requesting_owner -> {
          let new_stores = dict.delete(state.stores, id)
          process.send(reply, Ok(Nil))
          actor.continue(State(stores: new_stores))
        }
        Ok(_) -> {
          process.send(reply, Error("Forbidden"))
          actor.continue(state)
        }
        Error(_) -> {
          process.send(reply, Error("Not found"))
          actor.continue(state)
        }
      }
    }
  }
}

// Public convenience functions for synchronous calls

pub fn create(
  repo: StoreRepo,
  name: String,
  address: String,
  phone: String,
  owner_id: String,
) -> Store {
  process.call(repo, 5000, fn(reply) { Create(name:, address:, phone:, owner_id:, reply:) })
}

pub fn get_by_id(repo: StoreRepo, id: String) -> Result(Store, Nil) {
  process.call(repo, 5000, fn(reply) { GetById(id:, reply:) })
}

pub fn list_by_owner(repo: StoreRepo, owner_id: String) -> List(Store) {
  process.call(repo, 5000, fn(reply) { ListByOwner(owner_id:, reply:) })
}

pub fn list_all(repo: StoreRepo) -> List(Store) {
  process.call(repo, 5000, fn(reply) { ListAll(reply:) })
}

pub fn update(
  repo: StoreRepo,
  id: String,
  name: String,
  address: String,
  phone: String,
  requesting_owner: String,
) -> Result(Store, String) {
  process.call(
    repo,
    5000,
    fn(reply) { Update(id:, name:, address:, phone:, requesting_owner:, reply:) },
  )
}

pub fn delete(
  repo: StoreRepo,
  id: String,
  requesting_owner: String,
) -> Result(Nil, String) {
  process.call(repo, 5000, fn(reply) { Delete(id:, requesting_owner:, reply:) })
}

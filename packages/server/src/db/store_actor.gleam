import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/result
import db/drink_store.{type Store}

/// Messages the store actor can handle
pub type StoreMsg {
  GetState(reply_to: Subject(Store))
  UpdateState(state: Store)
}

/// Store actor handle
pub type StoreActor =
  Subject(StoreMsg)

/// Start the store actor with initial empty state
pub fn start() -> Result(StoreActor, String) {
  let initial_state = drink_store.new_store()

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start()
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(_) { "Failed to start store actor" })
}

/// Get current store state
pub fn get_state(actor: StoreActor) -> Store {
  process.call(actor, 1000, fn(reply_to) { GetState(reply_to) })
}

/// Update store state
pub fn update_state(actor: StoreActor, state: Store) -> Nil {
  process.send(actor, UpdateState(state))
}

/// Handle incoming messages
fn handle_message(state: Store, msg: StoreMsg) -> actor.Next(Store, StoreMsg) {
  case msg {
    GetState(reply_to) -> {
      process.send(reply_to, state)
      actor.continue(state)
    }
    UpdateState(new_state) -> {
      actor.continue(new_state)
    }
  }
}

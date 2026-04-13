import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject, type Pid}
import gleam/list
import gleam/otp/actor
import gleam/dynamic.{type Dynamic}

/// Public API for starting the todo actor
pub fn start() -> Result(Pid, Dynamic) {
  let builder =
    actor.new([])
    |> actor.on_message(handle_message)

  case actor.start(builder) {
    Ok(started) -> Ok(started.pid)
    Error(err) -> Error(start_error_to_dynamic(err))
  }
}

fn start_error_to_dynamic(err: actor.StartError) -> Dynamic {
  let message = case err {
    actor.InitTimeout -> "InitTimeout"
    actor.InitFailed(msg) -> "InitFailed: " <> msg
    actor.InitExited(_) -> "InitExited"
  }
  dynamic.string(message)
}

/// Internal state type: list of stored todos with their IDs
type State =
  List(StoredTodo)

type StoredTodo {
  StoredTodo(id: String, item: Dict(String, Dynamic))
}

/// Message types that the actor can receive
pub type Message {
  // Synchronous calls (require reply)
  GetAll(reply_to: Subject(List(Dict(String, Dynamic))))
  Get(id: String, reply_to: Subject(Dict(String, Dynamic)))

  // Asynchronous casts (no reply)
  Put(id: String, item: Dict(String, Dynamic))
  Delete(id: String)
}

/// Handle incoming messages
fn handle_message(state: State, msg: Message) {
  case msg {
    // Get all todos - synchronous
    GetAll(reply_to) -> {
      let todos = list.map(state, fn(s) { s.item })
      process.send(reply_to, todos)
      actor.continue(state)
    }

    // Get specific todo by ID - synchronous
    Get(id, reply_to) -> {
      let found = list.find(state, fn(s) { s.id == id })
      case found {
        Ok(stored) -> process.send(reply_to, stored.item)
        Error(_) -> process.send(reply_to, dict.new())
      }
      actor.continue(state)
    }

    // Add/update a todo - asynchronous
    Put(id, item) -> {
      // Remove existing if present, then add new at front
      let filtered = list.filter(state, fn(s) { s.id != id })
      let new_state = [StoredTodo(id, item), ..filtered]
      actor.continue(new_state)
    }

    // Delete a todo - asynchronous
    Delete(id) -> {
      let new_state = list.filter(state, fn(s) { s.id != id })
      actor.continue(new_state)
    }
  }
}

/// Convenience functions for interacting with the actor

/// Get all todos from the actor
pub fn get_all(actor_subject: Subject(Message)) -> List(Dict(String, Dynamic)) {
  process.call(actor_subject, 1000, fn(reply_to) { GetAll(reply_to) })
}

/// Get a specific todo by ID
pub fn get(actor_subject: Subject(Message), id: String) -> Dict(String, Dynamic) {
  process.call(actor_subject, 1000, fn(reply_to) { Get(id, reply_to) })
}

/// Add or update a todo
pub fn put(actor_subject: Subject(Message), id: String, item: Dict(String, Dynamic)) {
  process.send(actor_subject, Put(id, item))
}

/// Delete a todo
pub fn delete(actor_subject: Subject(Message), id: String) {
  process.send(actor_subject, Delete(id))
}

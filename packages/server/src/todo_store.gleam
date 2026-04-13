/// CRUD operations interface for Todo storage
/// Wraps an OTP actor for state management

import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import shared.{type AppError, type Todo, type TodoAttrs, NotFound, Pending, Todo}

// Message types for the todo store actor
pub type StoreMsg {
  Create(attrs: TodoAttrs, reply_to: Subject(Result(Todo, AppError)))
  GetAll(reply_to: Subject(List(Todo)))
  GetById(id: String, reply_to: Subject(Option(Todo)))
  Update(id: String, attrs: TodoAttrs, reply_to: Subject(Result(Todo, Nil)))
  Delete(id: String, reply_to: Subject(Result(Nil, AppError)))
}

// Store state holds the list of todos and a counter for ID generation
type StoreState {
  StoreState(todos: List(Todo), next_id: Int)
}

/// Subject type for the todo store actor
pub type TodoStore =
  Subject(StoreMsg)

// Use an external Erlang module for global state
@external(erlang, "todo_store_ffi", "get_store")
fn get_global_store() -> Result(Subject(StoreMsg), Nil)

@external(erlang, "todo_store_ffi", "set_store")
fn set_global_store(store: Subject(StoreMsg)) -> Nil

@external(erlang, "todo_store_ffi", "clear_store")
fn clear_global_store() -> Nil

/// Initialize the todo store actor
pub fn start() -> Result(TodoStore, String) {
  // Check if already started
  case get_global_store() {
    Ok(store) -> Ok(store)
    Error(_) -> {
      let initial_state = StoreState(todos: [], next_id: 1)

      case
        actor.new(initial_state)
        |> actor.on_message(handle_message)
        |> actor.start()
      {
        Ok(started) -> {
          let store = started.data
          set_global_store(store)
          Ok(store)
        }
        Error(_) -> Error("Failed to start todo store actor")
      }
    }
  }
}

/// Stop the todo store
pub fn stop() -> Nil {
  clear_global_store()
}

/// Clear all todos from the store (for testing)
pub fn clear() -> Nil {
  // Stop current store and start fresh
  stop()
  let _ = start()
  Nil
}

// Handle incoming messages
fn handle_message(state: StoreState, msg: StoreMsg) {
  case msg {
    Create(attrs, reply_to) -> {
      let new_item = create_todo_data(state, attrs)
      let new_state = StoreState(
        todos: [new_item, ..state.todos],
        next_id: state.next_id + 1,
      )
      actor.send(reply_to, Ok(new_item))
      actor.continue(new_state)
    }

    GetAll(reply_to) -> {
      // Return todos in creation order (oldest first)
      let ordered = list.reverse(state.todos)
      actor.send(reply_to, ordered)
      actor.continue(state)
    }

    GetById(id, reply_to) -> {
      let found = list.find(state.todos, fn(t) { t.id == id })
      let response = case found {
        Ok(t) -> Some(t)
        Error(_) -> None
      }
      actor.send(reply_to, response)
      actor.continue(state)
    }

    Update(id, attrs, reply_to) -> {
      let found = list.find(state.todos, fn(t) { t.id == id })
      case found {
        Ok(existing) -> {
          let updated = Todo(
            id: existing.id,
            title: attrs.title,
            description: attrs.description,
            priority: attrs.priority,
            status: existing.status,
            created_at: existing.created_at,
            updated_at: Some(current_timestamp()),
          )
          let new_todos = list.map(state.todos, fn(t) {
            case t.id == id {
              True -> updated
              False -> t
            }
          })
          let new_state = StoreState(..state, todos: new_todos)
          actor.send(reply_to, Ok(updated))
          actor.continue(new_state)
        }
        Error(_) -> {
          actor.send(reply_to, Error(Nil))
          actor.continue(state)
        }
      }
    }

    Delete(id, reply_to) -> {
      let found = list.find(state.todos, fn(t) { t.id == id })
      case found {
        Ok(_) -> {
          let new_todos = list.filter(state.todos, fn(t) { t.id != id })
          let new_state = StoreState(..state, todos: new_todos)
          actor.send(reply_to, Ok(Nil))
          actor.continue(new_state)
        }
        Error(_) -> {
          actor.send(reply_to, Error(NotFound("Todo not found")))
          actor.continue(state)
        }
      }
    }
  }
}

// Create a new todo with generated ID and timestamp
fn create_todo_data(state: StoreState, attrs: TodoAttrs) -> Todo {
  let id = generate_id(state.next_id)
  let now = current_timestamp()

  Todo(
    id: id,
    title: attrs.title,
    description: attrs.description,
    priority: attrs.priority,
    status: Pending,
    created_at: now,
    updated_at: None,
  )
}

// Generate a unique ID using timestamp and counter
fn generate_id(counter: Int) -> String {
  let timestamp = current_timestamp()
  timestamp <> "-" <> int.to_string(counter)
}

// Get current timestamp as string
@external(erlang, "erlang", "system_time")
fn system_time(unit: Int) -> Int

@external(erlang, "erlang", "integer_to_binary")
fn int_to_binary(n: Int) -> String

fn current_timestamp() -> String {
  // Use millisecond timestamp for uniqueness
  let millis = system_time(1000)
  int_to_binary(millis)
}

// Get or create store
fn ensure_store() -> Subject(StoreMsg) {
  case get_global_store() {
    Ok(store) -> store
    Error(_) -> {
      let assert Ok(store) = start()
      store
    }
  }
}

// Public API functions

/// Create a new todo with generated ID and timestamp
pub fn create(attrs: TodoAttrs) -> Result(Todo, AppError) {
  let store = ensure_store()
  let reply = process.new_subject()
  actor.send(store, Create(attrs, reply))
  process.receive(reply, 5000)
  |> result.unwrap(Error(shared.InternalError("Timeout")))
}

/// Get all todos in creation order
pub fn get_all() -> List(Todo) {
  let store = ensure_store()
  let reply = process.new_subject()
  actor.send(store, GetAll(reply))
  process.receive(reply, 5000)
  |> result.unwrap([])
}

/// Get a todo by ID, returns None if not found
pub fn get_by_id(id: String) -> Option(Todo) {
  let store = ensure_store()
  let reply = process.new_subject()
  actor.send(store, GetById(id, reply))
  process.receive(reply, 5000)
  |> result.unwrap(None)
}

/// Update a todo by ID, returns Error(Nil) if not found
pub fn update(id: String, attrs: TodoAttrs) -> Result(Todo, Nil) {
  let store = ensure_store()
  let reply = process.new_subject()
  actor.send(store, Update(id, attrs, reply))
  process.receive(reply, 5000)
  |> result.unwrap(Error(Nil))
}

/// Delete a todo by ID, returns :ok or :not_found
pub fn delete(id: String) -> Result(Nil, AppError) {
  let store = ensure_store()
  let reply = process.new_subject()
  actor.send(store, Delete(id, reply))
  process.receive(reply, 5000)
  |> result.unwrap(Error(shared.InternalError("Timeout")))
}

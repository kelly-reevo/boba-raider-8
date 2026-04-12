/// OTP Actor for managing in-memory Todo state
/// Provides thread-safe CRUD operations with UUID generation

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/otp/actor
import gleam/string
import shared.{type Todo, type UpdateTodoInput}

/// Opaque reference to the todo store actor
pub opaque type Store {
  Store(subject: Subject(Message))
}

/// Internal state of the actor
type State {
  State(todos: Dict(String, Todo), next_id: Int)
}

/// Messages that can be sent to the actor
type Message {
  CreateTodo(title: String, description: String, reply: Subject(Result(Todo, Nil)))
  GetTodo(id: String, reply: Subject(Option(Todo)))
  GetAllTodos(reply: Subject(List(Todo)))
  UpdateTodo(id: String, input: UpdateTodoInput, reply: Subject(Result(Todo, String)))
  DeleteTodo(id: String, reply: Subject(Result(Nil, String)))
}

/// Start the todo store actor
pub fn start() -> Result(Store, Nil) {
  let initial_state = State(todos: dict.new(), next_id: 1)

  let builder =
    actor.new(initial_state)
    |> actor.on_message(handle_message)

  case actor.start(builder) {
    Ok(started) -> Ok(Store(started.data))
    Error(_) -> Error(Nil)
  }
}

/// Generate a unique ID (timestamp + counter based)
fn generate_id(state: State) -> #(String, State) {
  let id = "todo-" <> string.inspect(state.next_id) <> "-" <> string.inspect(erlang_timestamp())
  let new_state = State(..state, next_id: state.next_id + 1)
  #(id, new_state)
}

/// Get current timestamp in milliseconds
fn erlang_timestamp() -> Int {
  erlang_system_time_millis()
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time_millis() -> Int

/// Actor message handler
fn handle_message(state: State, message: Message) -> actor.Next(State, Message) {
  case message {
    CreateTodo(title, description, reply) -> {
      let #(id, new_state) = generate_id(state)
      let now = erlang_timestamp()
      let item = shared.Todo(
        id: id,
        title: title,
        description: description,
        completed: False,
        created_at: now,
        updated_at: now,
      )
      let updated_todos = dict.insert(new_state.todos, id, item)
      let final_state = State(..new_state, todos: updated_todos)

      process.send(reply, Ok(item))
      actor.continue(final_state)
    }

    GetTodo(id, reply) -> {
      let result = case dict.get(state.todos, id) {
        Ok(item) -> Some(item)
        Error(_) -> None
      }
      process.send(reply, result)
      actor.continue(state)
    }

    GetAllTodos(reply) -> {
      let todos = dict.values(state.todos)
      // Sort by created_at to maintain creation order
      let sorted = list.sort(todos, fn(a, b) {
        int_compare(a.created_at, b.created_at)
      })
      process.send(reply, sorted)
      actor.continue(state)
    }

    UpdateTodo(id, input, reply) -> {
      case dict.get(state.todos, id) {
        Ok(existing) -> {
          let now = erlang_timestamp()
          let updated = shared.Todo(
            id: existing.id,
            title: option_unwrap_or(input.title, existing.title),
            description: option_unwrap_or(input.description, existing.description),
            completed: option_unwrap_or(input.completed, existing.completed),
            created_at: existing.created_at,
            updated_at: now,
          )
          let updated_todos = dict.insert(state.todos, id, updated)
          let new_state = State(..state, todos: updated_todos)
          process.send(reply, Ok(updated))
          actor.continue(new_state)
        }
        Error(_) -> {
          process.send(reply, Error("Todo not found"))
          actor.continue(state)
        }
      }
    }

    DeleteTodo(id, reply) -> {
      case dict.get(state.todos, id) {
        Ok(_) -> {
          let updated_todos = dict.delete(state.todos, id)
          let new_state = State(..state, todos: updated_todos)
          process.send(reply, Ok(Nil))
          actor.continue(new_state)
        }
        Error(_) -> {
          process.send(reply, Error("Todo not found"))
          actor.continue(state)
        }
      }
    }
  }
}

/// Helper to unwrap shared.Option to a value with fallback
fn option_unwrap_or(opt: shared.Option(a), default: a) -> a {
  case opt {
    shared.Some(value) -> value
    shared.None -> default
  }
}

/// Compare two integers
fn int_compare(a: Int, b: Int) -> order.Order {
  case a < b {
    True -> order.Lt
    False -> case a > b {
      True -> order.Gt
      False -> order.Eq
    }
  }
}

// Public API functions

/// Create a new todo item
pub fn create_todo(store: Store, title: String, description: String) -> Result(Todo, Nil) {
  process.call(store.subject, 5000, fn(r) { CreateTodo(title, description, r) })
}

/// Get a single todo by ID
pub fn get_todo(store: Store, id: String) -> Option(Todo) {
  process.call(store.subject, 5000, fn(r) { GetTodo(id, r) })
}

/// Get all todos in creation order
pub fn get_all_todos(store: Store) -> List(Todo) {
  process.call(store.subject, 5000, fn(r) { GetAllTodos(r) })
}

/// Update a todo with partial fields
pub fn update_todo(store: Store, id: String, input: UpdateTodoInput) -> Result(Todo, String) {
  process.call(store.subject, 5000, fn(r) { UpdateTodo(id, input, r) })
}

/// Delete a todo by ID
pub fn delete_todo(store: Store, id: String) -> Result(Nil, String) {
  process.call(store.subject, 5000, fn(r) { DeleteTodo(id, r) })
}
